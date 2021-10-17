import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:jxcmobile/share/toasts.dart';
import 'package:jxcmobile/share/styles.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/model/query.dart';
import 'package:jxcmobile/page/search_simple.dart';
import 'package:jxcmobile/page/search_mobile.dart';
import 'package:jxcmobile/page/search_trader.dart';
import 'package:jxcmobile/page/search_cargo.dart';

Widget makeReportTitle(String resfields) {
  List<String> cols = resfields.split('\t');
  List<Widget> reportColTitles = [];
  for (int i = 0, iLen = cols.length; i < iLen; ++i) {
    reportColTitles.add(Expanded(
      child: Text(qryResultFieldNames[cols[i]] ?? '', textScaleFactor: 0.75),
    ));
  }
  return (resfields.isEmpty) ? Container() : Row(children: reportColTitles);
}

List<Widget> makeReportValueRows(
    String resfields, String resvalues, Comm comm) {
  List<String> cols = resfields.split('\t');
  List<String> lines = resvalues.split('\n');
  List<Widget> reportValueRows = [];
  if (resfields.isNotEmpty) {
    for (int i = 0, iLen = lines.length; i < iLen; ++i) {
      List<String> vals = lines[i].split('\t');
      if (vals.length == cols.length) {
        List<Widget> vigs = [];
        for (int j = 0, jLen = cols.length; j < jLen; ++j) {
          String val = comm.formatValue(cols[j], vals[j]);
          vigs.add(Expanded(child: Text(val, textScaleFactor: 0.75)));
        }
        reportValueRows.add(
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            color: (lines.length > 1 && i % 2 == 0)
                ? const Color(0xfff0f0f0)
                : Colors.white,
            child: Row(children: vigs),
          ),
        );
      }
    }
  }
  return reportValueRows;
}

/// QueryPage
class QueryPage extends StatefulWidget {
  const QueryPage({
    Key? key,
    required this.qry,
  }) : super(key: key);
  final QueryClip qry;
  @override
  _QueryPageState createState() => _QueryPageState();
}

