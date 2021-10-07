import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/share/toasts.dart';
import 'package:jxcmobile/page/search_simple.dart';
import 'package:jxcmobile/model/note.dart';
import 'package:jxcmobile/part/note_detail.dart';

/// NotePage
class NotePage extends StatefulWidget {
  const NotePage({
    Key? key,
    required this.note,
  }) : super(key: key);
  final Note note;
  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  late final Comm comm;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  //必须，只有设有controller，在其他选择弹窗退回时，已填文本值才不会清空。
  final remarkController = TextEditingController();

  Future<void> _selectShop(BuildContext context) async {
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
      widget.note.shop = result ?? '';
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
      widget.note.staff = result ?? '';
    });
  }

  double _sumMoney() {
    double sum = 0.0;
    for (NoteDetail detail in widget.note.detailList) {
      sum += detail.money;
    }
    return sum;
  }

  void netResponsed() {
    if (comm.netErrorMsg.isNotEmpty) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (comm.currentRequest.isNotEmpty &&
        comm.currentRequest[0] == 'FEEINSERT' &&
        comm.currentResponse.isNotEmpty) {
      List<String> resp = comm.currentResponse;
      if (resp[resp.length - 1] != 'OK') {
        comm.clearResponse();
        AppToast.show(((resp.length > 2) ? resp[2] : '提交不成功'), context);
        return;
      }
      widget.note.sheetid = int.tryParse(resp[2]) ?? 0;
      widget.note.dated = int.tryParse(resp[3]) ?? 0;
      comm.tableSave(
          noteHiveTable, widget.note.id.toString(), widget.note.joinMain(),
          notify: true);
      Navigator.pop(context, 'saved');
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
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    if (comm.bindShop.isNotEmpty) widget.note.shop = comm.bindShop;
    final Color primaryColor = Theme.of(context).primaryColor;
    final Note note = widget.note;

    //sheetid
    final sheetidEdit = Text('<新单>', style: TextStyle(color: primaryColor));
    final sheetidRead = Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        'SZD-${note.sheetid.toString().padLeft(9, '0')}',
        style: TextStyle(color: primaryColor),
        textScaleFactor: 1.5,
      ),
    );

    //shop
    final shopEdit = TextFormField(
      key: Key('__fieldShopValue${note.shop}'),
      initialValue: note.shop,
      readOnly: true,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: Business.shopNameOf('szd'),
        labelStyle: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
        suffixIcon: GestureDetector(
          child: Icon((comm.bindShop.isEmpty) ? Icons.search : Icons.lock),
          onTap: (comm.bindShop.isEmpty) ? () => _selectShop(context) : null,
        ),
      ),
    );
    final shopRead = Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text('${Business.shopNameOf('szd')}：',
              style: TextStyle(color: primaryColor)),
        ),
        Expanded(
          flex: 3,
          child: Text(note.shop),
        ),
      ],
    );

    //staff
    final staffEdit = TextFormField(
      key: Key('__fieldStaffValue${note.staff}'),
      initialValue: note.staff,
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
          child: Text(note.staff),
        ),
      ],
    );

    //remark
    final remarkEdit = TextFormField(
        //此处Key内插入bill.remark在添加明细时会渲染出错！只好插入时间。
        key: Key('__remark${DateTime.now().microsecondsSinceEpoch}'),
        controller: remarkController,
        maxLines: 5,
        minLines: 1,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          labelText: '备注',
          labelStyle: TextStyle(
            color: Theme.of(context).primaryColor,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              Future.delayed(const Duration(milliseconds: 50)).then((_) {
                remarkController.clear(); //直接使用Controller.clear()有BUG
                FocusScope.of(context).unfocus();
              });
            },
          ),
        ),
        onChanged: (String value) {
          note.remark = value;
        });

    final remarkRead = Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text('备注：', style: TextStyle(color: primaryColor)),
        ),
        Expanded(
          flex: 3,
          child: Text(note.remark),
        ),
      ],
    );

    //添加明细按钮
    final detailAddButton = ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        elevation: 5.0,
        padding: const EdgeInsets.all(9.0),
      ),
      child: const Tooltip(
        message: '添加明细',
        child: Icon(Icons.add, color: Colors.white),
      ),
      onPressed: () {
        setState(() {
          widget.note.detailList
              .add(NoteDetail(timeKey: DateTime.now().millisecondsSinceEpoch));
        });
      },
    );

    //totalMoney
    final totalMoney = Row(
      children: <Widget>[
        Expanded(
          child: Text(
            '合计',
            textScaleFactor: 1.2,
            style: TextStyle(color: primaryColor),
          ),
        ),
        Expanded(
          child: Align(
            child: Text(
              '${_sumMoney().toStringAsFixed(comm.moneyDots)}元',
              textScaleFactor: 1.2,
              style: TextStyle(color: primaryColor),
            ),
            alignment: Alignment.centerRight,
          ),
        ),
      ],
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
          //网络请求
          List<String> mValues = [
            note.shop,
            note.staff,
            note.remark,
          ];
          List<String> dValues = [];
          for (NoteDetail detail in note.detailList) {
            List<String> cols = [
              detail.timeKey.toString(),
              detail.desc,
              (detail.money * 10000).toStringAsFixed(0)
            ];
            dValues.add(cols.join('\t'));
          }
          int reqId = (DateTime.now()).microsecondsSinceEpoch;
          List<String> params = [
            'FEEINSERT',
            reqId.toString(),
            mValues.join('\t'),
            dValues.join('\n')
          ];
          comm.workRequest(context, params);
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
          note.shop = '';
          note.staff = '';
          note.remark = '';
          note.detailList.clear();
        });
        remarkController.clear();
      },
    );

    //总构建
    return Scaffold(
      appBar: AppBar(
        title: const Text('收支单'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.always,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 6.0),
              (note.sheetid > 0) ? sheetidRead : sheetidEdit,
              (note.sheetid > 0) ? shopRead : shopEdit,
              (note.sheetid > 0) ? staffRead : staffEdit,
              (note.sheetid > 0) ? remarkRead : remarkEdit,
              const SizedBox(height: 18.0),
              for (NoteDetail detail in note.detailList)
                SubjectDetailItem(
                  readOnly: (note.sheetid > 0),
                  detail: detail,
                  onRemoved: () {
                    setState(() {
                      note.detailList.remove(detail);
                    });
                  },
                  onChanged: () {
                    setState(() {
                      //空行执行，不能省略
                    });
                  },
                ),
              const SizedBox(height: 6.0),
              (note.sheetid > 0) ? Container() : detailAddButton,
              const SizedBox(height: 12.0),
              totalMoney,
              const SizedBox(height: 20.0),
              (note.sheetid > 0) ? Container() : formPostButton,
              (note.sheetid > 0) ? Container() : formCancelButton,
            ],
          ),
        ),
      ),
    );
  }
}
