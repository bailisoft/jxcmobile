import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/styles.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/model/query.dart';

import 'package:jxcmobile/page/query.dart';

class QueryListItem extends StatelessWidget {
  const QueryListItem({
    Key? key,
    required this.query,
    required this.onOpen,
    required this.onDelete,
  }) : super(key: key);

  final QueryClip query;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final comm = Provider.of<Comm>(context, listen: false);

    final String dateInfo = (query.qtype == 'summ' || query.qtype == 'view')
        ? '${formatFromEpochSeconds(query.dateb)} 至 ${formatFromEpochSeconds(query.datee)}'
        : '截至 ${formatFromEpochSeconds(query.datee)}';

    final List<String> cons = [];
    if (query.shop.isNotEmpty &&
        query.qtype != 'cash' &&
        query.qtype != 'rest' &&
        query.color.isEmpty &&
        query.sizer.isEmpty) cons.add(query.shop);

    if (query.trader.isNotEmpty &&
        query.qtype != 'stock' &&
        query.qtype != 'view') cons.add(query.trader);

    if (query.cargo.isNotEmpty && query.qtype != 'cash') cons.add(query.cargo);
    if (query.color.isNotEmpty && query.qtype == 'stock') cons.add(query.color);
    if (query.sizer.isNotEmpty && query.qtype == 'stock') cons.add(query.sizer);

    if (query.checkk == 1) cons.add('仅审核');
    if (query.checkk == 2) cons.add('仅未审');

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              query.titleName(false),
              style:
                  TextStyle(color: primaryColor, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 6),
            Text(
              dateInfo,
              textScaleFactor: 0.75,
              style: TextStyle(color: primaryColor),
            ),
            GestureDetector(
              child: Icon(
                Icons.search,
                color: primaryColor,
              ),
              onTap: () => onOpen(),
            ),
            Expanded(child: Container()),
            GestureDetector(
              child: Tooltip(
                message: '移除缓存',
                child: Icon(
                  Icons.clear,
                  color: primaryColor,
                ),
              ),
              onTap: () => onDelete(),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            cons.join('，'),
            textScaleFactor: 0.75,
            style: TextStyle(color: primaryColor),
          ),
        ),
        makeReportTitle(query.resfields),
        ...makeReportValueRows(query.resfields, query.resvalues, comm),
      ],
    );
  }
}

class HomeQuery extends StatelessWidget {
  const HomeQuery({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final comm = Provider.of<Comm>(context, listen: true);

    if (comm.tableLength(queryHiveTable) == 0) {
      return const Center(
        child: Text(
          '戳左上角选择查询',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: comm.tableLength(queryHiveTable),
      separatorBuilder: (context, i) => Container(
        height: 1,
        color: Theme.of(context).primaryColor,
      ),
      itemBuilder: (context, i) {
        QueryClip qry =
            QueryClip.parseFrom(comm.tableValueAt(queryHiveTable, i));
        return Padding(
          padding: const EdgeInsets.all(12),
          child: QueryListItem(
            query: qry,
            onOpen: () async {
              await comm.tableOpen(queryHiveTable);
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QueryPage(qry: qry),
                ),
              );
            },
            onDelete: () {
              comm.tableDeleteAt(queryHiveTable, i, notify: true);
            },
          ),
        );
      },
    );
  }
}
