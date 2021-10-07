import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

  return hslLight.toColor();
}

MaterialColor nearestColor(String hexColorName) {
  int r = int.tryParse(hexColorName.substring(0, 2), radix: 16) ?? 0x11;
  int g = int.tryParse(hexColorName.substring(2, 4), radix: 16) ?? 0x99;
  int b = int.tryParse(hexColorName.substring(4, 6), radix: 16) ?? 0x00;
  HSLColor comHsl = HSLColor.fromColor(Color.fromARGB(255, r, g, b));
  MaterialColor selectColor = Colors.primaries[0];
  int minDiff = 360;
  for (int i = 0, iLen = Colors.primaries.length; i < iLen; ++i) {
    HSLColor sysHsl = HSLColor.fromColor(Colors.primaries[i][500] ?? Colors.grey);
    int hueDiff = (sysHsl.hue - comHsl.hue).round();
    if (hueDiff < 0) hueDiff = 0 - hueDiff;
    if (hueDiff < minDiff) {
      selectColor = Colors.primaries[i];
      minDiff = hueDiff;
    }
  }
  return selectColor;
}

String formatFromEpochSeconds(int epochSeconds) {
  DateTime dt = DateTime.fromMillisecondsSinceEpoch(1000 * epochSeconds);
  return DateFormat('yyyy-M-d').format(dt);
}

String formatAsDateTime(DateTime date, {timeDevide = true}) {
  return (timeDevide)
      ? DateFormat('yyyy-M-d - HH:mm').format(date)
      : DateFormat('yyyy-M-d   HH:mm').format(date);
}

//事实上提交时按后台生成时间记录，这里这样处理其实也只是为了提交（或查询）前的界面显示。
int todayEpochSeconds() {
  DateTime n = DateTime.now();
  DateTime today = DateTime(n.year, n.month, n.day, 0, 0, 0, 0, 0);
  return today.millisecondsSinceEpoch ~/ 1000;
}

Image getCargoPlaceholder(double size) {
  return Image.asset('assets/cargo.png', width: size, height: size);
}

/*
codeUnits gets you a List<int>
Uint8List.fromList(...) converts List<int> to Uint8List
String.fromCharCodes(...) converts List<int> or Uint8List to String

class Some extends StatelessWidget {
	const Some({
		Key key,
	}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		return Text('');
	}
}

class Some extends StatefulWidget {
	Some({Key key}) : super(key: key);
	@override
	SomeState createState() => SomeState();
}

class SomeState extends State<Some> {
	@override
	Widget build(BuildContext context) {
		return Text('');
	}
}
*/
