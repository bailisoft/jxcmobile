import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/share/comm.dart';

/// 文字提示
class AppToast {
  static void show(String msg, BuildContext context, {bool colored = false}) {
    _Toaster.dismiss();
    _Toaster.createView(msg, context, colored);
  }
}
class _Toaster {
  static final _Toaster _singleton = _Toaster._internal();
  _Toaster._internal();
  factory _Toaster() {
    return _singleton;
  }

  static OverlayState? _overlayState;
  static OverlayEntry? _overlayEntry;
  static bool _showing = false;

  static dismiss() {
    if (_showing) {
      _showing = false;
      _overlayEntry?.remove();
    }
  }

  static void createView(String msg, BuildContext ctx, bool colored) async {

    _overlayState = Overlay.of(ctx);

    _overlayEntry = OverlayEntry(builder: (BuildContext context) {
      return Positioned(
          top: MediaQuery.of(context).size.height / 3.0,
          child: Material(
              color: Colors.transparent,
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.topCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colored ? Colors.red : const Color(0xFF888888),
                      border: Border.all(
                          color: colored ? Colors.red : const Color(0xFF888888),
                          width: 3),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                    child: Text(
                      msg,
                      softWrap: true,
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  )
              )
          )
      );
    });

    _showing = true;
    _overlayState?.insert(_overlayEntry!);
    var stays = msg.length > 7 ? 2 : 1;
    await Future.delayed(Duration(seconds: stays));
    dismiss();
  }
}

/// 进度等待图
class Waiting {
  static void show(BuildContext context) {
    _Waiting.dismiss();
    _Waiting.createView(context);
  }
  static void dismiss() {
    _Waiting.dismiss();
  }
//  static bool
}
class _Waiting {
  static final _Waiting _singleton = _Waiting._internal();
  _Waiting._internal();
  factory _Waiting() {
    return _singleton;
  }

  static OverlayState? _overlayState;
  static OverlayEntry? _overlayEntry;
  static bool _showing = false;

  static void dismiss() {
    if (_showing) {
      _showing = false;
      _overlayEntry?.remove();
    }
  }

  static void createView(BuildContext ctx) async {

    _overlayState = Overlay.of(ctx);

    _overlayEntry = OverlayEntry(builder: (BuildContext context) {
      return Positioned(
          top: 0.0,
          child: Material(
              color: const Color.fromARGB(150, 0, 0, 0),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              )
          )
      );
    });

    _showing = true;
    _overlayState?.insert(_overlayEntry!);
  }
}

/// 通用提示对话框
showConfirmDialog(
    BuildContext context, {
      required String title,
      required String msg,
      required String yesButtonCaption,
      required String noButtonCaption,
      required VoidCallback yesCallBack,
    }) {
  // set up the buttons
  Widget cancelButton = TextButton(
    child: Text(noButtonCaption),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  Widget continueButton = TextButton(
    child: Text(yesButtonCaption),
    onPressed: () {
      Navigator.of(context).pop();
      yesCallBack();
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(msg),
    actions: [cancelButton, continueButton],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

/// 底部滚轮选择弹框
Widget buildWheelPicker(BuildContext context, List<String> items) {
  final FixedExtentScrollController scrollController =
      FixedExtentScrollController(initialItem: 0);
  return Container(
    height: 200, //_kPickerSheetHeight,
    color: CupertinoColors.white,
    child: GestureDetector(
      onTap: () {
        String picked = items[scrollController.selectedItem];
        Navigator.pop(context, picked);
      },
      child: CupertinoPicker(
        scrollController: scrollController,
        useMagnifier: true,
        magnification: 1.5,
        itemExtent: 40,
        backgroundColor: CupertinoColors.white,
        onSelectedItemChanged: (int index) {},
        children: List<Widget>.generate(items.length, (int index) {
          return Center(child: Text(items[index], textScaleFactor: 0.8));
        }),
      ),
    ),
  );
}

/// 底部图片
void bottomPopCargoImage(BuildContext context, Cargo cargo,
    {useFavorButton = true}) {
  showModalBottomSheet(
      context: context,
      builder: (context) {
        final comm = Provider.of<Comm>(context, listen: false);
        return SingleChildScrollView(
          child: Column(
            children: <Widget>[
              (useFavorButton)
                  ? Container(
                      color: Theme.of(context).primaryColor,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text(
                            cargo.hpcode,
                            style: const TextStyle(color: Colors.white),
                            textScaleFactor: 2,
                          ),
                          TextButton.icon(
                            icon: Icon(
                              (cargo.favoritee)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                            ),
                            label: Text(
                              (cargo.favoritee) ? '已收藏' : '收藏',
                              style: const TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                              if (!cargo.favoritee) {
                                cargo.favoritee = true;
                                comm.tableSave(favoriteHiveTable, cargo.hpcode, cargo.hpcode);
                              }
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    )
                  : Container(),
              Center(
                child: (cargo.imagedata.isNotEmpty)
                    ? Image.memory(base64Decode(cargo.imagedata))
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 150),
                        child: Text('该货品暂无图片'),
                      ),
              ),
            ],
          ),
        );
      });
}

/// ValueEditDialog
class ValueEditDialog extends StatefulWidget {
  final String title;
  final double initValue;
  final int dots;
  const ValueEditDialog({
    Key? key,
    required this.title,
    required this.initValue,
    required this.dots,
  }) : super(key: key);

  @override
  _ValueEditDialogState createState() => _ValueEditDialogState();
}

/// _ValueEditDialogState
class _ValueEditDialogState extends State<ValueEditDialog> {
  final editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    editController.text =
    (widget.initValue < 0.0001 && widget.initValue > -0.0001)
        ? ''
        : widget.initValue.toStringAsFixed(widget.dots);
  }

  @override
  void dispose() {
    editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(90),
              child: TextField(
                controller: editController,
                autofocus: true,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton.icon(
              //color: Theme.of(context).primaryColor,
              label: const Text('确定', style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: () {
                double? val = double.tryParse(editController.text);
                if (val != null) {
                  Navigator.pop(context, val);
                } else {
                  AppToast.show('无效数字', context);
                }
              },
            ),
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