class _QueryPageState extends State<QueryPage> {
  late final Comm comm;
  bool executed = false;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Future<void> selectSumBiz(BuildContext context) async {
    List<String> nameList = [];
    summNames.forEach((k, v) {
      if (comm.canOpen('vi$k')) {
        nameList.add('+$v');
      } else {
        nameList.add('-$v');
      }
    });

    String result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchSimple(
          title: '选择具体业务',
          noResultMsg: 'notrequired',
          pickList: nameList,
          containsHeaderChar: true,
        ),
      ),
    );

    setState(() {
      String? picked = summNames.keys
          .firstWhereOrNull((k) => result == summNames[k]);
      widget.qry.tname = picked ?? '';
    });
  }

  Future<void> _selectShop(BuildContext context, bool forTrader) async {
    String? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchSimple(
          title: '选择门店',
          noResultMsg: '系统暂无登记门店',
          pickList: comm.shops.map((shop) => shop.kname).toList(),
        ),
      ),
    );
    setState(() {
      if (forTrader) {
        widget.qry.trader = result ?? '';
      } else {
        widget.qry.shop = result ?? '';
      }
    });
  }

  Future<void> _pickTrader(BuildContext context, bool forSupplier) async {
    List<String> traders = (forSupplier)
        ? comm.suppliers.map((trader) => trader.kname).toList()
        : comm.customers.map((trader) => trader.kname).toList();

    String? result = await showSearch(
      context: context,
      delegate: SearchTraderDelegate(
        hintText: (forSupplier) ? '搜索采购厂商' : '搜索批发客户',
        searchList: traders,
      ),
    );

    setState(() {
      widget.qry.trader = result ?? '';
    });
  }

  Future<void> _searchVip(BuildContext context) async {
    if (widget.qry.tname.isEmpty) {
      AppToast.show('请先选择具体业务！', context);
      return;
    }
    List<String>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchMobilePage(
          title: '确认' + Business.traderNameOf(widget.qry.tname),
          tname: widget.qry.tname,
        ),
      ),
    );
    setState(() {
      if (result == null) {
        widget.qry.trader = '';
      } else {
        widget.qry.trader = result[0];
      }
    });
  }

  Future<void> selectCargo(BuildContext context) async {
    Cargo? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchCargoPage(),
      ),
    );
    setState(() {
      widget.qry.cargo = (result != null) ? result.hpcode : '';
      widget.qry.color = '';
      widget.qry.sizer = '';
    });
  }

  void netResponsed() {
    if (comm.netErrorMsg.isNotEmpty) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (comm.currentRequest.isNotEmpty &&
        comm.currentRequest[0].startsWith('QRY') &&
        comm.currentResponse.length == 4) {
      if (comm.currentResponse[3] == 'OK') {
        List<String> rows = comm.currentResponse[2].split('\n');
        setState(() {
          widget.qry.resfields = rows[0];
          if (rows.length > 1) {
            //有值需拼回待用
            widget.qry.resvalues = rows.sublist(1).join('\n');
          } else {
            //无值设格式占位
            List<String> flds = rows[0].split('\t');
            List<String> vals = [];
            for (var _ in flds) {
              vals.add('');
            }
            widget.qry.resvalues = vals.join('\t');
          }
          executed = true;
        });
      } else {
        List<String> resp = comm.currentResponse;
        AppToast.show((resp.length > 2) ? resp[2] : '查询不成功', context);
      }
      comm.clearResponse();
    }
  }

  @override
  void initState() {
    super.initState();
    comm = Provider.of<Comm>(context, listen: false);
    comm.addListener(netResponsed);
  }

  @override
  void dispose() {
    comm.removeListener(netResponsed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (comm.bindShop.isNotEmpty) widget.qry.shop = comm.bindShop;
    if (comm.bindTrader.isNotEmpty) widget.qry.trader = comm.bindTrader;
    final Color primaryColor = Theme.of(context).primaryColor;
    final QueryClip qry = widget.qry;

    if (qry.dateb == 0) qry.dateb = todayEpochSeconds();
    if (qry.datee == 0) qry.datee = todayEpochSeconds();
    final dateb = DateTime.fromMillisecondsSinceEpoch(1000 * qry.dateb);
    final datee = DateTime.fromMillisecondsSinceEpoch(1000 * qry.datee);

    final String checkkTristateTitle =
        (qry.checkk == 0) ? '全部不限' : ((qry.checkk == 1) ? '仅限已审' : '仅限未审');
    final String checkkTwoTitle = (qry.checkk == 0) ? '全部不限' : '仅限已审';
    final bool? checkkTristateValue =
        (qry.checkk == 0) ? null : (qry.checkk == 1);
    final bool checkkTwoValue = (qry.checkk == 1);
    final bool checkUseTristate = (qry.qtype == 'summ');

    final bizTableField = TextFormField(
      key: Key('__fieldTnameValue${qry.tname}'),
      initialValue: summNames[qry.tname] ?? '',
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: '具体业务（必选）',
        labelStyle: TextStyle(
          color: primaryColor,
        ),
        isDense: true,
        suffixIcon: GestureDetector(
          child: const Icon(Icons.search),
          onTap: () => selectSumBiz(context),
        ),
      ),
    );

    final datebField = TextFormField(
      key: Key('__fieldBatebValue${qry.dateb}'),
      initialValue: DateFormat('yyyy-M-d').format(dateb),
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: '开始日期',
        labelStyle: TextStyle(
          color: primaryColor,
        ),
        isDense: true,
        suffixIcon: GestureDetector(
          child: const Icon(Icons.date_range),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: dateb,
              firstDate: DateTime(2000, 1),
              lastDate: DateTime(2200),
              locale: const Locale.fromSubtags(languageCode: 'zh'),
            );
            if (picked != null && picked != dateb) {
              setState(() {
                qry.dateb = picked.millisecondsSinceEpoch ~/ 1000;
              });
            }
          },
        ),
      ),
    );

    final dateeField = TextFormField(
      key: Key('__fieldBateeValue${qry.datee}'),
      initialValue: DateFormat('yyyy-M-d').format(datee),
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: '截至日期',
        labelStyle: TextStyle(
          color: primaryColor,
        ),
        isDense: true,
        suffixIcon: GestureDetector(
          child: const Icon(Icons.date_range),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: datee,
              firstDate: DateTime(2000, 1),
              lastDate: DateTime(2100),
              locale: const Locale.fromSubtags(languageCode: 'zh'),
            );
            if (picked != null && picked != datee) {
              setState(() {
                qry.datee = picked.millisecondsSinceEpoch ~/ 1000;
              });
            }
          },
        ),
      ),
    );

    final traderField = TextFormField(
      key: Key('__fieldTraderValue${qry.trader}'),
      initialValue: (qry.tname != 'syd') ? qry.trader : qry.shop,
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText:
            (qry.tname.isEmpty) ? '对方' : Business.traderNameOf(qry.tname),
        labelStyle: TextStyle(
          color: primaryColor,
        ),
        isDense: true,
        suffixIcon: GestureDetector(
          child: Icon((comm.bindTrader.isEmpty && qry.tname != 'syd')
              ? Icons.search
              : Icons.lock),
          onTap: (comm.bindTrader.isEmpty &&
                  qry.tname != 'syd' &&
                  qry.tname != 'dbd')
              ? ((qry.tname == 'lsd')
                  ? () => _searchVip(context)
                  : () => _pickTrader(context, qry.tname.startsWith('cg')))
              : ((qry.tname == 'dbd')
                  ? () => _selectShop(context, true)
                  : null),
        ),
      ),
    );

    final shopField = TextFormField(
      key: Key('__fieldShopValue${qry.shop}'),
      initialValue: qry.shop,
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: Business.shopNameOf(qry.tname),
        labelStyle: TextStyle(
          color: primaryColor,
        ),
        isDense: true,
        suffixIcon: GestureDetector(
          child: Icon((comm.bindShop.isEmpty) ? Icons.search : Icons.lock),
          onTap: (comm.bindShop.isEmpty)
              ? () => _selectShop(context, false)
              : null,
        ),
      ),
    );

    final cargoField = TextFormField(
      key: Key('__fieldCargoValue${qry.cargo}'),
      initialValue: qry.cargo,
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: '货号',
        labelStyle: TextStyle(
          color: primaryColor,
        ),
        isDense: true,
        suffixIcon: GestureDetector(
          child: const Icon(Icons.search),
          onTap: () => selectCargo(context),
        ),
      ),
    );

    final colorField = TextFormField(
      key: Key('__fieldColorValue${qry.color}'),
      initialValue: qry.color,
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: '颜色',
        labelStyle: TextStyle(
          color: primaryColor,
        ),
        isDense: true,
        suffixIcon: GestureDetector(
          child: const Icon(Icons.keyboard_arrow_down),
          onTap: () async {
            String? picked = await showModalBottomSheet<String>(
                context: context,
                builder: (BuildContext context) {
                  Cargo objCargo =
                      comm.cargos.firstWhere((e) => e.hpcode == qry.cargo);
                  List<String> items = comm.colorItemsOf(objCargo);
                  return buildWheelPicker(context, items);
                });
            setState(() {
              qry.color = picked ?? '';
            });
          },
        ),
      ),
    );

    final sizerField = TextFormField(
      key: Key('__fieldSizerValue${qry.sizer}'),
      initialValue: qry.sizer,
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: '尺码',
        labelStyle: TextStyle(
          color: primaryColor,
        ),
        isDense: true,
        suffixIcon: GestureDetector(
          child: const Icon(Icons.keyboard_arrow_down),
          onTap: () async {
            String? picked = await showModalBottomSheet<String>(
                context: context,
                builder: (BuildContext context) {
                  Cargo objCargo =
                      comm.cargos.firstWhere((e) => e.hpcode == qry.cargo);
                  List<String> items = comm.sizerItemsOf(objCargo);
                  return buildWheelPicker(context, items);
                });
            setState(() {
              qry.sizer = picked ?? '';
            });
          },
        ),
      ),
    );

    void submmitQuery() {
      if (qry.qtype == 'view' && qry.cargo.isEmpty) {
        AppToast.show('货号必须指定！', context, colored: true);
        return;
      }
      if (qry.qtype == 'summ' && qry.tname.isEmpty) {
        AppToast.show('具体业务必须指定！', context, colored: true);
        return;
      }
      FocusScope.of(context).unfocus();
      qry.resfields = '';
      qry.resvalues = '';
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        int reqId = (DateTime.now()).microsecondsSinceEpoch;
        List<String> params = [
          'QRY${qry.qtype.toUpperCase()}',
          reqId.toString(),
          qry.tname,
          qry.shop,
          qry.trader,
          qry.cargo,
          qry.color,
          qry.sizer,
          formatFromEpochSeconds(qry.dateb),
          formatFromEpochSeconds(qry.datee),
          qry.checkk.toString()
        ];
        comm.workRequest(context, params);
      }
    }

    void clearReset() {
      setState(() {
        qry.shop = '';
        qry.trader = '';
        qry.cargo = '';
        qry.color = '';
        qry.sizer = '';
        qry.checkk = 0;
        qry.dateb = todayEpochSeconds();
        qry.datee = todayEpochSeconds();
      });
    }

    final reportButtons = Column(
      children: <Widget>[
        SizedBox(
          width: 200,
          child: ElevatedButton(
            child: const Text('保留', textScaleFactor: 1.2),
            onPressed: () {
              Navigator.pop(context, qry);
            },
          ),
        ),
        TextButton(
          child: Text(
            '取消',
            textScaleFactor: 1.2,
            style: TextStyle(color: primaryColor),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );

    //总布局
    return Scaffold(
      appBar: AppBar(
        title: Text('${qry.titleName(true)}查询'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.always,
          child: Column(
            children: <Widget>[
              (qry.qtype == 'summ') ? bizTableField : Container(),
              (qry.tname.isNotEmpty &&
                      qry.tname != 'syd' &&
                      qry.qtype != 'stock' &&
                      qry.qtype != 'view')
                  ? traderField
                  : Container(),
              (qry.qtype != 'cash' && qry.qtype != 'rest')
                  ? shopField
                  : Container(),
              (qry.qtype != 'cash') ? cargoField : Container(),
              (qry.qtype == 'stock' && qry.cargo.isNotEmpty)
                  ? colorField
                  : Container(),
              (qry.qtype == 'stock' && qry.cargo.isNotEmpty)
                  ? sizerField
                  : Container(),
              (qry.qtype != 'stock' &&
                      qry.qtype != 'cash' &&
                      qry.qtype != 'rest')
                  ? datebField
                  : Container(),
              dateeField,
              TextFormField(
                key: Key('__fieldCheckkValue${qry.checkk}'),
                initialValue:
                    (checkUseTristate) ? checkkTristateTitle : checkkTwoTitle,
                readOnly: true,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: '审核状态',
                  labelStyle: TextStyle(
                    color: primaryColor,
                  ),
                  isDense: true,
                  suffixIcon: Checkbox(
                    value: (checkUseTristate)
                        ? checkkTristateValue
                        : checkkTwoValue,
                    tristate: checkUseTristate,
                    onChanged: (v) {
                      setState(() {
                        if (checkUseTristate) {
                          qry.checkk = (v == null) ? 0 : ((v) ? 1 : 2);
                        } else {
                          qry.checkk = (v == true) ? 1 : 0;
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 9),
              TextButton(
                child: Text(
                  '重设',
                  textScaleFactor: 1.2,
                  style: TextStyle(color: primaryColor),
                ),
                onPressed: clearReset,
              ),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  child: const Text('执行', textScaleFactor: 1.2),
                  onPressed: submmitQuery,
                ),
              ),
              const SizedBox(height: 12),
              makeReportTitle(qry.resfields),
              ...makeReportValueRows(qry.resfields, qry.resvalues, comm),
              (qry.resvalues.isEmpty) ? const Text('无结果') : Container(),
              const SizedBox(height: 12),
              (executed) ? reportButtons : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
