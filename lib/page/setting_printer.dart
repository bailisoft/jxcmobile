import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/share/comm.dart';

class SettingPrinter extends StatefulWidget {
  const SettingPrinter({Key? key}) : super(key: key);
  @override
  _SettingPrinterState createState() => _SettingPrinterState();
}

class _SettingPrinterState extends State<SettingPrinter> {
  List<BluetoothDevice> _devices = [];
  late final Comm comm;

  final TextEditingController printAttachController = TextEditingController();
  final TextEditingController printCopiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    comm = Provider.of<Comm>(context, listen: false);
    BluetoothPrint appPrinter = comm.appPrinter;
    appPrinter.scanResults.listen((devices) {
      _devices = devices;
    });

    printAttachController.text = comm.printAttachText;
    printCopiesController.text = comm.printCopies.toString();
  }

  @override
  void dispose() {
    printAttachController.dispose();
    printCopiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color darkColor = Theme.of(context).primaryColorDark;
    final comm = Provider.of<Comm>(context, listen: false);
    BluetoothPrint appPrinter = comm.appPrinter;
    String printerInfo = comm.currentPrinterDevice?.name ?? '暂无';
    String stateInfo = '就绪';
    if (comm.printerState == PrinterState.psDisconnected) stateInfo = '已断开';
    if (comm.printerState == PrinterState.psError) {
      stateInfo = '连接失败，请重启打印机电源后重启APP再试。';
    }

    void printTest() async {
      Map<String, dynamic> config = {};
      List<LineText> list = [];

      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '百利进销存打印测试OK',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1));
      list.add(LineText(linefeed: 1));

      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '如果你看到这些文字，说明蓝牙打印机连接正常，可以启用打印了！',
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(linefeed: 1));

      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content:
              'If you see these words, the Bluetooth printer is connected properly '
              'and printing can be enabled!',
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(linefeed: 1));

      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'これらの単語が表示された場合は、プリンターが正しく接続され、印刷を有効にできます！',
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(linefeed: 1));

      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '如果你看到這些文字，說明藍牙打印機連接正常，可以啟用打印了！',
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(linefeed: 1));
      list.add(LineText(linefeed: 1));

      await appPrinter.printReceipt(config, list);
    }

    Widget invalidBody() {
      return Center(
        child: Column(
          children: const [
            Text('在线终端不支持外部硬件'),
            Text('如需打印请使用下载安装版'),
          ],
        ),
      );
    }

    Widget validBody() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            '当前打印机',
            textScaleFactor: 0.75,
          ),
          Text(
            printerInfo,
            style: TextStyle(color: darkColor),
          ),
          Text(
            stateInfo,
            textScaleFactor: 0.75,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Center(
            child: StreamBuilder<bool>(
              stream: appPrinter.isScanning,
              initialData: false,
              builder: (c, snapshot) {
                if (snapshot.data != null) {
                  return Column(
                    children: <Widget>[
                      TextButton(
                        child: const Text('停止'),
                        style: TextButton.styleFrom(primary: Colors.red),
                        onPressed: () {
                          appPrinter.stopScan();
                        },
                      ),
                      const Text(
                        '扫描查找中…',
                        textScaleFactor: 0.75,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: <Widget>[
                      TextButton(
                        child: const Text('扫描蓝牙'),
                        onPressed: () {
                          setState(() {
                            _devices = [];
                          });
                          appPrinter.startScan(timeout: const Duration(seconds: 5));
                        },
                      ),
                      Text(
                        '发现蓝牙设备：${_devices.length}',
                        textScaleFactor: 0.75,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            itemCount: _devices.length,
            itemBuilder: (BuildContext context, int index) {
              bool canPrint = (_devices.isNotEmpty &&
                  comm.printerState == PrinterState.psConnected);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 16.0),
                    Column(
                      children: <Widget>[
                        Text(
                          _devices[index].name ?? '',
                          textScaleFactor: 1.0,
                        ),
                        Text(
                          _devices[index].address ?? '',
                          textScaleFactor: 0.5,
                        ),
                      ],
                    ),
                    GestureDetector(
                      child: const Text('连接'),
                      onTap: () async {
                        comm.currentPrinterDevice = _devices[index];
                        await appPrinter.connect(_devices[index]);
                        setState(() {});
                      },
                    ),
                    GestureDetector(
                      child: Text(
                        '测试',
                        style: TextStyle(
                          color: canPrint ? Colors.black : Colors.grey,
                        ),
                      ),
                      onTap: canPrint ? printTest : null,
                    ),
                    Container(),
                  ],
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return const Divider(color: Colors.grey);
            },
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: printAttachController,
            decoration: const InputDecoration(
              labelText: '小票末尾附加信息（最多500字）',
              isDense: true,
            ),
            maxLength: 500,
            maxLines: 5,
          ),
          TextField(
            controller: printCopiesController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '打印份数（几联单）',
              isDense: true,
              counterText: '',
            ),
            maxLength: 1,
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            child: const Text('确定', style: TextStyle(color: Colors.white)),
            onPressed: (_devices.isNotEmpty &&
                    comm.printerState == PrinterState.psConnected)
                ? () async {
                    comm.printAttachText = printAttachController.text;
                    comm.printCopies =
                        int.tryParse(printCopiesController.text) ?? 1;
                    comm.saveBookLocalSettings({
                      'printAttachText': comm.printAttachText,
                      'printCopies': comm.printCopies.toString(),
                    });
                    Navigator.pop(context);
                  }
                : null,
          ),
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置打印'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: (kIsWeb) ? invalidBody() : validBody(),
      ),
    );
  }
}
