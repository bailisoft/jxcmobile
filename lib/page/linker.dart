import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/share/comm.dart';

class BackerSettingPage extends StatefulWidget {
  const BackerSettingPage({Key? key}) : super(key: key);
  @override
  _BackerSettingPageState createState() => _BackerSettingPageState();
}

class _BackerSettingPageState extends State<BackerSettingPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  FocusNode backerFocus = FocusNode();
  FocusNode fronterFocus = FocusNode();
  FocusNode passCodeFocus = FocusNode();
  FocusNode cryptCodeFocus = FocusNode();
  bool obscurePassCode = true;
  bool obscureCryptCode = true;

  String _backer = '';
  String _fronter = '';
  String _passCode = '';
  String _cryptCode = '';

  void togglePassCode() {
    setState(() {
      obscurePassCode = !obscurePassCode;
    });
  }

  void toggleCryptCode() {
    setState(() {
      obscureCryptCode = !obscureCryptCode;
    });
  }

  void pressOk(context) {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      final comm = Provider.of<Comm>(context, listen: false);
      comm.setLoginSettings(_backer, _fronter, _passCode, _cryptCode, '', '');
      comm.connectLogin(context, LoginedWay.linkSetting);
    }
  }

  void pressCancel() {
    Provider.of<Comm>(context, listen: false).guideSelectBooks();
  }

  @override
  void dispose() {
    backerFocus.dispose();
    fronterFocus.dispose();
    passCodeFocus.dispose();
    cryptCodeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (BuildContext context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 50.0),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 60.0),
              const Text(
                '连接设置',
                textScaleFactor: 3.0,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 10.0),
              Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: '后台名',
                        isDense: true,
                      ),
                      maxLength: 16,
                      focusNode: backerFocus,
                      onFieldSubmitted: (String value) {
                        backerFocus.unfocus();
                        FocusScope.of(context).requestFocus(fronterFocus);
                      },
                      onSaved: (String? value) {
                        _backer = value ?? '';
                      },
                      validator: (v) => ((v ?? '').isEmpty) ? '请填后台名！' : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: '用户名',
                        isDense: true,
                      ),
                      maxLength: 16,
                      focusNode: fronterFocus,
                      onFieldSubmitted: (String value) {
                        fronterFocus.unfocus();
                        FocusScope.of(context).requestFocus(passCodeFocus);
                      },
                      onSaved: (String? value) {
                        _fronter = value ?? '';
                      },
                      validator: (v) => ((v ?? '').isEmpty) ? '请填用户名！' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: '登录码',
                        isDense: true,
                        suffixIcon: GestureDetector(
                          child: Icon(
                            obscurePassCode
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onTap: () => togglePassCode(),
                        ),
                      ),
                      maxLength: 16,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: obscurePassCode,
                      focusNode: passCodeFocus,
                      onFieldSubmitted: (String value) {
                        passCodeFocus.unfocus();
                        FocusScope.of(context).requestFocus(cryptCodeFocus);
                      },
                      onSaved: (String? value) {
                        _passCode = value ?? '';
                      },
                      validator: (v) => ((v ?? '').isEmpty) ? '请填登录码！' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: '保密码（选填）',
                        isDense: true,
                        suffixIcon: GestureDetector(
                          child: Icon(
                            obscureCryptCode
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onTap: () => toggleCryptCode(),
                        ),
                      ),
                      maxLength: 32,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: obscureCryptCode,
                      focusNode: cryptCodeFocus,
                      onFieldSubmitted: (String value) {
                        cryptCodeFocus.unfocus();
                      },
                      onSaved: (String? value) {
                        _cryptCode = value ?? '';
                      },
                    ),
                    Consumer(builder:
                        (BuildContext context, Comm comm, Widget? child) {
                      return Text(
                        comm.netErrorMsg,
                        textScaleFactor: .75,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              SizedBox(
                width: double.infinity,
                height: 50.0,
                child: ElevatedButton(
                  child: const Text('登录'),
                  onPressed: () => pressOk(context),
                ),
              ),
              const SizedBox(height: 10.0),
              TextButton(
                child: const Text('取消'),
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.resolveWith((states) {
                    return Colors.grey[700];
                  }),
                  shape: MaterialStateProperty.all(const StadiumBorder()),
                ),
                onPressed: pressCancel,
              ),
            ],
          ),
        );
      }),
    );
  }
}
