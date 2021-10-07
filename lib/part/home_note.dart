import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/styles.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/model/note.dart';
import 'package:jxcmobile/page/note.dart';

class NoteListItem extends StatelessWidget {
  const NoteListItem({
    Key? key,
    required this.note,
    this.onDelete,
  }) : super(key: key);

  final Note note;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final comm = Provider.of<Comm>(context, listen: false);
    final Color primaryColor = Theme.of(context).primaryColor;
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(note.dated * 1000);
    final String formattedDateTime = formatAsDateTime(dt);
    final String sheetidText = (note.sheetid > 0)
        ? 'SZD-${note.sheetid.toString().padLeft(9, '0')}'
        : '';
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
                        '收支单',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: (note.sheetid > 0) ? primaryColor : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        sheetidText,
                        style: TextStyle(color: primaryColor),
                      ),
                      GestureDetector(
                        child: Icon(
                          Icons.arrow_forward,
                          color: (note.sheetid > 0) ? primaryColor : Colors.red,
                        ),
                        onTap: () async {
                          await comm.tableOpen(noteHiveTable);
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => NotePage(note: note),
                            ),
                          );
                          if ((double.tryParse(note.sumMoney()) ?? 0) > 0.001) {
                            await comm.tableOpen(noteHiveTable);
                            comm.tableSave(noteHiveTable, note.id.toString(),
                                note.joinMain(),
                                notify: true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text(formattedDateTime)),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(flex: 3, child: Text(note.shop)),
                Expanded(flex: 2, child: Text(note.staff)),
                Expanded(
                  flex: 2,
                  child: Text(
                    '￥${note.sumMoney()}',
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            child: Tooltip(
              message: (note.sheetid > 0) ? '已提交' : '删除',
              child: Icon(
                (note.sheetid > 0) ? Icons.check : Icons.clear,
                color: (note.sheetid > 0) ? primaryColor : Colors.red,
              ),
            ),
            onTap: () {
              if (note.sheetid == 0 && onDelete != null) {
                onDelete!();
              }
            },
          ),
        ),
      ],
    );
  }
}

class HomeNote extends StatelessWidget {
  const HomeNote({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final comm = Provider.of<Comm>(context, listen: true);

    if (comm.tableLength(noteHiveTable) == 0) {
      return const Center(
        child: Text(
          '暂无报销收支',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: comm.tableLength(noteHiveTable),
      separatorBuilder: (context, i) => Container(
        height: 1,
        color: Theme.of(context).primaryColor,
      ),
      itemBuilder: (context, i) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: NoteListItem(
            note: Note.parseFrom(comm.tableValueAt(noteHiveTable, i)),
            onDelete: () {
              comm.tableDeleteAt(noteHiveTable, i, notify: true);
            },
          ),
        );
      },
    );
  }
}
