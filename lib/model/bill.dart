import 'package:jxcmobile/share/define.dart';

/// 对象类
class BillDetail {
  BillDetail({
    required this.cargo,
    this.colorType = '',
    this.sizerType = '',
    this.qty = 1,
    this.actPrice = 0,
  });
  final Cargo cargo;
  String colorType;
  String sizerType;
  double qty;
  double actPrice;
}

/// 货单
class Bill {
  Bill({
    required this.id,
    required this.tname,
    required this.sheetid,
    required this.dated,
    this.shop = '',
    this.trader = '',
    this.stype = '',
    this.staff = '',
    this.remark = '',
    this.sumqty = 0.0,
    this.summoney = 0.0,
    this.sumdis = 0.0,
    this.actpay = 0.0,
    this.actowe = 0.0,
    this.checker = '',
    this.chktime = 0,
  });
  int id; //Unix纪元毫秒
  String tname; //cgd, cgj, cgt, pfd, pff, pft, dbd, syd, lsd
  int sheetid; //未提交新单暂用0，提交后用返回值存储。
  int dated; //Unix纪元秒，未提交新单暂用系统时间，提交后用返回值存储。
  String shop;
  String trader;
  String stype;
  String staff;
  String remark;
  double sumqty;
  double summoney;
  double sumdis;
  double actpay;
  double actowe;
  String checker;
  int chktime;
  List<BillDetail> detailList = [];

  String joinDetail() {
    List<String> list = detailList
        .map((dtl) =>
            '${dtl.cargo.hpcode}\t${dtl.colorType}\t${dtl.sizerType}\t${dtl.qty}\t${dtl.actPrice}')
        .toList();
    return list.join('\n');
  }

  List<BillDetail> parseDetail(String text, List<Cargo> regCargos) {
    List<String> list = text.split('\n');
    return list.map((line) {
      List<String> cols = line.split('\t');
      while (cols.length < 5) {
        cols.add('');
      }
      Cargo cargo = regCargos.firstWhere((e) => e.hpcode == cols[0],
          orElse: () => Cargo(hpcode: ''));
      return BillDetail(
        cargo: cargo.hpcode.isEmpty ? Cargo(hpcode: cols[0]) : cargo,
        colorType: cols[1],
        sizerType: cols[2],
        qty: (double.tryParse(cols[3]) ?? 0),
        actPrice: (double.tryParse(cols[4]) ?? 0),
      );
    }).toList();
  }

  void syncMainTotal() {
    double qty = 0;
    double mny = 0;
    void doSum(BillDetail dtl) {
      qty += dtl.qty;
      mny += dtl.actPrice * dtl.qty;
    }

    detailList.forEach(doSum);
    sumqty = qty;
    summoney = mny;
    actowe = summoney - actpay;
  }

  String joinMain() {
    List<String> cols = [
      id.toString(),
      tname,
      sheetid.toString(),
      dated.toString(),
      shop,
      trader,
      stype,
      staff,
      remark,
      sumqty.toString(),
      summoney.toString(),
      sumdis.toString(),
      actpay.toString(),
      actowe.toString(),
      checker,
      chktime.toString(),
      joinDetail()
    ];
    return cols.join('\x1e');
  }

  static Bill parseFrom(String data, List<Cargo> regCargos) {
    List<String> cols = data.split('\x1e');
    Bill bill = Bill(
      id: int.tryParse(cols[0]) ?? 0,
      tname: cols[1],
      sheetid: int.tryParse(cols[2]) ?? 0,
      dated: int.tryParse(cols[3]) ?? 0,
      shop: cols[4],
      trader: cols[5],
      stype: cols[6],
      staff: cols[7],
      remark: cols[8],
      sumqty: double.tryParse(cols[9]) ?? 0,
      summoney: double.tryParse(cols[10]) ?? 0,
      sumdis: double.tryParse(cols[11]) ?? 0,
      actpay: double.tryParse(cols[12]) ?? 0,
      actowe: double.tryParse(cols[13]) ?? 0,
      checker: cols[14],
      chktime: int.tryParse(cols[15]) ?? 0,
    );
    bill.detailList = bill.parseDetail(cols[16], regCargos);
    return bill;
  }
}
