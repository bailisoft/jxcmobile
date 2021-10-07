import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:convert/convert.dart' as packconvert;
import 'package:jxcmobile/share/pinyin.dart';

/// 常量
const String backerHiveTable = 'backers';
const String billHiveTable = 'bills';
const String noteHiveTable = 'notes';
const String queryHiveTable = 'querys';
const String favoriteHiveTable = 'favorites'; //k: hpcode, v:hpcode  //注意不是图片数据
const String chatHiveTable = 'chats';
const String settingHiveTable = 'settings';
const String imageHiveTable = 'images';

/// 网络登录请求类型
enum LoginedWay { linkSetting, bookList, homeRefresh }

/// 应用状态
enum AppStatus { guide, splash, login, work } //start->splash

/// 打印机状态
enum PrinterState { psConnected, psDisconnected, psError }

/// 主分页
enum HomeTab { bill, query, favorite, note, meeting }

/// 主分页名
const Map<HomeTab, String> homeTabNames = {
  HomeTab.bill: '开单',
  HomeTab.query: '查询',
  HomeTab.favorite: '收藏',
  HomeTab.note: '报销',
  HomeTab.meeting: '沟通',
};

/// 主分图标
const Map<HomeTab, Icon> homeTabIcons = {
  HomeTab.bill: Icon(Icons.edit),
  HomeTab.query: Icon(Icons.search),
  HomeTab.favorite: Icon(Icons.favorite_border),
  HomeTab.note: Icon(Icons.credit_card),
  HomeTab.meeting: Icon(Icons.people),
  //备选Icons：accessibility info_outline new_releases card_giftcard card_travel business
};

/// 单据类型名
const List<String> bizTypes = [
  'cgd',
  'cgj',
  'cgt',
  'dbd',
  'syd',
  'pfd',
  'pff',
  'pft',
  'lsd'
];
const Map<String, String> bizNames = {
  'cgd': '采购订货单',
  'cgj': '采购进货单',
  'cgt': '采购退货单',
  'dbd': '调拨单',
  'syd': '损益单',
  'pfd': '批发订货单',
  'pff': '批发发货单',
  'pft': '批发退货单',
  'lsd': '零售单',
};

const Map<String, String> summNames = {
  'cgd': '采购订货',
  'cgj': '采购进货',
  'cgt': '采购退货',
  'cg': '净采购',
  'dbd': '调拨',
  'syd': '损益',
  'pfd': '批发订货',
  'pff': '批发发货',
  'pft': '批发退货',
  'pf': '净批发',
  'lsd': '零售',
  'xs': '净销售',
};

/// 查询类型名
const List<String> qryTypes = ['summ', 'cash', 'rest', 'stock', 'view'];

/// 查询主菜单
const List<String> qryMenus = [
  'summ',
  'cash_cg',
  'rest_cg',
  'cash_pf',
  'rest_pf',
  'stock',
  'view'
];
const Map<String, String> qryNames = {
  'summ': '业务统计',
  'cash_cg': '采购欠款',
  'cash_pf': '批发欠款',
  'rest_cg': '采购欠货',
  'rest_pf': '批发欠货',
  'stock': '货品库存',
  'view': '进销存一览',
};

/// 查询结果字段名
const Map<String, String> qryResultFieldNames = {
  'shop': '门店',
  'cargo': '货号',
  'color': '颜色',
  'sizer': '尺码',
  'qty': '数量',
  'summqty': '数量',
  'summmny': '金额',
  'summdis': '折扣',
  'cashqty': '数量',
  'cashmny': '金额',
  'cashdis': '折扣',
  'cashpay': '实付',
  'cashowe': '欠款',
  'restqty': '数量',
  'restmny': '金额',
  'stockqty': '数量',
  'stockmny': '金额',
  'stockdis': '折扣',
  'qc': '期初',
  'gj': '购进',
  'gt': '购退',
  'sy': '损益',
  'dr': '调入',
  'dc': '调出',
  'pf': '批发',
  'pt': '批退',
  'ls': '零售',
  'qm': '期末',
};

/// 单据类
class Business {
  static String shopNameOf(String tname) {
    if (tname == 'dbd') {
      return '调出店';
    } else if (tname == 'szd') {
      return '关联门店';
    } else {
      return '门店';
    }
  }

  static String traderNameOf(String tname) {
    if (tname.startsWith('cg')) {
      return '厂商';
    } else if (tname == 'dbd') {
      return '调入店';
    } else if (tname == 'syd') {
      return '损益店';
    } else if (tname.startsWith('pf') || tname.startsWith('xs')) {
      return '客户';
    } else if (tname == 'lsd') {
      return '顾客';
    } else if (tname == 'szd') {
      return '关联客商';
    } else {
      return '';
    }
  }

