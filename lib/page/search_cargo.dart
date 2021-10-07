import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/share/toasts.dart';

/// CargoHeadLine
class CargoHeadLine extends StatelessWidget {
  final BuildContext context;
  final Cargo cargo;
  const CargoHeadLine({
    Key? key,
    required this.context,
    required this.cargo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: <Widget>[
            Expanded(child: Text(cargo.hpcode), flex: 2),
            Expanded(child: Text(cargo.hpname), flex: 2),
            Expanded(
              child: Align(
                child: Text('￥${cargo.setprice}'),
                alignment: Alignment.centerRight,
              ),
              flex: 1,
            ),
          ],
        ),
      ),
      //轻按选择
      onTap: () {
        Navigator.pop(context, cargo);
      },
      //长按看图
      onLongPress: () async {
        //先检查是否已有加载过图片
        if (cargo.imagedata.isNotEmpty) {
          bottomPopCargoImage(context, cargo);
        } else {
          //先查本地文件
          final comm = Provider.of<Comm>(context, listen: false);
          String imgData = comm.tableValueOf(imageHiveTable, cargo.hpcode) ?? '';
          if ( imgData.isNotEmpty ) {
            cargo.imagedata = imgData;
            bottomPopCargoImage(context, cargo);
            return;
          }
          //最后请求
          int reqId = (DateTime.now()).microsecondsSinceEpoch;
          List<String> params = ['GETIMAGE', reqId.toString(), cargo.hpcode];
          comm.workRequest(context, params);
        }
      },
    );
  }
}

/// SearchCargoPage
class SearchCargoPage extends StatefulWidget {
  const SearchCargoPage({Key? key}) : super(key: key);

  @override
  _SearchCargoPageState createState() => _SearchCargoPageState();
}

class _SearchCargoPageState extends State<SearchCargoPage> {
  static const int maxShowCount = 100;
  final controller = TextEditingController();
  String terms = '';
  late final Comm comm;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onSearchTextChanged);
    comm = Provider.of<Comm>(context, listen: false);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    setState(() => terms = controller.text);
  }

  Widget buildSearchResults(List<Cargo> cargos) {
    String resultHint = '';
    if (cargos.isEmpty) resultHint = '无此匹配';
    if (cargos.length > maxShowCount) resultHint = '太多匹配';

    if (resultHint.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            resultHint,
            //style: Styles.headlineDescription,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: cargos.length,
      separatorBuilder: (context, i) => Container(
        height: 1,
        color: Colors.grey,
      ),
      itemBuilder: (context, i) {
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: CargoHeadLine(context: context, cargo: cargos[i]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    List<Cargo> showCargos = comm.searchCargos(terms);
    String footerHint = '';
    if (showCargos.length < maxShowCount && showCargos.isNotEmpty) {
      footerHint = '轻触选择、长按看图。';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('添加货品')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.visiblePassword,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: '货号或品名拼音任意筛选',
                hintStyle: TextStyle(color: primaryColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
                suffixIcon: GestureDetector(
                  child: Icon(Icons.clear, color: primaryColor),
                  onTap: () {
                    //controller.clear();  //BUG
                    WidgetsBinding.instance!.addPostFrameCallback(
                      (_) => controller.clear(),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: buildSearchResults(showCargos),
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            footerHint,
            textScaleFactor: 0.8,
            style: TextStyle(color: primaryColor),
          ),
          const SizedBox(height: 12.0),
        ],
      ),
    );
  }
}
