import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:jxcmobile/share/styles.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/share/toasts.dart';

class FavoriteItem extends StatelessWidget {
  const FavoriteItem({
    Key? key,
    required this.cargo,
    this.onDelete,
  }) : super(key: key);

  final Cargo cargo;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    const double imgSize = 60;
    final Color primaryColor = Theme.of(context).primaryColor;
    final comm = Provider.of<Comm>(context, listen: false);

    Widget makePrice(String txt) {
      return Text(
        txt,
        textScaleFactor: 0.75,
        style: TextStyle(color: primaryColor),
      );
    }

    final List<Widget> prices = [];
    prices.add(makePrice('定价${cargo.setprice}'));
    if (comm.canBuy) prices.add(makePrice('进货${cargo.buyprice}'));
    if (comm.canLot) prices.add(makePrice('批发${cargo.lotprice}'));
    if (comm.canRet) prices.add(makePrice('零售${cargo.retprice}'));

    return Row(
      children: <Widget>[
        GestureDetector(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: (cargo.imagedata.isNotEmpty)
                ? Image.memory(base64Decode(cargo.imagedata),
                    width: imgSize, height: imgSize)
                : getCargoPlaceholder(imgSize),
          ),
          onTap: () async {
            if (cargo.imagedata.isNotEmpty) {
              bottomPopCargoImage(context, cargo, useFavorButton: false);
            } else {
              //先查本地文件
              String imgData = comm.tableValueOf(imageHiveTable, cargo.hpcode) ?? '';
              if (imgData.isNotEmpty) {
                cargo.imagedata = imgData;
                bottomPopCargoImage(context, cargo, useFavorButton: false);
                return;
              }
              //再网络请求
              int reqId = (DateTime.now()).microsecondsSinceEpoch;
              List<String> params = [
                'GETIMAGE',
                reqId.toString(),
                cargo.hpcode
              ];
              comm.workRequest(context, params);
            }
          },
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      cargo.hpcode,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      cargo.hpname,
                      style: TextStyle(color: primaryColor),
                      textScaleFactor: 0.75,
                    ),
                    Expanded(child: Container()),
                    GestureDetector(
                      child: Tooltip(
                        message: '移出收藏',
                        child: Icon(Icons.clear, color: primaryColor),
                      ),
                      onTap: () {
                        if (onDelete != null) {
                          onDelete!();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: prices,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HomeFavorite extends StatelessWidget {
  const HomeFavorite({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    final comm = Provider.of<Comm>(context, listen: true);
    if (comm.tableLength(favoriteHiveTable) == 0) {
      return const Center(
        child: Text(
          '暂无收藏',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: comm.tableLength(favoriteHiveTable),
      separatorBuilder: (context, i) => Container(
        height: 1,
        color: Theme.of(context).primaryColor,
      ),
      itemBuilder: (context, i) {
        String favHpcode = comm.tableKeyAt(favoriteHiveTable, i);
        Cargo? linkCargo =
            comm.cargos.firstWhereOrNull((e) => e.hpcode == favHpcode);
        return (linkCargo != null)
            ? FavoriteItem(
                cargo: linkCargo,
                onDelete: () {
                  comm.tableDeleteAt(favoriteHiveTable, i, notify: true);
                  comm.tableDeleteOf(imageHiveTable, favHpcode);
                },
              )
            : Container();
      },
    );
  }
}