  static String payNameOf(String tname) {
    if (tname.startsWith('cg')) {
      return '本单实付';
    } else if (tname == 'dbd') {
      return '本次实计金额';
    } else if (tname == 'syd') {
      return '本单损益';
    } else {
      return '本单实收';
    }
  }
}

/// 计算名称HASH（short md5）
int shortMd5Int(String plain) {
  var bytes = const Utf8Encoder().convert(plain);
  crypto.Digest digest = crypto.md5.convert(bytes);
  Uint8List hashData = Uint8List.fromList(digest.bytes);
  var hashView = ByteData.view(hashData.buffer);
  return hashView.getUint64(4);
}

/// 计算名称HASH（short md5）
String shortMd5Hex(String plain) {
  var bytes = const Utf8Encoder().convert(plain);
  crypto.Digest digest = crypto.md5.convert(bytes);
  return packconvert.hex.encode(digest.bytes).substring(8, 24);
}

/// 条码规则
class BarcodeRule {
  BarcodeRule({
    required this.barcodexp,
    required this.sizermiddlee,
  });

  final String barcodexp;
  final bool sizermiddlee;

  static List<BarcodeRule> parseListFrom(List<String> lines) {
    return lines.map((line) {
      List<String> cols = line.split('\t');
      return BarcodeRule(
        barcodexp: cols[0],
        sizermiddlee: int.tryParse(cols[1]) != 0,
      );
    }).toList();
  }
}

/// 码组
class SizerType {
  SizerType({
    required this.tname, //typeName not tableName
    required this.namelist,
    required this.codelist,
  });

  final String tname;
  final List<String> namelist;
  final List<String> codelist;

  static List<SizerType> parseListFrom(List<String> lines) {
    return lines.map((line) {
      List<String> cols = line.split('\t');
      return SizerType(
        tname: cols[0],
        namelist: cols[1].split(','),
        codelist: cols[2].split(','),
      );
    }).toList();
  }
}

/// 色组
class ColorType {
  ColorType({
    required this.tname, //typeName not tableName
    required this.namelist,
    required this.codelist,
  });

  final String tname;
  final List<String> namelist;
  final List<String> codelist;

  static List<ColorType> parseListFrom(List<String> lines) {
    return lines.map((line) {
      List<String> cols = line.split('\t');
      return ColorType(
        tname: cols[0],
        namelist: cols[1].split(','),
        codelist: cols[2].split(','),
      );
    }).toList();
  }
}

/// 货品
class Cargo {
  Cargo({
    required this.hpcode,
    this.hpname = '',
    this.sizertype = '',
    this.colortype = '',
    this.unit = '',
    this.setprice = 1000.0,
    this.retprice = 0.0,
    this.lotprice = 0.0,
    this.buyprice = 0.0,
    this.pinyincode = '',
  });

  final String hpcode;
  final String hpname;
  final String sizertype;
  final String colortype;
  final String unit;
  final double setprice;
  final double retprice;
  final double lotprice;
  final double buyprice;
  String pinyincode = '';
  String imagedata = '';
  bool favoritee = false;

  /*
  String get fileBasename {
    String str = '';
    for (int i = 0, iLen = hpcode.length; i < iLen; ++i) {
      int code = hpcode.codeUnitAt(i);
      str += ((code > 47 && code < 58) ||
              (code > 64 && code < 91) ||
              (code > 96 && code < 123))
          ? String.fromCharCode(code)
          : code.toString();
    }
    return str;
  }
  */

  static List<Cargo> parseListFrom(List<String> lines) {
    return lines.map((line) {
      List<String> cols = line.split('\t');
      Cargo cargo = Cargo(
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
      cargo.pinyincode = pinAcronym(cols[1]);
      return cargo;
    }).toList();
  }
}

/// 科目
class Fee {
  Fee({
    required this.kname,
  });

  final String kname;

  static List<Fee> parseListFrom(List<String> lines) {
    return lines.map((line) {
      List<String> cols = line.split('\t');
      return Fee(
        kname: cols[0],
      );
    }).toList();
  }
}

/// 门店
class Shop {
  Shop({
    required this.kname,
    this.regdis = 1.0,
    this.regman = '',
    this.regaddr = '',
    this.regtele = '',
  });

  final String kname;
  final double regdis;
  final String regman;
  final String regaddr;
  final String regtele;

