
/// 帐明细
class NoteDetail {
  NoteDetail({
    required this.timeKey,
    this.desc = ' ',
    this.money = 0.0,
  });
  final int timeKey;
  String desc;
  double money;
}

/// 帐单据
class Note {
  Note({
    required this.id,
    required this.sheetid,
    required this.dated,
    this.shop = '',
    this.staff = '',
    this.remark = '',
  });
  int id;
  int sheetid; //未提交新单暂用0，提交后用返回值存储。
  int dated; //Unix纪元秒，未提交新单暂用系统时间，提交后用返回值存储。
  String shop;
  String staff;
  String remark;
  List<NoteDetail> detailList = [];

  String joinDetail() {
    List<String> list = detailList
        .map((dtl) => '${dtl.timeKey}\t${dtl.desc}\t${dtl.money}')
        .toList();
    return list.join('\n');
  }

  List<NoteDetail> parseDetail(String text) {
    List<String> list = text.split('\n');
    return list.map((line) {
      List<String> cols = line.split('\t');
      while (cols.length < 3) {
        cols.add('');
      }
      return NoteDetail(
        timeKey: int.tryParse(cols[0]) ?? 0,
        desc: cols[1],
        money: double.tryParse(cols[2]) ?? 0,
      );
    }).toList();
  }

  String sumMoney() {
    double sum = 0.0;
    void doSum(NoteDetail dtl) {
      sum += dtl.money;
    }
    detailList.forEach(doSum);
    return sum.toStringAsFixed(2);
  }

  String joinMain() {
    List<String> cols = [
      id.toString(),
      sheetid.toString(),
      dated.toString(),
      shop,
      staff,
      remark,
      joinDetail()
    ];
    return cols.join('\x1e');
  }

  static Note parseFrom(String data) {
    List<String> cols = data.split('\x1e');
    Note bill = Note(
      id: int.tryParse(cols[0]) ?? 0,
      sheetid: int.tryParse(cols[1]) ?? 0,
      dated: int.tryParse(cols[2]) ?? 0,
      shop: cols[3],
      staff: cols[4],
      remark: cols[5],
    );
    bill.detailList = bill.parseDetail(cols[6]);
    return bill;
  }
}
