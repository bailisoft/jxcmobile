import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/share/toasts.dart';
import 'package:jxcmobile/model/bill.dart';
import 'package:jxcmobile/part/bill_detail.dart';
import 'package:jxcmobile/page/search_simple.dart';
import 'package:jxcmobile/page/search_mobile.dart';
import 'package:jxcmobile/page/search_trader.dart';
import 'package:jxcmobile/page/search_cargo.dart';

/// BillPage
class BillPage extends StatefulWidget {
  const BillPage({
    Key? key,
    required this.bill,
  }) : super(key: key);
  final Bill bill;
  @override
  _BillPageState createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  late final Comm comm;
  double traderDiscount = 1.0;
  bool ticketPrintChecked = false;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  //必需。只有设有controller，在其他选择弹窗退回时，已填文本值才不会清空。
  final remarkController = TextEditingController();
  final actpayController = TextEditingController();

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
        widget.bill.trader = result ?? '';
      } else {
        widget.bill.shop = result ?? '';
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
      widget.bill.trader = result ?? '';
      traderDiscount = 1.0;
      if (forSupplier) {
        Supplier? trader =
            comm.suppliers.firstWhereOrNull((e) => e.kname == result);
        if (trader != null) traderDiscount = trader.regdis;
      } else {
        Customer? trader =
            comm.customers.firstWhereOrNull((e) => e.kname == result);
        if (trader != null) traderDiscount = trader.regdis;
      }
    });
  }

  Future<void> _searchVip(BuildContext context) async {
    List<String>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchMobilePage(
          title: '确认' + Business.traderNameOf(widget.bill.tname),
          tname: widget.bill.tname,
        ),
      ),
    );
    setState(() {
      if (result != null && result.isNotEmpty) {
        widget.bill.trader = result[0];
        traderDiscount = (double.tryParse(result[1]) ?? 10000) / 10000;
      } else {
        widget.bill.trader = '';
        traderDiscount = 1.0;
      }
    });
  }

  Future<void> selectStaff(BuildContext context) async {
    String? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchSimple(
          title: '选择业务员',
          noResultMsg: '系统暂无登记业务员',
          pickList: comm.staffs.map((staff) => staff.kname).toList(),
        ),
      ),
    );
    setState(() {
      widget.bill.staff = result ?? '';
    });
  }

  Future<void> selectStype(BuildContext context) async {
    String? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchSimple(
          title: '选择细分类',
          noResultMsg: '系统暂无此业务细分类',
          pickList: comm.bsubTypes.getTypesOf(widget.bill.tname),
        ),
      ),
    );
    setState(() {
      widget.bill.stype = result ?? '';
    });
  }

  Future<void> selectCargo(BuildContext context) async {
    Cargo? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchCargoPage(),
      ),
    );
    if (result == null) {
      return;
    }
    final comm = Provider.of<Comm>(context, listen: false);
    setState(() {
      double initPrice = result.setprice;
      if (widget.bill.tname == 'lsd') initPrice = result.retprice;
      if (widget.bill.tname.startsWith('pf')) initPrice = result.lotprice;
      if (widget.bill.tname.startsWith('cg')) initPrice = result.buyprice;

      double applyDiscount = traderDiscount;

      //print('客：${widget.bill.trader}, 货：${result.hpcode}， 客统折：$traderDiscount');
      //价格政策
      if ((widget.bill.tname.startsWith('pf') || widget.bill.tname == 'lsd')) {
        for (int i = 0, iLen = comm.policies.length; i < iLen; ++i) {
          Policy pol = comm.policies[i];
          int epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          if (pol.startDate <= epoch && pol.endDate >= epoch) {
            RegExp traderExp = RegExp('^' + pol.traderExp + '\$');
            RegExp cargoExp = RegExp('^' + pol.cargoExp + '\$');
            if (pol.traderExp.isEmpty ||
                traderExp.hasMatch(widget.bill.trader)) {
              if (pol.cargoExp.isEmpty || cargoExp.hasMatch(result.hpcode)) {
                applyDiscount = pol.policyDis;
                break;
              }
            }
          }
        }
      }

      initPrice = initPrice * applyDiscount;
      widget.bill.detailList
          .add(BillDetail(cargo: result, qty: 1, actPrice: initPrice));
      widget.bill.syncMainTotal();
    });
  }

  double _sumQty() {
    double sum = 0;
    for (BillDetail detail in widget.bill.detailList) {
      sum += detail.qty;
    }
    return sum;
  }

  double _sumMoney() {
    double sum = 0.0;
    for (BillDetail detail in widget.bill.detailList) {
      sum += detail.qty * detail.actPrice;
    }
    return sum;
  }

  void netResponsed() {
    if (comm.netErrorMsg.isNotEmpty) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (comm.currentRequest.isNotEmpty &&
        comm.currentRequest[0] == 'BIZINSERT' &&
        comm.currentResponse.isNotEmpty) {
      List<String> resp = comm.currentResponse;
      if (resp[resp.length - 1] == 'OK') {
        int newSheetId = int.tryParse(resp[2]) ?? 0;
        int newDated = int.tryParse(resp[3]) ?? 0;
        widget.bill.sheetid = newSheetId;
        widget.bill.dated = newDated;
        comm.tableSave(
            billHiveTable, widget.bill.id.toString(), widget.bill.joinMain(),
            notify: true);
        Navigator.pop(context, 'saved');
      } else {
        AppToast.show((resp.length > 2) ? resp[2] : '提交不成功', context);
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
    remarkController.dispose();
    actpayController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    if (widget.bill.sheetid == 0) {
      widget.bill.syncMainTotal();
    }
    super.deactivate();
  }

  void printPosTicket(bool reprintt) async {
    //printer's
    if (comm.currentPrinterDevice == null ||
        comm.printerState != PrinterState.psConnected) return;

    widget.bill.syncMainTotal();

    Map<String, dynamic> config = {};
    List<LineText> list = [];

//    //comLogo
//    Uint8List imageBytes;
//    if (comm.comLogo == null) {
//      final ByteData data =
//          await rootBundle.load('assets/splash_effects/baililogo.png');
//      //TODO...缩放
//      imageBytes =
//          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
//    } else {
//      //imageBytes = base64Decode(comm.comLogo);
//
//      //TODO...缩放
//      pluginImage.Image image =
//          pluginImage.decodeImage(base64Decode(comm.comLogo));
//      pluginImage.Image thumbnail = pluginImage.copyResize(image, width: 64);
//      imageBytes = pluginImage.encodePng(thumbnail);
//    }
//    String base64Image = base64Encode(imageBytes);
//    list.add(LineText(
//      type: LineText.TYPE_IMAGE,
//      content: base64Image,
//      align: LineText.ALIGN_CENTER,
//      linefeed: 1,
//    ));

    //bill
    final bill = widget.bill;

    //comName
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: comm.comName,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));

    //bill Name
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: bizNames[bill.tname],
      weight: 1,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));

    //header fields
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));

    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '门店：${bill.shop}',
      linefeed: 1,
    ));
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '顾客：${bill.trader}',
      linefeed: 1,
    ));
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '备注：${bill.remark}',
      linefeed: 1,
    ));

    //detail lines
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '==============================',
      linefeed: 1,
    ));
    for (int i = 0, iLen = bill.detailList.length; i < iLen; ++i) {
      BillDetail detail = bill.detailList[i];
      double lineMoney = detail.actPrice * detail.qty;
      String line1 = '${detail.cargo.hpcode} ${detail.cargo.hpname} '
          '${detail.colorType} ${detail.sizerType}';
      String line2 = '${detail.actPrice.toStringAsFixed(comm.priceDots)} x '
          '${detail.qty.toStringAsFixed(comm.qtyDots)} = '
          '${lineMoney.toStringAsFixed(comm.moneyDots)}';
      list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: line1,
        linefeed: 1,
      ));
      list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: line2,
        align: LineText.ALIGN_RIGHT,
        linefeed: 1,
      ));
      if (i < iLen - 1) {
        list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '--------------------',
          align: LineText.ALIGN_RIGHT,
          linefeed: 1,
        ));
      }
    }
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '==============================',
      linefeed: 1,
    ));

    //summary values
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '数量合计：${bill.sumqty.toStringAsFixed(comm.qtyDots)}',
      linefeed: 1,
    ));
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '金额合计：${bill.summoney.toStringAsFixed(comm.moneyDots)}',
      linefeed: 1,
    ));
    if (bill.tname == 'pff' || bill.tname == 'pft') {
      list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '本单实收：${bill.actpay.toStringAsFixed(comm.moneyDots)}',
        linefeed: 1,
      ));
      list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '本次欠款：${bill.actowe.toStringAsFixed(comm.moneyDots)}',
        linefeed: 1,
      ));
    }
    //list.add(LineText(linefeed: 1));

    //附加信息
    if (comm.printAttachText.isNotEmpty) {
      list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '==============================',
        linefeed: 1,
      ));
      List<String> attatches = comm.printAttachText.split('\n');
      for (var line in attatches) {
        list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: line,
          linefeed: 1,
        ));
      }
    }

    //print out
    if (reprintt) {
      await comm.appPrinter.printReceipt(config, list);
    } else {
      for (int i = 0; i < comm.printCopies; ++i) {
        await comm.appPrinter.printReceipt(config, list);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (comm.bindShop.isNotEmpty) widget.bill.shop = comm.bindShop;
    if (comm.bindTrader.isNotEmpty) widget.bill.trader = comm.bindTrader;
    final Color primaryColor = Theme.of(context).primaryColor;
    final Bill bill = widget.bill;
    actpayController.text = bill.actpay.toStringAsFixed(comm.moneyDots);

    //sheetid
    final sheetidEdit = Text('<新单>', style: TextStyle(color: primaryColor));
    final sheetidRead = Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        '${bill.tname.toUpperCase()}-${bill.sheetid.toString().padLeft(9, '0')}',
        style: TextStyle(color: primaryColor),
        textScaleFactor: 1.5,
      ),
    );

    //shop
    final shopEdit = TextFormField(
      key: Key('__fieldShopValue${bill.shop}'),
      initialValue: bill.shop,
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: Business.shopNameOf(bill.tname),
        labelStyle: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
        suffixIcon: GestureDetector(
          child: Icon((comm.bindShop.isEmpty) ? Icons.search : Icons.lock),
          onTap: (comm.bindShop.isEmpty)
              ? () => _selectShop(context, false)
              : null,
        ),
      ),
    );
    final shopRead = Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text('${Business.shopNameOf(bill.tname)}：',
              style: TextStyle(color: primaryColor)),
        ),
        Expanded(
          flex: 3,
          child: Text(bill.shop),
        ),
      ],
    );

    //trader
    final traderEdit = TextFormField(
      key: Key('__fieldTraderValue${bill.trader}'),
      initialValue: (bill.tname != 'syd') ? bill.trader : bill.shop,
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: Business.traderNameOf(bill.tname),
        labelStyle: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
        suffixIcon: GestureDetector(
          child: Icon((comm.bindTrader.isEmpty && bill.tname != 'syd')
              ? Icons.search
              : Icons.lock),
          onTap: (comm.bindTrader.isEmpty &&
                  bill.tname != 'syd' &&
                  bill.tname != 'dbd')
              ? ((bill.tname == 'lsd')
                  ? () => _searchVip(context)
                  : () => _pickTrader(context, bill.tname.startsWith('cg')))
              : ((bill.tname == 'dbd')
                  ? () => _selectShop(context, true)
                  : null),
        ),
      ),
    );
    final traderRead = Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text('${Business.traderNameOf(bill.tname)}：',
              style: TextStyle(color: primaryColor)),
        ),
        Expanded(
          flex: 3,
          child: Text((bill.tname != 'syd') ? bill.trader : bill.shop),
        ),
      ],
    );

    //stype
    final stypeEdit = TextFormField(
      key: Key('__fieldStypeValue${bill.stype}'),
      initialValue: bill.stype,
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: '细分类',
        labelStyle: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
        suffixIcon: GestureDetector(
          child: const Icon(Icons.search),
          onTap: () => selectStype(context),
        ),
      ),
    );
    final stypeRead = Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text('细分类：', style: TextStyle(color: primaryColor)),
        ),
        Expanded(
          flex: 3,
          child: Text(bill.stype),
        ),
      ],
    );

    //staff
    final staffEdit = TextFormField(
      key: Key('__fieldStaffValue${bill.staff}'),
      initialValue: bill.staff,
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: '业务员',
        labelStyle: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
        suffixIcon: GestureDetector(
          child: const Icon(Icons.search),
          onTap: () => selectStaff(context),
        ),
      ),
    );
    final staffRead = Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text('业务员：', style: TextStyle(color: primaryColor)),
        ),
        Expanded(
          flex: 3,
          child: Text(bill.staff),
        ),
      ],
    );

    //remark
    final remarkEdit = TextFormField(
      key: Key('__cargobillRemarkValue${bill.remark}'),
      controller: remarkController,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: '备注',
        labelStyle: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
      ),
      onChanged: (String value) {
        bill.remark = value;
      },
    );
    final remarkRead = Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text('备注：', style: TextStyle(color: primaryColor)),
        ),
        Expanded(
          flex: 3,
          child: Text(bill.remark),
        ),
      ],
    );

    //sumqty
    final sumqtyEdit = Row(
      children: <Widget>[
        Expanded(
            child: Text(
          '数量合计',
          style: TextStyle(color: primaryColor),
        )),
        Expanded(
          child: Align(
            child: Text(
              _sumQty().toStringAsFixed(comm.qtyDots),
              textScaleFactor: 1.2,
              style: TextStyle(color: primaryColor),
            ),
            alignment: Alignment.centerRight,
          ),
        ),
      ],
    );
    final sumqtyRead = Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text('数量合计：', style: TextStyle(color: primaryColor)),
        ),
        Expanded(
          flex: 3,
          child: Text(bill.sumqty.toStringAsFixed(comm.qtyDots)),
        ),
      ],
    );

    //summoney
    final summoneyEdit = Row(
      children: <Widget>[
        Expanded(
            child: Text(
          '金额合计',
          style: TextStyle(color: primaryColor),
        )),
        Expanded(
          child: Align(
            child: Text(
              _sumMoney().toStringAsFixed(comm.moneyDots),
              textScaleFactor: 1.2,
              style: TextStyle(color: primaryColor),
            ),
            alignment: Alignment.centerRight,
          ),
        ),
      ],
    );
    final summoneyRead = Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text('金额合计：', style: TextStyle(color: primaryColor)),
        ),
        Expanded(
          flex: 3,
          child: Text(bill.summoney.toStringAsFixed(comm.moneyDots)),
        ),
      ],
    );

    //actpay
    final actpayEdit = TextFormField(
      controller: actpayController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.right,
      readOnly: true,
      decoration: InputDecoration(
        labelText: Business.payNameOf(bill.tname),
        labelStyle: TextStyle(color: Theme.of(context).primaryColor),
        //prefixIcon: Icon(Icons.keyboard, color: primaryColor),
      ),
      onTap: () async {
        double? val = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ValueEditDialog(
              title: '输入${Business.payNameOf(bill.tname)}',
              initValue: 0,
              dots: comm.moneyDots,
            ),
          ),
        );
        if (val != null) {
          setState(() {
            actpayController.text = val.toStringAsFixed(comm.moneyDots);
            bill.actpay = val;
            bill.actowe = _sumMoney() - val;
          });
        }
      },
    );
    final actpayRead = Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text('${Business.payNameOf(bill.tname)}：',
              style: TextStyle(color: primaryColor)),
        ),
        Expanded(
          flex: 3,
          child: Text(bill.actpay.toStringAsFixed(comm.moneyDots)),
        ),
      ],
    );

    //actowe
    final actoweEdit = Row(
      children: <Widget>[
        Expanded(
            child: Text(
          '本次欠款',
          style: TextStyle(color: primaryColor),
        )),
        Expanded(
          child: Align(
            child: Text(
              bill.actowe.toStringAsFixed(comm.moneyDots),
              textScaleFactor: 1.2,
              style: TextStyle(color: primaryColor),
            ),
            alignment: Alignment.centerRight,
          ),
        ),
      ],
    );
    final actoweRead = Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text('本次欠款：', style: TextStyle(color: primaryColor)),
        ),
        Expanded(
          flex: 3,
          child: Text(bill.actowe.toStringAsFixed(comm.moneyDots)),
        ),
      ],
    );

    final detailAddButton = ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 5.0,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(9.0),
      ),
      child: const Tooltip(
        message: '添加明细',
        child: Icon(Icons.add, color: Colors.white),
      ),
      onPressed: () {
        selectCargo(context);
      },
    );

    //小票打印按钮
    final ticketPrintCheck = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Checkbox(
          value: ticketPrintChecked,
          onChanged: (bool? newValue) {
            setState(() {
              ticketPrintChecked = newValue ?? false;
            });
          },
        ),
        const Text('提交同时打印小票'),
      ],
    );
    final ticketPrintButton = ElevatedButton(
      child: const Text('补打小票'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 90),
      ),
      onPressed: () {
        printPosTicket(true);
      },
    );

    //提交按钮
    final formPostButton = ElevatedButton(
      child: const Text('提交', textScaleFactor: 1.2),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 90),
      ),
      onPressed: () {
        FocusScope.of(context).unfocus();
        if (formKey.currentState!.validate()) {
          formKey.currentState!.save();

          //色码如有必填检查
          for (BillDetail detail in bill.detailList) {
            List<String> colors = comm.colorItemsOf(detail.cargo);
            if (colors.isNotEmpty && detail.colorType.isEmpty) {
              AppToast.show('${detail.cargo.hpcode}有颜色未指定！', context,
                  colored: true);
              return;
            }
            List<String> sizers = comm.sizerItemsOf(detail.cargo);
            if (sizers.isNotEmpty && detail.sizerType.isEmpty) {
              AppToast.show('${detail.cargo.hpcode}有尺码未指定！', context,
                  colored: true);
              return;
            }
          }

          //合计
          bill.sumqty = _sumQty();
          bill.summoney = _sumMoney();

          //网络请求
          List<String> mValues = [
            bill.shop,
            bill.trader,
            bill.stype,
            bill.staff,
            bill.remark,
            (bill.actpay * 10000).toStringAsFixed(0)
          ];
          List<String> dValues = [];
          for (BillDetail detail in bill.detailList) {
            List<String> cols = [
              detail.cargo.hpcode,
              detail.colorType,
              detail.sizerType,
              (detail.qty * 10000).toStringAsFixed(0),
              (detail.actPrice * 10000).toStringAsFixed(0)
            ];
            dValues.add(cols.join('\t'));
          }
          int reqId = (DateTime.now()).microsecondsSinceEpoch;
          List<String> params = [
            'BIZINSERT',
            reqId.toString(),
            bill.tname,
            mValues.join('\t'),
            dValues.join('\n')
          ];
          comm.workRequest(context, params);

          //检查打印
          if (ticketPrintChecked) printPosTicket(false);
        }
      },
    );

    //取消按钮
    final formCancelButton = TextButton(
      child: const Text('重填', textScaleFactor: 1.2),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 90),
      ),
      onPressed: () {
        setState(() {
          bill.shop = '';
          bill.trader = '';
          bill.stype = '';
          bill.staff = '';
          bill.remark = '';
          bill.actpay = 0;
          bill.actowe = 0;
          bill.detailList.clear();
        });
        remarkController.clear();
        actpayController.clear();
      },
    );

    //总构建
    return Scaffold(
      appBar: AppBar(
        title: Text(
          bizNames[bill.tname] ?? '',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.always,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 6.0),
              (bill.sheetid > 0) ? sheetidRead : sheetidEdit,
              (bill.sheetid > 0) ? shopRead : shopEdit,
              (bill.sheetid > 0) ? traderRead : traderEdit,
              (bill.sheetid > 0) ? stypeRead : stypeEdit,
              (bill.sheetid > 0) ? staffRead : staffEdit,
              (bill.sheetid > 0) ? remarkRead : remarkEdit,
              const SizedBox(height: 12.0),
              for (BillDetail detail in bill.detailList)
                CargoDetailItem(
                  readOnly: (bill.sheetid > 0),
                  detail: detail,
                  onRemoved: () {
                    setState(() {
                      bill.detailList.remove(detail);
                      bill.syncMainTotal();
                    });
                  },
                  onChanged: () {
                    setState(() {
                      bill.syncMainTotal();
                    });
                  },
                ),
              (bill.sheetid > 0) ? Container() : detailAddButton,
              const SizedBox(height: 12.0),
              (bill.sheetid > 0) ? sumqtyRead : sumqtyEdit,
              (bill.sheetid > 0) ? summoneyRead : summoneyEdit,
              (bill.sheetid > 0) ? actpayRead : actpayEdit,
              (bill.sheetid > 0) ? actoweRead : actoweEdit,
              const SizedBox(height: 20.0),
              (bill.sheetid > 0) ? ticketPrintButton : ticketPrintCheck,
              (bill.sheetid > 0) ? Container() : formPostButton,
              (bill.sheetid > 0) ? Container() : formCancelButton,
            ],
          ),
        ),
      ),
    );
  }
}
