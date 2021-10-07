import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/share/styles.dart';
import 'package:jxcmobile/share/toasts.dart';
import 'package:jxcmobile/model/backer.dart';

class BackerPage extends StatelessWidget {
  const BackerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final comm = Provider.of<Comm>(context, listen: true);

    Widget backerItem(String linkData) {

      Backer backer = Backer.parseFrom(linkData);
      return TextButton.icon(
        icon: (backer.comLogo.isEmpty ||
            backer.comLogo.length < 128)
            ? Icon(
          Icons.local_library,
          color: nearestColor(backer.comColor).shade300,
          size: 32.0,
        )
            : Image.memory(
          base64Decode(backer.comLogo),
          width: 32.0,
          height: 32.0,
        ),
        label: Text(
          backer.comName,
          textScaleFactor: 1.2,
          style: TextStyle(color: nearestColor(backer.comColor).shade500),
        ),
        onPressed: () {
          comm.setLoginSettings(
              backer.backerName,
              backer.fronterName,
              backer.passCode,
              backer.cryptCode,
              backer.comName,
              backer.comLogo);
          comm.connectLogin(context, LoginedWay.bookList);
        },
        onLongPress: () {
          showConfirmDialog(context,
              title: '后台删除确认',
              msg: '删除后台账号后，该账号及其密码、缓存数据都将从手机内删除。您确定要删除吗？',
              yesButtonCaption: '确定',
              noButtonCaption: '取消', yesCallBack: () {
                comm.deleteLink(backer.backerName);
              });
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Column(children: const [
            Text('服装企业进销存'),
            Text('上海百利软件提供技术支持', textScaleFactor: 0.6),
          ]),
        ),
      ),
      body: (comm.tableLength(backerHiveTable) > 0)
          ? Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: ListView.builder(
                itemCount: comm.tableLength(backerHiveTable),
                itemBuilder: (context, index) {
                  return backerItem(comm.tableValueAt(backerHiveTable, index));
                }),
          )
          : const Center(
              child: Text(
              '请先添加后台……',
              style: TextStyle(color: Colors.grey),
            )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 180,
        height: 40,
        child: ElevatedButton(
          onPressed: () {
            comm.guideCreateBookLink();
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add),
                Text('添加后台'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
