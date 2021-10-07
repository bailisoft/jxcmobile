import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:convert/convert.dart';
import 'package:archive/archive.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart' as crypto;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/share/pinyin.dart';
import 'package:jxcmobile/share/toasts.dart';
import 'package:jxcmobile/model/chat.dart';

/// 核心基础类
class Comm with ChangeNotifier {
  static const String _addressHost = 'www.bailisoft.com';
  static const String _addressPath = '/cmd/mids';
  static const int _majorVersion = 1;
  static const int _minorVersion = 0;
  static const int _buildVersion = 0;

  final int _lastMajorVersion = 1;
  final int _lastMinorVersion = 0;
  final int _lastBuildVersion = 0;

  String _backerName = '';
  String _fronterName = '';
  String _passCode = '';
  String _cryptCode = '';
  bool _fronterIsBoss = false;

  String _backerHashHex = '';
  String _fronterHashHex = '';
  Uint8List _cryptKey = Uint8List(0);

  String _midHost = '';
  int _tcpPort = 0;
  int _webPort = 0;
  Socket? _rawSocket;
  WebSocketChannel? _webSocket;
  List<int> _buffer = [];
  int _tcpPackLen = 0;
  Uint8List _earliestLostMsg = Uint8List(0);
  Timer? _beator;

  bool _loginCached = false;
  bool _onlining = false;
  String _bossAccount = '';
  LoginedWay _loginedWay = LoginedWay.linkSetting;
  AppStatus _netStatus = AppStatus.guide;

  /// 状态临时标识值
  String _netErrorMsg = '';
  List<String> _currentRequest = [];
  List<String> _currentResponse = [];

