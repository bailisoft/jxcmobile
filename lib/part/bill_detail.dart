import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/share/styles.dart';
import 'package:jxcmobile/share/toasts.dart';
import 'package:jxcmobile/model/bill.dart';

class CargoDetailItem extends StatefulWidget {
  final bool readOnly;
  final BillDetail detail;
  final VoidCallback onRemoved;
  final VoidCallback onChanged;
  const CargoDetailItem({
    Key? key,
    required this.readOnly,
    required this.detail,
    required this.onRemoved,
    required this.onChanged,
  })  : super(key: key);

  @override
  _CargoDetailItemState createState() => _CargoDetailItemState();
}

class _CargoDetailItemState extends State<CargoDetailItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final comm = Provider.of<Comm>(context, listen: false);

    //iamge
    final imageField = (widget.detail.cargo.imagedata.isNotEmpty)
        ? Image.memory(
            base64Decode(widget.detail.cargo.imagedata),
            width: 100,
            height: 100,
          )
        : GestureDetector(
            child: getCargoPlaceholder(100),
            onTap: () async {
              //再请求网络
              int reqId = (DateTime.now()).microsecondsSinceEpoch;
              List<String> params = [
                'GETIMAGE',
                reqId.toString(),
                widget.detail.cargo.hpcode
              ];
              comm.workRequest(context, params);
            },
          );

    //setprice
    final setPriceField = Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(99.0),
      ),
      child: Text(
        widget.detail.cargo.setprice.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    //hpcode
    final hpcodeField = Text(
      widget.detail.cargo.hpcode,
      textScaleFactor: 1.5,
      style: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w900,
      ),
    );

    //hpname
    final hpnameField = Text(
      widget.detail.cargo.hpname,
      textScaleFactor: 0.8,
      style: TextStyle(color: primaryColor),
    );

    //color
    final colorEdit = GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(0.0),
        decoration: const BoxDecoration(), //for capture gesture
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '颜色',
              textScaleFactor: 0.85,
              style: TextStyle(color: primaryColor),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(widget.detail.colorType),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    child: Icon(Icons.keyboard_arrow_down, color: primaryColor),
                    alignment: Alignment.centerRight,
                  ),
                ),
              ],
            ),
            Container(height: 1, color: Colors.grey),
          ],
        ),
      ),
      onTap: () async {
        String? picked = await showModalBottomSheet<String>(
            context: context,
            builder: (BuildContext context) {
              List<String> items = comm.colorItemsOf(widget.detail.cargo);
              return buildWheelPicker(context, items);
            });
        if (picked != null) {
          setState(() {
            widget.detail.colorType = picked;
          });
        }
      },
    );
    final colorRead = Text('颜色：${widget.detail.colorType}');

    //sizer
    final sizerEdit = GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(0.0),
        decoration: const BoxDecoration(), //for capture gesture
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '尺码',
              textScaleFactor: 0.85,
              style: TextStyle(color: primaryColor),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(widget.detail.sizerType),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    child: Icon(Icons.keyboard_arrow_down, color: primaryColor),
                    alignment: Alignment.centerRight,
                  ),
                ),
              ],
            ),
            Container(height: 1, color: Colors.grey),
          ],
        ),
      ),
      onTap: () async {
        String? picked = await showModalBottomSheet<String>(
            context: context,
            builder: (BuildContext context) {
              List<String> items = comm.sizerItemsOf(widget.detail.cargo);
              return buildWheelPicker(context, items);
            });
        if (picked != null) {
          setState(() {
            widget.detail.sizerType = picked;
          });
        }
      },
    );
    final sizerRead = Text('尺码：${widget.detail.sizerType}');

    //qty
    final qtyEdit = TextFormField(
      initialValue: widget.detail.qty.toStringAsFixed(comm.qtyDots),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.left,
      readOnly: true,
      decoration: InputDecoration(
        labelText: '数量',
        labelStyle: TextStyle(color: primaryColor),
        suffixIcon: Transform.translate(
          offset: const Offset(12, 9),
          child: Icon(Icons.keyboard, color: primaryColor),
        ),
        isDense: true,
      ),
      onTap: () async {
        double? val = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ValueEditDialog(
              title: '输入数量',
              initValue: widget.detail.qty,
              dots: comm.qtyDots,
            ),
          ),
        );
        if (val != null) {
          widget.detail.qty = val;
          widget.onChanged();
        }
      },
    );
    final qtyRead =
        Text('数量：${widget.detail.qty.toStringAsFixed(comm.qtyDots)}');

    //price
    final priceEdit = TextFormField(
      initialValue: widget.detail.actPrice.toStringAsFixed(comm.priceDots),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.left,
      readOnly: true,
      decoration: InputDecoration(
        labelText: '单价',
        labelStyle: TextStyle(color: primaryColor),
        suffixIcon: Transform.translate(
          offset: const Offset(12, 9),
          child: Icon(Icons.keyboard, color: primaryColor),
        ),
        isDense: true,
      ),
      onTap: () async {
        double? val = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ValueEditDialog(
              title: '输入单价',
              initValue: widget.detail.actPrice,
              dots: comm.priceDots,
            ),
          ),
        );
        if (val != null ) {
          widget.detail.actPrice = val;
          widget.onChanged();
        }
      },
    );
    final priceRead =
        Text('单价：${widget.detail.actPrice.toStringAsFixed(comm.priceDots)}');

    //discount
    final discountEdit = Text(
      '折扣：${(100.0 * widget.detail.actPrice / widget.detail.cargo.setprice).toStringAsFixed(comm.disDots - 2)}%',
      style: const TextStyle(color: Colors.grey),
      textScaleFactor: 0.85,
    );
    final discountRead = Text(
        '折扣：${(100.0 * widget.detail.actPrice / widget.detail.cargo.setprice).toStringAsFixed(comm.disDots - 2)}%');

    //money
    final moneyEdit = Text(
      '金额：￥${(widget.detail.actPrice * widget.detail.qty).toStringAsFixed(comm.moneyDots)}',
      style: const TextStyle(color: Colors.grey),
      textScaleFactor: 0.85,
    );
    final moneyRead = Text(
        '金额：${(widget.detail.actPrice * widget.detail.qty).toStringAsFixed(comm.moneyDots)}');

    //deleteButton
    final deleteButton = GestureDetector(
      child: Container(
        margin: const EdgeInsets.all(9),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(width: 2, color: Colors.grey)),
        child: const Icon(Icons.clear, color: Colors.grey),
      ),
      onTap: () => widget.onRemoved(),
    );

    //总构建
    return Card(
      elevation: (widget.readOnly) ? 0 : 3,
      color: (widget.readOnly) ? Colors.transparent : const Color(0xffeeeeee),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 18),
      child: Stack(
        children: <Widget>[
          IntrinsicHeight(
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 0,
                  child: Container(
                    width: 100,
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        imageField,
                        setPriceField,
                        const SizedBox(height: 1),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(
                        left: 12, top: 18, right: 12, bottom: 18),
                    child: Column(
                      children: <Widget>[
                        hpcodeField,
                        hpnameField,
                        const SizedBox(
                          height: 6.0,
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: (widget.readOnly) ? colorRead : colorEdit,
                            ),
                            const SizedBox(width: 36),
                            Expanded(
                              flex: 1,
                              child: (widget.readOnly) ? sizerRead : sizerEdit,
                            ),
                          ],
                        ),
                        Form(
                          //必须加此key，不然调用处删除一项底层数据时，会找错对应Widget
                          key: Key(
                              '__cargo${DateTime.now().microsecondsSinceEpoch}__'), //必须
                          autovalidateMode: AutovalidateMode.always,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 1,
                                child: (widget.readOnly) ? qtyRead : qtyEdit,
                              ),
                              const SizedBox(width: 36),
                              Expanded(
                                flex: 1,
                                child:
                                    (widget.readOnly) ? priceRead : priceEdit,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          //mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: (widget.readOnly)
                                  ? discountRead
                                  : discountEdit,
                            ),
                            const SizedBox(width: 36),
                            Expanded(
                              flex: 1,
                              child: (widget.readOnly) ? moneyRead : moneyEdit,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: (widget.readOnly) ? Container() : deleteButton,
          ),
        ],
      ),
    );
  }
}
