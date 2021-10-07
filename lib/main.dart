import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/share/styles.dart';
import 'package:jxcmobile/page/splash.dart';
import 'package:jxcmobile/page/backer.dart';
import 'package:jxcmobile/page/linker.dart';
import 'package:jxcmobile/page/home.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              true; // add your localhost detection logic here if you want
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  await Hive.initFlutter();
  await Hive.openBox(backerHiveTable);
  runApp(const BailiApp());
}

class BailiApp extends StatelessWidget {
  const BailiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Comm(),
      child: Consumer(builder: (BuildContext ctx, Comm comm, Widget? child) {
        Widget homePage;
        switch (comm.netStatus) {
          case AppStatus.guide:
            homePage = const BackerPage();
            break;
          case AppStatus.splash:
            homePage = const SplashPage();
            break;
          case AppStatus.login:
            homePage = const BackerSettingPage();
            break;
          default:
            homePage = const MyHomePage(title: '百利进销存终端');
        }
        return MaterialApp(
          title: '百利进销存',
          theme: ThemeData(
            primarySwatch: nearestColor(comm.comColor),
          ),
          home: homePage,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale("zh", "CH"),
            Locale("en", "US"),
          ],
          builder: (context, child) {
            child = Scaffold(
                body: GestureDetector(
              onTap: () {
                FocusScopeNode currentFocus = FocusScope.of(context);
                if (!currentFocus.hasPrimaryFocus &&
                    currentFocus.focusedChild != null) {
                  FocusManager.instance.primaryFocus?.unfocus();
                }
              },
              child: child,
            ));
            return child;
          },
        );
      }),
    );
  }
}
