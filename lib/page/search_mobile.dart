import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/share/toasts.dart';

class SearchMobilePage extends StatefulWidget {
  final String title;
  final String tname;
  const SearchMobilePage({
    Key? key,
    required this.title,
    required this.tname,
  }) : super(key: key);

  @override
  _SearchMobilePageState createState() => _SearchMobilePageState();
}

class _SearchMobilePageState extends State<SearchMobilePage> {
  final searchFocuser = FocusNode();
  final regManFocuser = FocusNode();
  final regAddrFocuser = FocusNode();
  final regMarkFocuser = FocusNode();
  final searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String regManValue = '';
  String regAddrValue = '';
  String regMarkValue = '';
  bool showImitage = false;

  late final Comm comm;
  List<String> searchResult = [];

  @override
  void initState() {
    super.initState();
    comm = Provider.of<Comm>(context, listen: false);
    comm.addListener(netResponsed);
  }

  @override
  void dispose() {
    comm.removeListener(netResponsed);
    searchFocuser.dispose();
    regManFocuser.dispose();
    regAddrFocuser.dispose();
    regMarkFocuser.dispose();
    searchController.dispose();
    super.dispose();
  }

  void netResponsed() {
    if (comm.netErrorMsg.isNotEmpty) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (comm.currentRequest.isNotEmpty &&
        comm.currentRequest[0] == 'GETOBJECT' &&
        comm.currentResponse.isNotEmpty) {
      searchResult = comm.currentResponse;
      comm.clearResponse();
    }

    if (comm.currentRequest.isNotEmpty &&
        comm.currentRequest[0] == 'REGINSERT' &&
        comm.currentResponse.isNotEmpty) {
      List<String> response = comm.currentResponse;
      if (response.length > 2) {
        if (response[response.length - 1] == 'OK') {
          setState(() {
            //登记成功后显示，当然不需要再用查询获取。因此这里模拟查询结果，以显示查询结果卡片
            String fnames = 'kname\tregdis\tregman\tregtele\tregaddr';
            String fvalues = '${searchController.text}\t10000\t$regManValue\t'
                '${searchController.text}\t$regAddrValue';
            searchResult = [
              'REGINSERT',
              '999999999',
              '$fnames\n$fvalues',
              'OK',
            ];
            showImitage = true;
            //重置登记值，已防止下次登记页面时有初始值
            regManValue = '';
            regAddrValue = '';
            regMarkValue = '';
          });
          comm.clearResponse();
        } else {
          AppToast.show(response[2], context);
        }
      }
    }
  }

  void _searchMobile(BuildContext context) async {
    showImitage = false;
    FocusScope.of(context).unfocus();
    String tname = (widget.tname.startsWith('cg')) ? 'supplier' : 'customer';
    String kvalue = searchController.text;
    if (kvalue.isNotEmpty) {
      int reqId = (DateTime.now()).microsecondsSinceEpoch;
      List<String> params = ['GETOBJECT', reqId.toString(), tname, kvalue];
      await comm.workRequest(context, params);
    }
  }

  void _registerTrader(BuildContext context) async {
    if (searchController.text.length < 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('手机号位数太少。')));
      return;
    }
    String tname = (widget.tname.startsWith('cg')) ? 'supplier' : 'customer';
    FocusScope.of(context).unfocus();
    String kvalue = searchController.text; //主要考虑LSD手机号，批发可让后台再处理名称
    String fnames = 'regdis\tregman\tregtele\tregaddr\tregmark';
    String fvalues =
        '10000\t$regManValue\t$kvalue\t$regAddrValue\t$regMarkValue';
    int reqId = (DateTime.now()).microsecondsSinceEpoch;
    List<String> params = [
      'REGINSERT',
      reqId.toString(),
      tname,
      'insert',
      kvalue,
      fnames,
      fvalues
    ];
    await comm.workRequest(context, params);
  }

  Widget _buildSearchResult(BuildContext context) {
    //初始空白
    String searchText = searchController.text;
    if (searchText.isEmpty || searchFocuser.hasFocus || searchResult.length < 3) {
      return Container();
    }

    String regManTitle = (widget.tname == 'lsd') ? '姓名' : '收件人';
    Color titleColor = Theme.of(context).primaryColor;
    List<String> rows = searchResult[2].split('\n');

    //已经登记，显示卡片
    if (rows.length == 2) {
      List<String> cols = rows[1].split('\t');
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        elevation: 6.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: <Widget>[
              Text(cols[0], textScaleFactor: 1.5),
              const SizedBox(height: 18.0),
              Text('享受折扣', style: TextStyle(color: titleColor)),
              Text(((double.tryParse(cols[1]) ?? 10000) / 10000).toString()),
              const SizedBox(height: 18.0),
              Text('收件人', style: TextStyle(color: titleColor)),
              Text((cols[2].isEmpty) ? '-' : cols[2]),
              const SizedBox(height: 18.0),
              Text('收件地址', style: TextStyle(color: titleColor)),
              Text((cols[4].isEmpty) ? '-' : cols[4]),
              SizedBox(height: (showImitage) ? 18.0 : 1.0),
              Text(
                (showImitage) ? '注册成功！' : '',
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 18.0),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('确定', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(context, cols);
                },
              ),
            ],
          ),
        ),
      );
    }

    //无登记，提示注册
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        children: <Widget>[
          Text(
            '$searchText 尚未登记',
            textScaleFactor: 1.5,
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
          Card(
            elevation: 5.0,
            margin: const EdgeInsets.symmetric(vertical: 12.0),
            child: Container(
              padding:
                  const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 18),
              child: Form(
                key: formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      focusNode: regManFocuser,
                      initialValue: regManValue,
                      decoration: InputDecoration(labelText: regManTitle),
                      onSaved: (String? value) => regManValue = value ?? '',
                      onFieldSubmitted: (String value) {
                        regManFocuser.unfocus();
                        FocusScope.of(context).requestFocus(regAddrFocuser);
                      },
                    ),
                    TextFormField(
                      focusNode: regAddrFocuser,
                      initialValue: regAddrValue,
                      decoration: const InputDecoration(labelText: '收件地址'),
                      onSaved: (String? value) => regAddrValue = value ?? '',
                      onFieldSubmitted: (String value) {
                        regAddrFocuser.unfocus();
                        FocusScope.of(context).requestFocus(regMarkFocuser);
                      },
                    ),
                    TextFormField(
                      focusNode: regMarkFocuser,
                      initialValue: regMarkValue,
                      decoration: const InputDecoration(labelText: '备注'),
                      onSaved: (String? value) => regMarkValue = value ?? '',
                      onFieldSubmitted: (String value) {
                        regMarkFocuser.unfocus();
                      },
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      label: const Text(
                        '提交登记',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          _registerTrader(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Builder(builder: (BuildContext ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                child: TextField(
                  focusNode: searchFocuser,
                  controller: searchController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '手机号',
                    suffixIcon: GestureDetector(
                      child: const Icon(Icons.clear),
                      onTap: () {
                        //searchController.clear();  //BUG
                        WidgetsBinding.instance!.addPostFrameCallback(
                          (_) => searchController.clear(),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              ElevatedButton.icon(
                label: const Text('查询', style: TextStyle(color: Colors.white)),
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => _searchMobile(ctx),
              ),
              const SizedBox(height: 12.0),
              _buildSearchResult(ctx),
            ],
          ),
        );
      }),
    );
  }
}
