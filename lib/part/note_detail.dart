import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/model/note.dart';

class SubjectDetailItem extends StatefulWidget {
  final bool readOnly;
  final NoteDetail detail;
  final VoidCallback onRemoved;
  final VoidCallback onChanged;
  const SubjectDetailItem({
    Key? key,
    required this.readOnly,
    required this.detail,
    required this.onRemoved,
    required this.onChanged,
  })  : super(key: key);

  @override
  _SubjectDetailItemState createState() => _SubjectDetailItemState();
}

class _SubjectDetailItemState extends State<SubjectDetailItem> {
  late final Comm comm;

  @override
  void initState() {
    super.initState();
    comm = Provider.of<Comm>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    //desc
    final descEdit = TextFormField(
      //key: Key('__tmpDesc${DateTime.now().microsecondsSinceEpoch}__'),
      initialValue: widget.detail.desc,
      decoration: InputDecoration(
        labelText: '细项',
        border: InputBorder.none,
        labelStyle: TextStyle(color: Theme.of(context).primaryColor),
        isDense: true,
      ),
      onChanged: (String value) {
        setState(() {
          widget.detail.desc = value;
        });
      },
    );
    final descRead = Text('细项：${widget.detail.desc}');

    //money
    final moneyEdit = TextFormField(
      initialValue: widget.detail.money.toStringAsFixed(comm.moneyDots),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: '金额',
        border: InputBorder.none,
        labelStyle: TextStyle(color: Theme.of(context).primaryColor),
        isDense: true,
      ),
      onChanged: (String value) {
        setState(() {
          widget.detail.money = double.tryParse(value) ?? 0;
          widget.onChanged();
        });
      },
    );
    final moneyRead = Text('金额：${(widget.detail.money).toStringAsFixed(comm.moneyDots)}');

    //deleteButton
    final deleteButton = GestureDetector(
        child: const Icon(Icons.clear, color: Colors.grey),
        onTap: () {
          widget.onRemoved();
        });

    //总构建
    return Card(
      elevation: (widget.readOnly) ? 0 : 3,
      color: (widget.readOnly) ? Colors.transparent : const Color(0xffeeeeee),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.only(top: 0, left: 6, right: 6, bottom: 0),
        child: Form(
          //必须加此key，不然调用处删除一项底层数据时，会找错对应Widget
          key: Key('__subjectDtl${widget.detail.timeKey}_form__'),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 2,
                child: (widget.readOnly) ? descRead : descEdit,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: (widget.readOnly) ? moneyRead : moneyEdit,
              ),
              const SizedBox(width: 6),
              (widget.readOnly) ? Container() : deleteButton,
            ],
          ),
        ),
      ),
    );
  }
}
