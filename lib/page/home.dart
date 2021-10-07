import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:jxcmobile/share/styles.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/model/bill.dart';
import 'package:jxcmobile/model/note.dart';
import 'package:jxcmobile/model/query.dart';
import 'package:jxcmobile/part/extra_menu_home.dart';
import 'package:jxcmobile/part/home_bill.dart';
import 'package:jxcmobile/part/home_query.dart';
import 'package:jxcmobile/part/home_note.dart';
import 'package:jxcmobile/part/home_favorite.dart';
import 'package:jxcmobile/part/home_meeting.dart';
import 'package:jxcmobile/share/toasts.dart';
import 'package:jxcmobile/page/bill.dart';
import 'package:jxcmobile/page/note.dart';
import 'package:jxcmobile/page/query.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title = ''}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  HomeTab selectedTab = HomeTab.bill;
  late final Comm comm;

  static HomeMeeting meetManager = const HomeMeeting();
  static Map<HomeTab, Widget> tabPages = {
    HomeTab.bill: const HomeBill(),
    HomeTab.query: const HomeQuery(),
    HomeTab.favorite: const HomeFavorite(),
    HomeTab.note: const HomeNote(),
    HomeTab.meeting: meetManager,
  };

  void newBill(String picked) async {
    //先建空单
    Bill bill = Bill(
      id: DateTime.now().millisecondsSinceEpoch,
      tname: picked,
      sheetid: 0,
      dated: todayEpochSeconds(),
    );

    //开新单
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BillPage(bill: bill),
      ),
    );

    //暂存更新
    if (bill.sumqty > 0.001) {
      await comm.tableOpen(billHiveTable);
      comm.tableSave(billHiveTable, bill.id.toString(), bill.joinMain(),
          notify: true);
    }
  }

  void newNote() async {
    //先建空单
    Note note = Note(
      id: DateTime.now().millisecondsSinceEpoch,
      sheetid: 0,
      dated: todayEpochSeconds(),
    );

    //开新单
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotePage(note: note),
      ),
    );

    //暂存更新
    if ((double.tryParse(note.sumMoney()) ?? 0) > 0.001) {
      await comm.tableOpen(noteHiveTable);
      comm.tableSave(noteHiveTable, note.id.toString(), note.joinMain(),
          notify: true);
    }
  }

  void newQuery(String picked) async {
    //qryMenu字符串约定
    List<String> menuSecs = picked.split('_');
    String qryType = menuSecs[0];
    String qryName = (menuSecs.length > 1) ? menuSecs[1] : '';

    //先建空查询
    QueryClip query = QueryClip(
      queryid: DateTime.now().millisecondsSinceEpoch,
      qtype: qryType,
      tname: qryName,
    );

    //开新查询
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QueryPage(qry: query),
      ),
    );

    if (result != null) {
      comm.tableSave(queryHiveTable, query.queryid.toString(), query.joinMain(),
          notify: true);
    }
  }

  void netResponsed() {
    if (comm.currentRequest.isNotEmpty &&
        comm.currentRequest[0] == 'GETIMAGE' &&
        comm.currentResponse.isNotEmpty) {
      List<String> requst = comm.currentRequest;
      String reqHpcode = requst[2];
      comm.clearResponse();
      Cargo? cargo = comm.cargos.firstWhereOrNull((e) => e.hpcode == reqHpcode);
      if (cargo != null) {
        bottomPopCargoImage(context, cargo);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    comm = Provider.of<Comm>(context, listen: false);
    comm.addListener(netResponsed);
  }

  @override
  void dispose() {
    comm.removeListener(netResponsed);
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      comm.disConnectSocket();
    }
    if (state == AppLifecycleState.resumed) {
      comm.connectLogin(context, LoginedWay.homeRefresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Theme.of(context).primaryColor;

    final bizQryDrawer = Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            child: SizedBox(
              height: 150,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: primaryColor,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircleAvatar(
                      child: homeTabIcons[selectedTab],
                    ),
                    Text(
                      '选择${homeTabNames[selectedTab]}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              itemCount: (selectedTab == HomeTab.bill)
                  ? bizTypes.length
                  : qryMenus.length,
              itemBuilder: (context, i) {
                String wqname = '';
                if (selectedTab == HomeTab.bill) {
                  wqname = bizTypes[i];
                } else {
                  if (qryMenus[i] == 'summ') wqname = 'temp_pass';
                  if (qryMenus[i] == 'cash_cg') wqname = 'vicgcash';
                  if (qryMenus[i] == 'rest_cg') wqname = 'vicgrest';
                  if (qryMenus[i] == 'cash_pf') wqname = 'vipfcash';
                  if (qryMenus[i] == 'rest_pf') wqname = 'vipfrest';
                  if (qryMenus[i] == 'stock') wqname = 'vistock';
                  if (qryMenus[i] == 'view') wqname = 'viall';
                }
                bool canOpen = comm.canOpen(wqname);
                VoidCallback? tapCallback = (canOpen)
                    ? () {
                        Navigator.pop(context);
                        if (selectedTab == HomeTab.bill) {
                          newBill(bizTypes[i]);
                        } else {
                          newQuery(qryMenus[i]);
                        }
                      }
                    : null;
                Color titleColor = (canOpen)
                    ? Theme.of(context).primaryColorDark
                    : Colors.grey;
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: GestureDetector(
                      child: Text(
                        (selectedTab == HomeTab.bill)
                            ? (bizNames[bizTypes[i]] ?? '')
                            : (qryNames[qryMenus[i]] ?? ''),
                        style: TextStyle(color: titleColor),
                      ),
                      onTap: tapCallback,
                    ),
                  ),
                );
              },
              separatorBuilder: (context, i) => Container(
                height: 1,
                color: Theme.of(context).primaryColorLight,
                margin: const EdgeInsets.symmetric(horizontal: 50),
              ),
            ),
          ),
          GestureDetector(
            child: Container(
              height: 60,
              color: Colors.white,
            ),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    final onlineTitle = Column(
      children: <Widget>[
        Text(
          comm.fronterName,
          textScaleFactor: 0.75,
          style: TextStyle(
            // Theme.of(context).primaryColorDark,
            color: nearestColor(comm.comColor).shade800,
          ),
        ),
        Text(
          comm.comName,
          textScaleFactor: 0.5,
          style: TextStyle(
            // Theme.of(context).primaryColorDark,
            color: nearestColor(comm.comColor).shade800,
          ),
        ),
      ],
    );

    final offlineTitle = GestureDetector(
      child: Column(
        children: <Widget>[
          Text(
            comm.netErrorMsg,
            textScaleFactor: 0.75,
            style: const TextStyle(color: Colors.yellow),
          ),
          const Text(
            '点击重连',
            textScaleFactor: 0.5,
            style: TextStyle(color: Colors.yellow),
          ),
        ],
      ),
      onTap: () {
        comm.connectLogin(context, LoginedWay.homeRefresh);
      },
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: (comm.netErrorMsg.isEmpty) ? primaryColor : Colors.red,
        title: Row(
          children: <Widget>[
            Text(homeTabNames[selectedTab] ?? ''),
            //SizedBox(width: 12),
            Expanded(child: Container()),
            (comm.netErrorMsg.isEmpty) ? onlineTitle : offlineTitle,
            Expanded(child: Container()),
          ],
        ),
        actions: const <Widget>[ExtraMenuHome()],
      ),
      body: tabPages[selectedTab],
      bottomNavigationBar: Builder(builder: (BuildContext context) {
        return BottomNavigationBar(
          unselectedItemColor: Colors.grey[600],
          selectedIconTheme: IconThemeData(color: primaryColor),
          selectedItemColor: primaryColor,
          showUnselectedLabels: true,
          currentIndex: selectedTab.index,
          onTap: (int index) async {
            await comm.tableOpenAll();
            if (index == selectedTab.index && index < 2) {
              Scaffold.of(context).openDrawer();
              return;
            }
            setState(() {
              selectedTab = HomeTab.values[index];
            });
          },
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              label: homeTabNames[HomeTab.bill] ?? '',
              icon: homeTabIcons[HomeTab.bill] ?? const Icon(Icons.circle),
            ),
            BottomNavigationBarItem(
              label: homeTabNames[HomeTab.query] ?? '',
              icon: homeTabIcons[HomeTab.query] ?? const Icon(Icons.circle),
            ),
            BottomNavigationBarItem(
              label: homeTabNames[HomeTab.favorite] ?? '',
              icon: homeTabIcons[HomeTab.favorite] ?? const Icon(Icons.circle),
            ),
            BottomNavigationBarItem(
              label: homeTabNames[HomeTab.note] ?? '',
              icon: homeTabIcons[HomeTab.note] ?? const Icon(Icons.circle),
            ),
            BottomNavigationBarItem(
              label: homeTabNames[HomeTab.meeting] ?? '',
              icon: homeTabIcons[HomeTab.meeting] ?? const Icon(Icons.circle),
            ),
          ],
        );
      }),
      drawer: (selectedTab.index < 2) ? bizQryDrawer : null,
      floatingActionButton: (selectedTab.index == 3)
          ? FloatingActionButton(
              tooltip: '记录收支',
              child: const Icon(Icons.add, size: 32),
              //backgroundColor: primaryColor,
              //foregroundColor: Colors.white,
              onPressed: newNote,
            )
          : null,
    );
  }
}