  static List<Shop> parseListFrom(List<String> lines) {
    return lines.map((line) {
      List<String> cols = line.split('\t');
      return Shop(
        kname: cols[0],
        regdis: (int.tryParse(cols[1]) ?? 10000) / 10000,
        regman: cols[2],
        regaddr: cols[3],
        regtele: cols[4],
      );
    }).toList();
  }
}

/// 客户
class Customer {
  Customer({
    required this.kname,
    this.regdis = 1.0,
    this.regman = '',
    this.regaddr = '',
    this.regtele = '',
  });

  final String kname;
  final double regdis;
  final String regman;
  final String regaddr;
  final String regtele;

  static List<Customer> parseListFrom(List<String> lines) {
    return lines.map((line) {
      List<String> cols = line.split('\t');
      return Customer(
        kname: cols[0],
        regdis: (int.tryParse(cols[1]) ?? 10000) / 10000,
        regman: cols[2],
        regaddr: cols[3],
        regtele: cols[4],
      );
    }).toList();
  }
}

/// 厂商
class Supplier {
  Supplier({
    required this.kname,
    this.regdis = 1.0,
    this.regman = '',
    this.regaddr = '',
    this.regtele = '',
  });

  final String kname;
  final double regdis;
  final String regman;
  final String regaddr;
  final String regtele;

  static List<Supplier> parseListFrom(List<String> lines) {
    return lines.map((line) {
      List<String> cols = line.split('\t');
      return Supplier(
        kname: cols[0],
        regdis: (int.tryParse(cols[1]) ?? 10000) / 10000,
        regman: cols[2],
        regaddr: cols[3],
        regtele: cols[4],
      );
    }).toList();
  }
}

/// 员工
class Staff {
  Staff({
    required this.kname,
  });

  final String kname;

  static List<Staff> parseListFrom(List<String> lines) {
    return lines.map((line) {
      List<String> cols = line.split('\t');
      return Staff(
        kname: cols[0],
      );
    }).toList();
  }
}

/// 价格政策
class Policy {
  Policy({
    required this.traderExp,
    required this.cargoExp,
    required this.policyDis,
    required this.useLevel,
    required this.startDate,
    required this.endDate,
  });

  final String traderExp;
  final String cargoExp;
  final double policyDis;
  final int useLevel;
  final int startDate;
  final int endDate;

  static List<Policy> parseListFrom(List<String> lines) {
    return lines.map((line) {
      List<String> cols = line.split('\t');
      return Policy(
        traderExp: cols[0],
        cargoExp: cols[1],
        policyDis: (int.tryParse(cols[2]) ?? 10000) / 10000,
        useLevel: int.tryParse(cols[3]) ?? 0,
        startDate: int.tryParse(cols[4]) ?? 0,
        endDate: int.tryParse(cols[5]) ?? 0,
      );
    }).toList();
  }
}

/// 细分类
class BSubTypes {
  BSubTypes();
  BSubTypes.fromParams({
    required this.cgdTypes,
    required this.cgjTypes,
    required this.cgtTypes,
    required this.dbdTypes,
    required this.sydTypes,
    required this.pfdTypes,
    required this.pffTypes,
    required this.pftTypes,
    required this.lsdTypes,
    required this.szdTypes,
  });

  List<String> cgdTypes = [];
  List<String> cgjTypes = [];
  List<String> cgtTypes = [];
  List<String> dbdTypes = [];
  List<String> sydTypes = [];
  List<String> pfdTypes = [];
  List<String> pffTypes = [];
  List<String> pftTypes = [];
  List<String> lsdTypes = [];
  List<String> szdTypes = [];

  List<String> getTypesOf(String tname) {
    if (tname == 'cgd') return cgdTypes;
    if (tname == 'cgj') return cgjTypes;
    if (tname == 'cgt') return cgtTypes;
    if (tname == 'dbd') return dbdTypes;
    if (tname == 'syd') return sydTypes;
    if (tname == 'pfd') return pfdTypes;
    if (tname == 'pff') return pffTypes;
    if (tname == 'pft') return pftTypes;
    if (tname == 'lsd') return lsdTypes;
    if (tname == 'szd') return szdTypes;
    return [];
  }

  //stype为bailioption表数据，每次登录都全返回，不需要本地存储，
  //而且，本APP离线使用时也无需非得stype不可。
}

/*
/// 包装表
class BoxTable with ChangeNotifier {

  BoxTable(this.hiveBox);
  final Box hiveBox;

  int get length => hiveBox.length;

  String valueOf(String key) => hiveBox.get(key);
  String valueAt(int index) => hiveBox.getAt(index);

  Future<void> save(String key, String data, {notify: false}) async {
    await hiveBox.put(key, data);
    if ( notify ) notifyListeners();
  }

  Future<void> deleteAt(int index, {notify: false}) async {
    await hiveBox.deleteAt(index);
    if (notify) notifyListeners();
  }
}
*/
