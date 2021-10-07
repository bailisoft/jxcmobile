import 'package:jxcmobile/share/define.dart';

/// 查询
class QueryClip {
  QueryClip({
    required this.queryid,
    required this.qtype,
    this.tname = '',
    this.dateb = 0,
    this.datee = 0,
    this.shop = '',
    this.trader = '',
    this.cargo = '',
    this.color = '',
    this.sizer = '',
    this.checkk = 0,
    this.resfields = '',
    this.resvalues = '',
  });
  int queryid;
  String qtype;
  String tname; //指基表名（qryType为summ、cash、rest三种时有意义）
  int dateb;
  int datee;
  String shop;
  String trader;
  String cargo;
  String color;
  String sizer;
  int checkk; //0不限、1仅审核、2未审核
  String resfields;
  String resvalues;

  String titleName(bool forPage) {
    if (qtype == 'cash' || qtype == 'rest') {
      String menuKey =
      (qtype == 'cash' || qtype == 'rest') ? '${qtype}_$tname' : qtype;
      return qryNames[menuKey] ?? '';
    }

    if (qtype == 'summ') {
      return (forPage) ? (qryNames[qtype] ?? '') : '${summNames[tname]}统计';
    }

    return qryNames[qtype] ?? '';
  }

  String joinMain() {
    List<String> cols = [
      queryid.toString(),
      qtype,
      tname,
      dateb.toString(),
      datee.toString(),
      shop,
      trader,
      cargo,
      color,
      sizer,
      checkk.toString(),
      resfields,
      resvalues,
    ];
    return cols.join('\x1e');
  }

  static QueryClip parseFrom(String data) {
    List<String> cols = data.split('\x1e');
    QueryClip clip = QueryClip(
      queryid: int.tryParse(cols[0]) ?? 0,
      qtype: cols[1],
      tname: cols[2],
      dateb: int.tryParse(cols[3]) ?? 0,
      datee: int.tryParse(cols[4]) ?? 0,
      shop: cols[5],
      trader: cols[6],
      cargo: cols[7],
      color: cols[8],
      sizer: cols[9],
      checkk: int.tryParse(cols[10]) ?? 0,
      resfields: cols[11],
      resvalues: cols[12],
    );
    return clip;
  }
}