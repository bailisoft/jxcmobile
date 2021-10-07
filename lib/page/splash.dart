import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/comm.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key?key}) : super(key: key);
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final shiningIdx = Random().nextInt(3) + 1;
  late final Comm comm;
  late final Image centerLogo;

  @override
  void initState() {
    super.initState();
    comm = Provider.of<Comm>(context, listen: false);

    //LOGO
    centerLogo = (comm.comLogo.length > 100)
        ? Image.memory(
            base64Decode(comm.comLogo),
            width: 48,
            height: 48,
          )
        : Image.asset(
            'assets/splash_effects/baililogo.png',
            width: 48,
            height: 48,
          );
  }

  @override
  Widget build(BuildContext context) {
    final comm = Provider.of<Comm>(context, listen: false);
    return Scaffold(
      body: GestureDetector(
        child: Container(
          decoration: const BoxDecoration(color: Colors.black),
          child: Stack(
            children: [
              Center(
                child: Image.asset(
                  'assets/splash_effects/effect_$shiningIdx.gif',
                  width: 400,
                  height: 400,
                ),
              ),
              Center(
                child: centerLogo,
              ),
              Positioned(
                bottom: 0,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 90,
                  child: Center(
                    child: Text(
                      comm.netErrorMsg,
                      style: const TextStyle(color: Color(0xffff6666)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          if (comm.netErrorMsg.isNotEmpty) {
            comm.guideSelectBooks();
          }
        },
      ),
    );
  }
}
