import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/styles.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/model/bill.dart';
import 'package:jxcmobile/page/bill.dart';

class BillListItem extends StatelessWidget {
  const BillListItem({
    Key? key,
    required this.bill,
    this.onDelete,
  }) : super(key: key);

  final Bill bill;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final comm = Provider.of<Comm>(context, listen: false);
    final Color primaryColor = Theme.of(context).primaryColor;
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(bill.dated * 1000);
    final String formattedDateTime = formatAsDateTime(dt);
    final String sheetidText = (bill.sheetid > 0)
        ? '${bill.tname.toUpperCase()}-${bill.sheetid.toString().padLeft(9, '0')}'
        : '（草稿）';
    return Stack(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Row(
                    children: <Widget>[
                      Text(
                        '${bizNames[bill.tname]}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: (bill.sheetid > 0) ? primaryColor : Colors.red,
                        ),
                      ),
                      SizedBox(width: 2),
                      Text(
                        sheetidText,
                        style: TextStyle(
                          color: (bill.sheetid > 0) ? primaryColor : Colors.red,
                        ),
                      ),
                      GestureDetector(
                        child: Icon(
                          Icons.arrow_forward,
                          color: (bill.sheetid > 0) ? primaryColor : Colors.red,
                        ),
                        onTap: () async {
                          await comm.tableOpen(billHiveTable);
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BillPage(bill: bill),
                            ),
                          );
                          if (bill.sumqty > 0.001) {
                            await comm.tableOpen(billHiveTable);
                            comm.tableSave(billHiveTable, bill.id.toString(),
                                bill.joinMain(),
                                notify: true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text('$formattedDateTime')),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(flex: 3, child: Text('${bill.shop}')),
                Expanded(flex: 2, child: Text('数量: ${bill.sumqty}')),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(flex: 3, child: Text('${bill.trader}')),
                Expanded(flex: 2, child: Text('金额: ${bill.summoney}')),
              ],
            ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            child: Tooltip(
              message: (bill.sheetid > 0) ? '已提交' : '删除',
              child: Icon(
                (bill.sheetid > 0) ? Icons.check : Icons.clear,
                color: (bill.sheetid > 0) ? primaryColor : Colors.red,
              ),
            ),
            onTap: () {
              if (bill.sheetid == 0 && onDelete != null) {
                onDelete!();
              }
            },
          ),
        ),
      ],
    );
  }
}

class HomeBill extends StatelessWidget {
  const HomeBill({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final comm = Provider.of<Comm>(context, listen: true);

    if (comm.tableLength(billHiveTable) == 0) {
      return const Center(
        child: Text(
          '戳左上角选择单据',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: comm.tableLength(billHiveTable),
      separatorBuilder: (context, i) => Container(
        height: 1,
        color: Theme.of(context).primaryColor,
      ),
      itemBuilder: (context, i) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: BillListItem(
            bill: Bill.parseFrom(
                comm.tableValueAt(billHiveTable, i), comm.cargos),
            onDelete: () {
              comm.tableDeleteAt(billHiveTable, i, notify: true);
            },
          ),
        );
      },
    );
  }
}
