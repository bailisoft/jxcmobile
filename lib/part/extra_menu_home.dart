import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/page/setting_printer.dart';

class ExtraMenuHome extends StatelessWidget {
  const ExtraMenuHome({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final comm = Provider.of<Comm>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final extIcon = (comm.needUpgrade()) ? Icons.new_releases : Icons.settings;
    final extColor = (comm.needUpgrade())
        ? Colors.red[700]
        : Theme.of(context).primaryColorLight;

    return PopupMenuButton<ExtraHomeAction>(
      icon: Icon(extIcon, color: extColor),
      onSelected: (action) async {
        switch (action) {
          case ExtraHomeAction.syncBacker:
            int reqId = DateTime.now().microsecondsSinceEpoch;
            int reqTm = DateTime.now().millisecondsSinceEpoch;
            List<String> params = [
              'LOGIN',
              reqId.toString(),
              reqTm.toString(),
              "mobile"
            ];
            comm.workRequest(context, params);
            break;

          case ExtraHomeAction.setPrinter:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return const SettingPrinter();
              }),
            );
            break;

          case ExtraHomeAction.switchLogin:
            comm.guideSelectBooks();
            break;

          case ExtraHomeAction.goUpgrade:
            if (await canLaunch(comm.getVersionUrl())) {
              await launch(comm.getVersionUrl());
            } else {
              throw 'Could not launch ${comm.getVersionUrl()}';
            }
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        List<PopupMenuItem<ExtraHomeAction>> menuItems =
            <PopupMenuItem<ExtraHomeAction>>[
          PopupMenuItem<ExtraHomeAction>(
            value: ExtraHomeAction.syncBacker,
            child: Row(
              children: <Widget>[
                Icon(Icons.refresh, color: primaryColor),
                const Text('刷新同步'),
              ],
            ),
          ),
          PopupMenuItem<ExtraHomeAction>(
            value: ExtraHomeAction.setPrinter,
            child: Row(
              children: <Widget>[
                Icon(Icons.print, color: primaryColor),
                const Text('设置打印'),
              ],
            ),
          ),
          PopupMenuItem<ExtraHomeAction>(
            value: ExtraHomeAction.switchLogin,
            child: Row(
              children: <Widget>[
                Icon(Icons.dvr, color: primaryColor),
                const Text('切换后台'),
              ],
            ),
          ),
        ];
        if (comm.needUpgrade()) {
          menuItems.insert(
              0,
              PopupMenuItem<ExtraHomeAction>(
                value: ExtraHomeAction.goUpgrade,
                child: Row(
                  children: <Widget>[
                    Icon(extIcon, color: extColor),
                    const Text('前往升级'),
                  ],
                ),
              ));
        }
        return menuItems;
      },
    );
  }
}

enum ExtraHomeAction {
  syncBacker,
  setPrinter,
  switchLogin,
  goUpgrade
}