  /// 登录后账册相关值
  String _comName = '百利公司';
  String _comLogo = '';
  String _comColor = '00ff00';
  int _qtyDots = 0;
  int _priceDots = 1;
  int _moneyDots = 2;
  int _disDots = 3;
  List<BarcodeRule> _barcodeRules = [];
  List<SizerType> _sizerTypes = [];
  List<ColorType> _colorTypes = [];
  List<Cargo> _cargos = [];
  List<Shop> _shops = [];
  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];
  List<Staff> _staffs = [];
  List<Policy> _policies = [];
  List<Fee> _fees = [];
  List<Conversation> _talks = [];
  BSubTypes _bsubTypes = BSubTypes();
  String _bindShop = '';
  String _bindTrader = '';
  String _loginMobile = '';
  bool _canRet = false;
  bool _canLot = false;
  bool _canBuy = false;
  final Map<String, int> _rightMap = <String, int>{};

  /// 打印相关，直接暴露
  BluetoothDevice? currentPrinterDevice;
  BluetoothPrint appPrinter = BluetoothPrint.instance;
  PrinterState printerState = PrinterState.psDisconnected;
  String printAttachText = '';
  int printCopies = 1;

  /// 公开属性
  String get backerName => _backerName;
  String get fronterName => _fronterName;
  String get fronterHashHex => _fronterHashHex;
  bool get fronterIsBoss => _fronterIsBoss;

  AppStatus get netStatus => _netStatus;
  String get netErrorMsg => _netErrorMsg;

  List<String> get currentRequest => _currentRequest;
  List<String> get currentResponse => _currentResponse;

  String get comName => _comName;
  String get comLogo => _comLogo;
  String get comColor => _comColor;
  int get qtyDots => _qtyDots;
  int get priceDots => _priceDots;
  int get moneyDots => _moneyDots;
  int get disDots => _disDots;
  List<Cargo> get cargos => _cargos;
  List<Shop> get shops => _shops;
  List<Customer> get customers => _customers;
  List<Supplier> get suppliers => _suppliers;
  List<Staff> get staffs => _staffs;
  List<Policy> get policies => _policies;
  List<Fee> get fees => _fees;
  List<Conversation> get talks => _talks;
  BSubTypes get bsubTypes => _bsubTypes;

  String get bindShop => _bindShop;
  String get bindTrader => _bindTrader;
  String get loginMobile => _loginMobile;
  bool get canRet => _canRet;
  bool get canLot => _canLot;
  bool get canBuy => _canBuy;
  String get bossAccount => _bossAccount;

  /// 构造函数
  Comm() {
    //网页端不检查打印机
    if ( !kIsWeb) {
      appPrinter.state.listen((state) {
        switch (state) {
          case BluetoothPrint.CONNECTED:
            printerState = PrinterState.psConnected;
            break;
          case BluetoothPrint.DISCONNECTED:
            printerState = PrinterState.psDisconnected;
            break;
          default:
            printerState = PrinterState.psError;
            break;
        }
        notifyListeners();
      });
    }
  }

  bool needUpgrade() {
    if (_lastMajorVersion > _majorVersion) {
      return true;
    }
    if (_lastMinorVersion > _minorVersion) {
      return true;
    }
    if (_lastBuildVersion > _buildVersion) {
      return true;
    }
    return false;
  }

  String getVersionUrl() {
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        return 'https://www.bailisoft.com/d/jxcapk.html';
      } else if (Platform.isIOS) {
        return 'https://www.bailisoft.com/d/jxcipa.html';
      }
    }
    return 'https://www.bailisoft.com';
  }

  /// Hive表功能包装
  Future<void> tableOpenAll() async {
    await Hive.openBox('$_backerName$billHiveTable');
    await Hive.openBox('$_backerName$noteHiveTable');
    await Hive.openBox('$_backerName$queryHiveTable');
    await Hive.openBox('$_backerName$favoriteHiveTable');
    await Hive.openBox('$_backerName$chatHiveTable');
    await Hive.openBox('$_backerName$settingHiveTable');
    await Hive.openBox('$_backerName$imageHiveTable');
  }

  Future<void> tableOpen(String tableName) async {
    String boxName =
        (backerHiveTable == tableName) ? tableName : '$_backerName$tableName';
    await Hive.openBox(boxName);
  }

  Box tableOf(String tableName) {
    String boxName =
        (backerHiveTable == tableName) ? tableName : '$_backerName$tableName';
    return Hive.box(boxName);
  }

  int tableLength(String tableName) {
    String boxName =
        (backerHiveTable == tableName) ? tableName : '$_backerName$tableName';
    Box box = Hive.box(boxName);
    return box.length;
  }

  String? tableValueOf(String tableName, String key) {
    String boxName =
        (backerHiveTable == tableName) ? tableName : '$_backerName$tableName';
    Box box = Hive.box(boxName);
    return box.get(key);
  }

  String tableValueAt(String tableName, int index) {
    String boxName =
        (backerHiveTable == tableName) ? tableName : '$_backerName$tableName';
    Box box = Hive.box(boxName);
    return box.getAt(index);
  }

  String tableKeyAt(String tableName, int index) {
    String boxName =
        (backerHiveTable == tableName) ? tableName : '$_backerName$tableName';
    Box box = Hive.box(boxName);
    return box.keyAt(index);
  }

  Future<void> tableSave(String tableName, String key, String data,
      {notify = false}) async {
    String boxName =
        (backerHiveTable == tableName) ? tableName : '$_backerName$tableName';
    Box box = Hive.box(boxName);
    await box.put(key, data);
    if (notify) notifyListeners();
  }

  Future<void> tableDeleteAt(String tableName, int index,
      {notify = false}) async {
    String boxName =
        (backerHiveTable == tableName) ? tableName : '$_backerName$tableName';
    Box box = Hive.box(boxName);
    await box.deleteAt(index);
    if (notify) notifyListeners();
  }

  Future<void> tableDeleteOf(String tableName, String key,
      {notify = false}) async {
    String boxName =
        (backerHiveTable == tableName) ? tableName : '$_backerName$tableName';
    Box box = Hive.box(boxName);
    await box.delete(key);
    if (notify) notifyListeners();
  }

  Future<void> clearLoginerHiveData() async {
    Box boxBill = await Hive.openBox('$_backerName$billHiveTable');
    boxBill.clear();

    Box boxNote = await Hive.openBox('$_backerName$noteHiveTable');
    boxNote.clear();

    Box boxQuery = await Hive.openBox('$_backerName$queryHiveTable');
    boxQuery.clear();

    Box boxFavorite = await Hive.openBox('$_backerName$favoriteHiveTable');
    boxFavorite.clear();

    Box boxChat = await Hive.openBox('$_backerName$chatHiveTable');
    boxChat.clear();
  }

  /// 网络参数设置
  void setLoginSettings(String bk, String fr, String pcode, String kcode,
      String name, String logo) {
    _backerName = bk;
    _fronterName = fr;
    _passCode = pcode;
    _cryptCode = kcode;
    _comName = name;
    _comLogo = logo;
  }

  /// 取权限
  bool canOpen(String winqryname) {
    //selfasBoss的_rightMap为空，故需要先判断
    if (_fronterIsBoss) {
      return true;
    }
    //temp_pass为特殊标记，不在_rightMap内，也需要先判断
    if (winqryname == 'temp_pass') {
      return true;
    }
    //非法键————其实只是起测试作用，正确代码不应会有
    if (!_rightMap.containsKey(winqryname)) {
      return false;
    }
    //见后台bailiwins.h与bailicodes.cpp文件中权限标志定义
    int rightFlagValue = _rightMap[winqryname] ?? -1;
    return (winqryname.startsWith("vi"))
        ? (rightFlagValue > 0)
        : (rightFlagValue > 1);
  }

  /// 搜索匹配货号
  List<Cargo> searchCargos(String terms) {
    return _cargos
        .where((v) =>
            v.hpcode.toUpperCase().contains(terms.toUpperCase()) ||
            v.hpname.toUpperCase().contains(terms.toUpperCase()) ||
            v.pinyincode.toUpperCase().contains(terms.toUpperCase()))
        .toList();
  }

  /// 取得颜色表
  List<String> colorItemsOf(Cargo cargo) {
    ColorType? found =
        _colorTypes.firstWhereOrNull((t) => t.tname == cargo.colortype);
    return (found?.namelist) ?? cargo.colortype.split(',');
  }

  /// 取得尺码表
  List<String> sizerItemsOf(Cargo cargo) {
    SizerType? found =
        _sizerTypes.firstWhereOrNull((t) => t.tname == cargo.sizertype);
    return (found?.namelist) ?? [];
  }

  /// 格式化值
  String formatValue(String field, String value) {
    if (field.contains('shop') ||
        field.contains('cargo') ||
        field.contains('color') ||
        field.contains('sizer')) {
      return value;
    }
    double v = (int.tryParse(value) ?? 0) / 10000;
    int dots = _qtyDots;
    if (field.contains('mny') ||
        field.contains('money') ||
        field.contains('apy') ||
        field.contains('owe')) dots = _moneyDots;
    if (field.contains('dis')) dots = _disDots;
    if (field.contains('price')) dots = _priceDots;
    return v.toStringAsFixed(dots);
  }

  /// 删除后台连接信息
  void deleteLink(String backerName) {
    Hive.box(backerHiveTable).delete(backerName);
    notifyListeners();
  }

  /// 加载账册本地设置参数
  Future<void> loadBookLocalSettings() async {
    Box box = Hive.box('$_backerName$settingHiveTable');
    for (int i = 0, iLen = box.length; i < iLen; ++i) {
      String k = box.keyAt(i);
      String v = box.getAt(i);
      if (k == 'printAttachText') {
        printAttachText = v;
      }
      if (k == 'printCopies') {
        printCopies = int.tryParse(v) ?? 1;
      }
      //更多其他在此添加...
    }
  }

  /// 保存账册本地设置参数
  Future<void> saveBookLocalSettings(Map<String, String> settings) async {
    Box box = Hive.box('$_backerName$settingHiveTable');
    box.putAll(settings);
  }

  /// 重置网络应答缓存
  void clearResponse() {
    _currentResponse = [];
  }

  /// 连接网络并自动登录
  Future<void> connectLogin(BuildContext context, LoginedWay loginWay) async {
    if (_backerName.isEmpty || _fronterName.isEmpty || _passCode.isEmpty) {
      _netStatus = AppStatus.login;
      notifyListeners();
      return;
    }

    //其他异步过程使用
    _loginedWay = loginWay;

    //手动调用
    if (loginWay == LoginedWay.homeRefresh) {
      Waiting.show(context);
    } else {
      _netStatus = AppStatus.splash;
      notifyListeners();
    }

    //关闭现连接
    if (!kIsWeb && _rawSocket != null) {
      await _rawSocket!.close();
      _rawSocket = null;
    }
    if (kIsWeb && _webSocket != null) {
      await _webSocket!.sink.close();
      _webSocket = null;
    }

    //清空识别标记
    _onlining = false;
    _netErrorMsg = '';
    _currentRequest = [];
    if (loginWay == LoginedWay.linkSetting) {
      await clearLoginerHiveData();
    }

    //取得公服地址等
    if (_midHost.isEmpty ||
        _tcpPort < 1024 ||
        _webPort < 1024 ||
        loginWay == LoginedWay.bookList ||
        loginWay == LoginedWay.linkSetting) {

      String responseText = '';
      try {
        var resp = await http.get(
            Uri.https(_addressHost, _addressPath, {'backer': _backerName}),
            headers: {
              "Accept": "text/plain",
              "Access-Control_Allow_Origin": "*"
            });
        if (resp.statusCode == 200) {
          responseText = resp.body;
        }
      } catch (e) {
        debugPrint('http get address failed: ${e.toString()}');
      }

      //地址信息格式协议
      if (responseText.isNotEmpty) {
        var infoFields = responseText.split('\t');
        if (infoFields.isNotEmpty) {
          var addrFields = infoFields[0].split(':');
          if (addrFields.length == 3) {
            _midHost = addrFields[0];
            _tcpPort = int.tryParse(addrFields[1]) ?? 19201;
            _webPort = int.tryParse(addrFields[2]) ?? 19202;
            notifyListeners();
            debugPrint('parsed midserver host:$_midHost, '
                'tcpPort:$_tcpPort, webPort:$_webPort from '
                '$_addressHost$_addressPath');
          }
        }
      } else {
        _rawSocket = null;
        _netErrorMsg = '没有网络';
        _currentResponse = [];
        notifyListeners();
      }
    }

    //因初始化方式原因，dart2js不支持clear()
    _earliestLostMsg = Uint8List(0);

    //计算联网变量
    _backerHashHex = shortMd5Hex(_backerName);
    _fronterHashHex = shortMd5Hex(_fronterName);
    _cryptKey = (_cryptCode.isNotEmpty)
        ? Uint8List.fromList(crypto.md5.convert(_cryptCode.codeUnits).bytes)
        : Uint8List(0); //isNotEmpty是否加解密处判断依据

    //构造联网包准备字段
    int timeStamp = DateTime.now().millisecondsSinceEpoch;
    String rands = _generateRandomString(64);
    String verify = '$_fronterHashHex$_backerHashHex${timeStamp.toString()}'
        '$_passCode$rands';
    Uint8List verifyBytes = const Utf8Encoder().convert(verify);
    var digest = crypto.sha256.convert(verifyBytes);
    String vhash = hex.encode(digest.bytes);

    //WEB
    if (kIsWeb) {
      //准备timestamp大整数
      int hi = timeStamp ~/ 0x100000000;
      int lo = timeStamp & 0xffffffff;
      Uint8List timBytes = Uint8List(8);
      ByteData timeView = ByteData.view(timBytes.buffer);
      timeView.setInt32(0, hi, Endian.big);
      timeView.setInt32(4, lo, Endian.big);

      //协议【selfId(16)backerId(16)epoch(8)randomBytes(64)vhash(64)】
      List<int> data = [];
      data.addAll(_fronterHashHex.codeUnits);
      data.addAll(_backerHashHex.codeUnits);
      data.addAll(timBytes);
      data.addAll(rands.codeUnits);
      data.addAll(vhash.codeUnits);

      //连接并监听
      String uri = 'wss://$_midHost:$_webPort/webjxc?front=$_fronterHashHex'
          '&backer=$_backerHashHex&token=${base64UrlEncode(data)}';
      //debugPrint('wss url: $uri');
      _webSocket = WebSocketChannel.connect(Uri.parse(uri));
      _webSocket?.stream.listen((data) {
        _dealWebData(data);
      }, onError: _dealWebError, onDone: _dealWebDone, cancelOnError: true);
    }
    //Android | IOS
    else {
      //协议【selfId(16)backerId(16)epoch(8)randomBytes(64)vhash(64)】
      String text =
          _fronterHashHex + _backerHashHex + '12345678' + rands + vhash;

      //嵌入timestamp大整数
      Uint8List reqData = Uint8List.fromList(text.codeUnits);
      ByteData byteView = ByteData.view(reqData.buffer);
      byteView.setInt64(32, timeStamp, Endian.big);

      //连接
      try {
        _rawSocket = await Socket.connect(_midHost, _tcpPort);
      } catch (e) {
        debugPrint('connectLogin to $_midHost:$_tcpPort err: $e');
        _rawSocket = null;
        _netErrorMsg = '联网失败';
        _currentResponse = [];
        notifyListeners();
        return;
      }

      //监听 ———— 同时设置onError监听，以获取及时掉线通知
      _rawSocket?.listen(_dealTcpData,
          onError: _dealTcpError, onDone: _dealTcpDone, cancelOnError: true);

      //联网验证————不能等待，连上之后，必须马上写，因为公服golang中设置极短的readDeadline
      _rawSocket?.add(reqData);
    }
  }

  /// 关闭网络
  Future<void> disConnectSocket() async {
    if (_beator != null) {
      _beator?.cancel();
      _beator = null;
    }

    if (kIsWeb) {
      if (_webSocket != null) {
        await _webSocket!.sink.close();
        _webSocket = null;
      }
    } else {
      if (_rawSocket != null) {
        await _rawSocket!.close();
        _rawSocket = null;
      }
    }
  }

  /// 后台请求
  Future<void> workRequest(BuildContext? context, List<String> params) async {
    //在线检查————所有登录调用 context 都为 null，其余都必定有确定 context
    if (context != null) {
      if (_netErrorMsg.isNotEmpty) {
        AppToast.show('登录已掉线！', context);
        return;
      }
      Waiting.show(context);
    }

    //保存请求标识
    _currentRequest = params;

    //数据转换（压缩、加密）
    Uint8List reqData = _upFlowConvert(params.join('\f'));

    //数据头
    if (kIsWeb) {
      _webSocket?.sink.add(reqData);
    } else {
      List<int> bytes = [];
      bytes.addAll([0, 0, 0, 0]);
      bytes.addAll(reqData);
      Uint8List sendPack = Uint8List.fromList(bytes);
      ByteData byteView = ByteData.view(sendPack.buffer);
      byteView.setInt32(0, reqData.length, Endian.big);
      _rawSocket?.add(sendPack);
    }
  }

  /// 群事件（fens根据isRequestNotResponse参数，有request和response两种调用情况）
  void saveMeetingEvent(List<String> fens, bool isRequestNotResponse) {
    if (fens[0] == 'GRPCREATE') {
      _talks.add(Conversation(
        conversationId: fens[2],
        conversationName: fens[3],
        members: fens[4],
        arriving: false,
      ));
    }

    if (fens[0] == 'GRPINVITE') {
      String meetId = fens[2];
      String meetName = fens[3];
      String newMembers = (isRequestNotResponse)
          ? fens[4].trim() + '\t' + fens[5].trim()
          : fens[4].trim();
      Conversation? one = _talks.firstWhereOrNull((m) => m.conversationId == meetId);
      if (one != null) {
        one.conversationName = meetName;
        one.members = newMembers.trim();
      } else {
        _talks.add(Conversation(
          conversationId: meetId,
          conversationName: meetName,
          members: newMembers.trim(),
          arriving: false,
        ));
      }
    }

    if (fens[0] == 'GRPKICKOFF') {
      String meetId = fens[2];
      Conversation? one = _talks.firstWhereOrNull((m) => m.conversationId == meetId);
      if (one != null) {
        if (isRequestNotResponse) {
          List<String> kicks = fens[3].split('\t');
          if (kicks.contains(_fronterName)) {
            _talks.remove(one);
          }
        } else {
          one.members = fens[3];
        }
      }
    }

    if (fens[0] == 'GRPRENAME') {
      String meetId = fens[2];
      String meetName = fens[3];
      Conversation? one = _talks.firstWhereOrNull((m) => m.conversationId == meetId);
      if (one != null) {
        one.conversationName = meetName;
      }
    }

    if (fens[0] == 'GRPDISMISS') {
      String meetId = fens[2];
      Conversation? one = _talks.firstWhereOrNull((m) => m.conversationId == meetId);
      if (one != null) _talks.remove(one);
    }
  }

  /// 连接设置页取消
  void guideSelectBooks() async {
    if (Hive.isBoxOpen('$_backerName$billHiveTable')) {
      Hive.box('$_backerName$billHiveTable').compact();
      Hive.box('$_backerName$billHiveTable').close();
    }
    if (Hive.isBoxOpen('$_backerName$noteHiveTable')) {
      Hive.box('$_backerName$noteHiveTable').compact();
      Hive.box('$_backerName$noteHiveTable').close();
    }
    if (Hive.isBoxOpen('$_backerName$queryHiveTable')) {
      Hive.box('$_backerName$queryHiveTable').compact();
      Hive.box('$_backerName$queryHiveTable').close();
    }
    if (Hive.isBoxOpen('$_backerName$favoriteHiveTable')) {
      Hive.box('$_backerName$favoriteHiveTable').compact();
      Hive.box('$_backerName$favoriteHiveTable').close();
    }
    if (Hive.isBoxOpen('$_backerName$chatHiveTable')) {
      Hive.box('$_backerName$chatHiveTable').compact();
      Hive.box('$_backerName$chatHiveTable').close();
    }
    if (Hive.isBoxOpen('$_backerName$imageHiveTable')) {
      Hive.box('$_backerName$imageHiveTable').compact();
      Hive.box('$_backerName$imageHiveTable').close();
    }
    if (Hive.isBoxOpen('$_backerName$settingHiveTable')) {
      Hive.box('$_backerName$settingHiveTable').compact();
      Hive.box('$_backerName$settingHiveTable').close();
    }

    if (Hive.isBoxOpen(backerHiveTable)) {
      Hive.box(backerHiveTable).compact();
    } else {
      await tableOpen(backerHiveTable);
    }

    _netErrorMsg = '';
    _netStatus = AppStatus.guide;
    notifyListeners();
  }

  /// 连接设置页进入
  void guideCreateBookLink() {
    _netStatus = AppStatus.login;
    notifyListeners();
  }

  /// 压缩、加密
  Uint8List _upFlowConvert(String data) {
    //压缩
    Uint8List header = Uint8List(4);
    var dataBytes = utf8.encode(data);
    var zipData =
        (kIsWeb) ? const ZLibEncoder().encode(dataBytes) : zlib.encode(dataBytes);
    Uint8List deflatedBody = Uint8List.fromList(zipData);
    Uint8List packageBody = Uint8List.fromList(header + deflatedBody);
    ByteData byteView = ByteData.view(packageBody.buffer);
    byteView.setUint32(0, deflatedBody.length, Endian.big);

    //加密
    Uint8List encrypted;
    if (_cryptKey.isEmpty) {
      encrypted = packageBody;
    } else {
      Uint8List iv = Uint8List.fromList(_generateRandomString(16).codeUnits);
      final key = encrypt.Key(_cryptKey);
      final encryptor =
          encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final aes = encryptor.encryptBytes(packageBody, iv: encrypt.IV(iv));
      encrypted = Uint8List.fromList(iv + aes.bytes);
    }

    //返回
    return encrypted;
  }

  /// 解密、解压
  String _downFlowConvert(Uint8List data) {
    if (data.isEmpty) return '';

    //解密
    List<int> decrypted;
    if (_cryptKey.isEmpty || data.length % 16 > 0) {
      decrypted = data;
    } else {
      try {
        Uint8List ivBytes = data.sublist(0, 16);
        Uint8List cipher = data.sublist(16);
        final key = encrypt.Key(_cryptKey);
        final iv = encrypt.IV(ivBytes);
        final encryptor =
            encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
        decrypted = encryptor.decryptBytes(encrypt.Encrypted(cipher), iv: iv);
      } catch (e) {
        return 'ERR\faes';
      }
    }

    //解压
    List<int> inflatedData;
    try {
      //头部4字节长度不要传入参数
      inflatedData = (kIsWeb)
          ? const ZLibDecoder().decodeBytes(decrypted.sublist(4))
          : zlib.decode(decrypted.sublist(4));
    } catch (e) {
      return 'ERR\fzip';
    }

    //返回字符串
    return utf8.decode(inflatedData);
  }

  /// 构造随机字符串
  String _generateRandomString(int len) {
    String alphabet =
        'qwertyuiopasdfghjklzxcvbnm1234567890QWERTYUIOPASDFGHJKLZXCVBNM';
    String left = '';
    int ablen = alphabet.length;
    for (var i = 0; i < len; i++) {
      left = left + alphabet[Random().nextInt(ablen)];
    }
    return left;
  }

  /// 以下为各对象中途重登录
  void _appendBarcodeRules(List<String> lines) {
    Map<String, int> exists = <String, int>{};
    for (int i = 0, iLen = _barcodeRules.length; i < iLen; ++i) {
      exists[_barcodeRules[i].barcodexp] = i;
    }
    for (var line in lines) {
      List<String> cols = line.split('\t');
      BarcodeRule newOne = BarcodeRule(
        barcodexp: cols[0],
        sizermiddlee: int.tryParse(cols[1]) != 0,
      );
      String objkey = cols[0];
      if (exists.containsKey(objkey)) {
        _barcodeRules[exists[objkey] ?? 0] = newOne;
      } else {
        _barcodeRules.add(newOne);
      }
    }
  }

  void _appendSizerTypes(List<String> lines) {
    Map<String, int> exists = <String, int>{};
    for (int i = 0, iLen = _sizerTypes.length; i < iLen; ++i) {
      exists[_sizerTypes[i].tname] = i;
    }
    for (var line in lines) {
      List<String> cols = line.split('\t');
      SizerType newOne = SizerType(
        tname: cols[0],
        namelist: cols[1].split(','),
        codelist: cols[2].split(','),
      );
      String objkey = cols[0];
      if (exists.containsKey(objkey)) {
        _sizerTypes[exists[objkey] ?? 0] = newOne;
      } else {
        _sizerTypes.add(newOne);
      }
    }
  }

  void _appendColorTypes(List<String> lines) {
    Map<String, int> existColorTypes = <String, int>{};
    for (int i = 0, iLen = _colorTypes.length; i < iLen; ++i) {
      existColorTypes[_colorTypes[i].tname] = i;
    }
    for (var line in lines) {
      List<String> cols = line.split('\t');
      ColorType newOne = ColorType(
        tname: cols[0],
        namelist: cols[1].split(','),
        codelist: cols[2].split(','),
      );
      String objkey = cols[0];
      if (existColorTypes.containsKey(objkey)) {
        _colorTypes[existColorTypes[objkey] ?? 0] = newOne;
      } else {
        _colorTypes.add(newOne);
      }
    }
  }

  void _appendCargos(List<String> lines) {
    Map<String, int> exists = <String, int>{};
    for (int i = 0, iLen = _cargos.length; i < iLen; ++i) {
      exists[_cargos[i].hpcode] = i;
    }
    for (var line in lines) {
      List<String> cols = line.split('\t');
      Cargo newOne = Cargo(
        hpcode: cols[0],
        hpname: cols[1],
        sizertype: cols[2],
        colortype: cols[3],
        unit: cols[4],
        setprice: (int.tryParse(cols[5]) ?? 999999999) / 10000,
        buyprice: (int.tryParse(cols[6]) ?? 0) / 10000,
        lotprice: (int.tryParse(cols[7]) ?? 0) / 10000,
        retprice: (int.tryParse(cols[8]) ?? 0) / 10000,
      );
      newOne.pinyincode = pinAcronym(cols[1]);
      String objkey = cols[0];
      if (exists.containsKey(objkey)) {
        _cargos[exists[objkey] ?? 0] = newOne;
      } else {
        _cargos.add(newOne);
      }
    }
  }

  void _appendShops(List<String> lines) {
    Map<String, int> exists = <String, int>{};
    for (int i = 0, iLen = _shops.length; i < iLen; ++i) {
      exists[_shops[i].kname] = i;
    }
    for (var line in lines) {
      List<String> cols = line.split('\t');
      Shop newOne = Shop(
        kname: cols[0],
        regdis: (int.tryParse(cols[1]) ?? 10000) / 10000,
        regman: cols[2],
        regaddr: cols[3],
        regtele: cols[4],
      );
      String objkey = cols[0];
      if (exists.containsKey(objkey)) {
        _shops[exists[objkey] ?? 0] = newOne;
      } else {
        _shops.add(newOne);
      }
    }
  }

  void _appendCustomers(List<String> lines) {
    Map<String, int> exists = <String, int>{};
    for (int i = 0, iLen = _customers.length; i < iLen; ++i) {
      exists[_customers[i].kname] = i;
    }
    for (var line in lines) {
      List<String> cols = line.split('\t');
      Customer newOne = Customer(
        kname: cols[0],
        regdis: (int.tryParse(cols[1]) ?? 10000) / 10000,
        regman: cols[2],
        regaddr: cols[3],
        regtele: cols[4],
      );
      String objkey = cols[0];
      if (exists.containsKey(objkey)) {
        _customers[exists[objkey] ?? 0] = newOne;
      } else {
        _customers.add(newOne);
      }
    }
  }

  void _appendSuppliers(List<String> lines) {
    Map<String, int> exists = <String, int>{};
    for (int i = 0, iLen = _suppliers.length; i < iLen; ++i) {
      exists[_suppliers[i].kname] = i;
    }
    for (var line in lines) {
      List<String> cols = line.split('\t');
      Supplier newOne = Supplier(
        kname: cols[0],
        regdis: (int.tryParse(cols[1]) ?? 10000) / 10000,
        regman: cols[2],
        regaddr: cols[3],
        regtele: cols[4],
      );
      String objkey = cols[0];
      if (exists.containsKey(objkey)) {
        _suppliers[exists[objkey] ?? 0] = newOne;
      } else {
        _suppliers.add(newOne);
      }
    }
  }

  void _appendStaffs(List<String> lines) {
    Map<String, int> exists = <String, int>{};
    for (int i = 0, iLen = _staffs.length; i < iLen; ++i) {
      exists[_staffs[i].kname] = i;
    }
    for (var line in lines) {
      List<String> cols = line.split('\t');
      Staff newOne = Staff(
        kname: cols[0],
      );
      String objkey = cols[0];
      if (exists.containsKey(objkey)) {
        _staffs[exists[objkey] ?? 0] = newOne;
      } else {
        _staffs.add(newOne);
      }
    }
  }

  void _appendNotes(List<String> lines) {
    Map<String, int> exists = <String, int>{};
    for (int i = 0, iLen = _fees.length; i < iLen; ++i) {
      exists[_fees[i].kname] = i;
    }
    for (var line in lines) {
      List<String> cols = line.split('\t');
      Fee newOne = Fee(
        kname: cols[0],
      );
      String objkey = cols[0];
      if (exists.containsKey(objkey)) {
        _fees[exists[objkey] ?? 0] = newOne;
      } else {
        _fees.add(newOne);
      }
    }
  }

  /// 拆解收到消息
  void _saveMessage(List<String> fens, {notify = false}) async {
    if (fens.length < 5) return;

    //取得接受方
    String toMeetingId = (fens[3].length == 16) ? fens[1] : fens[3];
    Conversation? conversation = _talks.firstWhereOrNull((m) => m.conversationId == toMeetingId);
    if (conversation != null) conversation.arriving = true;

    //保存
    Message msg = Message(
      msgid: int.tryParse(fens[0]) ?? 0,
      conversationId: toMeetingId,
      sender: fens[2],
      content: fens[4].replaceAll(RegExp(r'\r'), '\n'),
      status: 2,
    );
    await tableSave(chatHiveTable, msg.msgid.toString(), msg.joinMain(),
        notify: notify);
  }

  /// 【登录成功后数据加载】
  Future<void> _loginLoad(List<String> fens, bool appendMode) async {
    //解析数据（此处fens不包含请求命令与请求时间头二参数）
    for (int i = 0, iLen = fens.length; i < iLen; ++i) {
      List<String> lines = fens[i].split('\n');

      //_barcodeRules ———— no local sqlite
      if (i == 0 && lines.length > 1) {
        if (appendMode) {
          _appendBarcodeRules(lines.sublist(1));
        } else {
          _barcodeRules = BarcodeRule.parseListFrom(lines.sublist(1));
        }
      }

      //_sizerTypes ———— no local sqlite
      if (i == 1 && lines.length > 1) {
        if (appendMode) {
          _appendSizerTypes(lines.sublist(1));
        } else {
          _sizerTypes = SizerType.parseListFrom(lines.sublist(1));
        }
      }

      //_colorTypes ———— no local sqlite
      if (i == 2 && lines.length > 1) {
        if (appendMode) {
          _appendColorTypes(lines.sublist(1));
        } else {
          _colorTypes = ColorType.parseListFrom(lines.sublist(1));
        }
      }

      //_cargos ———— no local sqlite
      if (i == 3 && lines.length > 1) {
        if (appendMode) {
          _appendCargos(lines.sublist(1));
        } else {
          _cargos = Cargo.parseListFrom(lines.sublist(1));
        }
      }

      //_shops ———— no local sqlite
      if (i == 4 && lines.length > 1) {
        if (appendMode) {
          _appendShops(lines.sublist(1));
        } else {
          _shops = Shop.parseListFrom(lines.sublist(1));
        }
      }

      //_customers ———— no local sqlite
      if (i == 5 && lines.length > 1) {
        if (appendMode) {
          _appendCustomers(lines.sublist(1));
        } else {
          _customers = Customer.parseListFrom(lines.sublist(1));
        }
      }

      //_suppliers ———— no local sqlite
      if (i == 6 && lines.length > 1) {
        if (appendMode) {
          _appendSuppliers(lines.sublist(1));
        } else {
          _suppliers = Supplier.parseListFrom(lines.sublist(1));
        }
      }

      //_staffs ———— no local sqlite
      if (i == 7 && lines.length > 1) {
        if (appendMode) {
          _appendStaffs(lines.sublist(1));
        } else {
          _staffs = Staff.parseListFrom(lines.sublist(1));
        }
      }

      //_fees ———— no local sqlite
      if (i == 8 && lines.length > 1) {
        if (appendMode) {
          _appendNotes(lines.sublist(1));
        } else {
          _fees = Fee.parseListFrom(lines.sublist(1));
        }
      }

      //各单据业务分类 ———— no local sqlite
      if (i == 9 && lines.length == 11) {
        _bsubTypes = BSubTypes.fromParams(
          cgdTypes: lines[1].split(','),
          cgjTypes: lines[2].split(','),
          cgtTypes: lines[3].split(','),
          dbdTypes: lines[4].split(','),
          sydTypes: lines[5].split(','),
          pfdTypes: lines[6].split(','),
          pffTypes: lines[7].split(','),
          pftTypes: lines[8].split(','),
          lsdTypes: lines[9].split(','),
          szdTypes: lines[10].split(','),
        );
      }

      //bailiOption ———— no local sqlite
      if (i == 10 && lines.length == 8) {
        //注意，如果有后加，这儿需要也增加
        List<String> cols;
        cols = lines[1].split('\t'); //注意与后台协议列数及顺序
        if (cols.length == 2) _qtyDots = int.tryParse(cols[1]) ?? 0;
        cols = lines[2].split('\t');
        if (cols.length == 2) _priceDots = int.tryParse(cols[1]) ?? 0;
        cols = lines[3].split('\t');
        if (cols.length == 2) _moneyDots = int.tryParse(cols[1]) ?? 0;
        cols = lines[4].split('\t');
        if (cols.length == 2) _disDots = int.tryParse(cols[1]) ?? 2;
        cols = lines[5].split('\t');
        if (cols.length == 2) _comName = cols[1];
        cols = lines[6].split('\t');
        if (cols.length == 2) _comColor = cols[1];
        cols = lines[7].split('\t');
        if (cols.length == 2 && cols[1].length > 100) {
          _comLogo = cols[1];
        }
      }

      //自身权限 ———— no local sqlite
      if (i == 11 ) {
        if ( lines.length > 1 ) {
          List<String> flds = lines[0].split('\t');
          List<String> cols = lines[1].split('\t');
          const int rightFields = 39; //注意与后台协议列数及顺序
          if (flds.length == rightFields && cols.length == rightFields) {
            _bindShop = cols[0];
            _bindTrader = (cols[1].isEmpty) ? cols[2] : cols[1];
            _loginMobile = cols[3];
            _canRet = (int.tryParse(cols[6]) ?? 0) != 0;
            _canLot = (int.tryParse(cols[7]) ?? 0) != 0;
            _canBuy = (int.tryParse(cols[8]) ?? 0) != 0;
            for (int i = 9; i < rightFields; ++i) {
              _rightMap[flds[i]] = int.tryParse(cols[i]) ?? 0;
            }
          }
          _fronterIsBoss = false;
        } else {
          _fronterIsBoss = true;
        }
      }

      //各用户拥有群（真群，非单聊对象伪群） ———— no local sqlite
      if (i == 12) {
        if (lines.length > 1) {
          _talks = Conversation.parseListFrom(lines.sublist(1));
        } else {
          _talks = [];  //必须，否则刷新时重复添加
        }
      }

      //可单聊人（假群meeting）
      if (i == 13) {
        if (_fronterIsBoss) {
          //单聊对象为所有账号
          if (lines.length > 1) {
            lines.sublist(1).forEach((loginer) {
              if ( loginer != _fronterName ) {
                _talks.add(
                  Conversation(
                    conversationId: shortMd5Hex(loginer),
                    conversationName: loginer,
                    members: '',
                  ),
                );
              }
            });
          }
        } else {
          _talks.add(
            //普通账号，总是可以与总经理单聊
            Conversation(
              conversationId: shortMd5Hex(fens[16]),  //提前引用
              conversationName: fens[16],             //提前引用
              members: '',
            ),
          );
        }
      }

      //后台记录离线消息
      if (i == 14) {
        List<String> msgs = lines.sublist(1);
        for (int j = 0, jLen = msgs.length; j < jLen; ++j) {
          _saveMessage(msgs[j].split('\t'));
        }
      }

      //价格政策（迭代增加数据在此以后）
      if (i == 15) {
        _policies = Policy.parseListFrom(lines.sublist(1));
      }

      //总经理账号
      if (i == 16) {
        _bossAccount = fens[i];  //注意 (i == 13) 时已经引用
      }
    }

    //总经理权限
    if (_fronterIsBoss) {
      _bindShop = '';
      _bindTrader = '';
      _canRet = true;
      _canLot = true;
      _canBuy = true;
    }

    //加载本地设置
    if (_loginedWay != LoginedWay.homeRefresh) {
      loadBookLocalSettings();
    }

    //公服转发失败暂存消息
    if (_earliestLostMsg.isNotEmpty) {
      String transData = _downFlowConvert(_earliestLostMsg);
      List<String> params = transData.split('\f');
      //lostMsg为其他前端直转的格式数据（见workRequest），不同于离线数据由Qt后端SQL格式化。
      if ( params.length >= 6 ) {
        _saveMessage(params.sublist(1));
      }
    }

    //心跳机制————由于各类防火墙环境，心跳机制不可少。
    if (_beator == null && !kIsWeb) {
      _beator = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_rawSocket != null) {
          _rawSocket?.add(Uint8List.fromList([0, 0, 0, 0]));
        }
      });
    }

    //保存或更新账册连接参数
    if (_loginedWay != LoginedWay.homeRefresh) {
      List<String> cols = [
        _backerName,
        _fronterName,
        _passCode,
        _cryptCode,
        _comName,
        _comColor,
        _comLogo,
      ];
      tableSave(backerHiveTable, _backerName, cols.join('\x1e'), notify: true);

      //切换页面
      await tableOpen(backerHiveTable);
      _netStatus = AppStatus.guide;
      notifyListeners();
    }
  }

  /// 处理网络数据
  Future<void> _dealReadyData(
      Uint8List readyData, bool isMsg, bool isGroup, bool isWebSocket) async {
    //转换（解密解压）
    String bodyText = _downFlowConvert(readyData.sublist(1));

    //一级分隔拆解
    List<String> fens = bodyText.split('\f');

    //debug
    if (fens.length > 18) {
      debugPrint('fens.sublist(18) should be OK: ${fens.sublist(18)} ');
    }

    //正常无可能，但为保险
    if (fens.length < 3) return;

    //特殊处理————转发消息
    if (isMsg) {
      _saveMessage(fens.sublist(1), notify: true);
    }

    //特殊处理————群事件
    if (isGroup) {
      saveMeetingEvent(fens, true); //此为普通用户收到总经理转发
    }

    //特殊处理————存图
    if (fens[0] == 'GETIMAGE' && fens.length > 3) {
      Cargo? cargo = _cargos.firstWhereOrNull((e) => e.hpcode == fens[2]);
      if (cargo != null) {
        cargo.imagedata = fens[3];
        int limCount = (kIsWeb) ? 100 : 1000;
        if (tableLength(imageHiveTable) > limCount) {
          tableDeleteAt(imageHiveTable, 0);
        }
        await tableSave(imageHiveTable, cargo.hpcode, fens[3]);
      }
    }

    //特殊处理————登录
    if (fens[0] == 'LOGIN') {
      //后台权限等原因拒绝
      if (fens[fens.length - 1] != 'OK') {
        _netErrorMsg = fens[fens.length - 1];
        disConnectSocket();
        Waiting.dismiss();
        notifyListeners();
        return;
      }

      //打开数据库连接
      await tableOpenAll();
      // tableOf(favoriteHiveTable).clear();
      // tableOf(imageHiveTable).clear();

      //登录数据大处理
      await _loginLoad(fens.sublist(2), _loginCached);

      //登录后标志
      _loginCached = true;
      _onlining = true;
      _netErrorMsg = '';
      _netStatus = AppStatus.work;
    }

    //其他情况由请求处自行处理
    _currentResponse = fens;

    //通知
    Waiting.dismiss();
    notifyListeners();
  }

  /// TCP数据监听
  Future<void> _dealTcpData(Uint8List data) async {
    //读掉
    _buffer.addAll(data);
    Uint8List bytes = Uint8List.fromList(_buffer);
    ByteData view = ByteData.view(bytes.buffer);

    //循环（为什么用循环，是理论上有可能多个完整数据）
    while (bytes.length >= _tcpPackLen + 4) {
      //一次完整数据
      Uint8List? readyData;
      _tcpPackLen = view.getUint32(0, Endian.big);
      if (_buffer.length >= _tcpPackLen + 4) {
        readyData = bytes.sublist(4, 4 + _tcpPackLen);
        _buffer = _buffer.sublist(4 + _tcpPackLen);
        bytes = Uint8List.fromList(_buffer);
        view = ByteData.view(bytes.buffer);
        _tcpPackLen = 0;
      }

      //未读完或空数据
      if (readyData == null || readyData.length < 2) {
        continue;
      }

      //暂且仅将头部转为字符串，用于数据类型判断
      int headLen = (readyData.length > 8) ? 8 : readyData.length;
      String header = String.fromCharCodes(readyData.sublist(0, headLen));

      //有登录
      if (!_onlining && header == 'ON') {
        _netErrorMsg = '此号有人已登录';
        notifyListeners();
        return;
      }

      //网络连接成功必须登录
      if (!_onlining && (header.startsWith('OK') || header.startsWith('OK'))) {

        //此缓存不含M或R头标志（见公服代码）
        _earliestLostMsg = data.sublist(2);

        int reqId = DateTime.now().microsecondsSinceEpoch;
        int reqTm = (_loginCached) ? DateTime.now().millisecondsSinceEpoch : 0;
        List<String> params = [
          'LOGIN',
          reqId.toString(),
          reqTm.toString(),
          "mobile"
        ];
        workRequest(null, params);
        Timer(const Duration(seconds: 10), () {
          if (!_onlining) {
            _netErrorMsg = '登录失败！'; //原提示“登录错误”
            notifyListeners();
          }
        });
        continue;
      }

      //统一处理
      await _dealReadyData(
          readyData, header.startsWith('M'), header.startsWith('G'), false);
    }
  }

  /// Web数据监听
  Future<void> _dealWebData(Uint8List data) async {
    //空数据
    if (data.length < 2) {
      return;
    }

    //暂且仅将头部转为字符串，用于数据类型判断
    int headLen = (data.length > 8) ? 8 : data.length;
    String header = String.fromCharCodes(data.sublist(0, headLen));

    //有登录
    if (!_onlining && header == 'ON') {
      _netErrorMsg = '此号有人已登录';
      notifyListeners();
      return;
    }

    //网络连接成功必须登录
    if (!_onlining && (header.startsWith('OK') || header.startsWith('OK'))) {

      //此缓存不含M或R头标志（见公服代码）
      _earliestLostMsg = data.sublist(2);

      //准备
      int reqId = DateTime.now().microsecondsSinceEpoch;
      int reqTm = (_loginCached) ? DateTime.now().millisecondsSinceEpoch : 0;
      List<String> params = [
        'LOGIN',
        reqId.toString(),
        reqTm.toString(),
        "mobile"
      ];

      //发送
      workRequest(null, params);

      //页面等待
      Timer(const Duration(seconds: 10), () {
        if (!_onlining) {
          _netErrorMsg = '登录失败！'; //原提示“登录错误”
          notifyListeners();
        }
      });

      //跳过后面数据处理
      return;
    }

    //统一处理
    await _dealReadyData(
        data, header.startsWith('M'), header.startsWith('G'), true);
  }

  /// TCP错误监听
  void _dealTcpError(error) {
    final String errText = error.toString();
    debugPrint('tcpError:$errText');

    Waiting.dismiss();
    if (_onlining) {
      _netErrorMsg = '掉线';
    } else {
      _netErrorMsg =
          (errText.contains('reset by peer')) ? '连接设置无效' : '后台故障';
    }
    _currentResponse = [];
    notifyListeners();

    if (_beator != null) {
      _beator?.cancel();
      _beator = null;
    }

    _rawSocket?.close();
    _rawSocket = null;
  }

  /// Web错误监听
  void _dealWebError(error) {
    final String errText = error.toString();
    //print('webError:$errText');

    Waiting.dismiss();
    if (_onlining) {
      _netErrorMsg = '掉线';
    } else {
      _netErrorMsg =
          (errText.contains('reset by peer')) ? '连接设置无效' : '后台故障';
    }
    _currentResponse = [];
    notifyListeners();

    if (_beator != null) {
      _beator?.cancel();
      _beator = null;
    }

    _webSocket?.sink.close();
    _webSocket = null;
  }

  /// TCP结束监听
  void _dealTcpDone() {
    if (_rawSocket != null) {
      _rawSocket?.close();
      _rawSocket = null;
    }
  }

  /// Web结束监听
  void _dealWebDone() {
    if (_webSocket != null) {
      _webSocket?.sink.close();
      _webSocket = null;
    }
  }
}
