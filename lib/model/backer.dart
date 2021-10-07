
/// 对象类
class Backer {
  Backer({
    required this.backerName,
    this.fronterName = '',
    this.passCode = '',
    this.cryptCode = '',
    this.comName = '',
    this.comColor = '',
    this.comLogo = '',
  });
  String backerName;
  String fronterName;
  String passCode;
  String cryptCode;
  String comName;
  String comColor;
  String comLogo;

  String joinMain() {
    List<String> cols = [
      backerName,
      fronterName,
      passCode,
      cryptCode,
      comName,
      comColor,
      comLogo,
    ];
    return cols.join('\x1e');
  }

  static Backer parseFrom(String data) {
    List<String> cols = data.split('\x1e');
    return Backer(
      backerName: cols[0],
      fronterName: cols[1],
      passCode: cols[2],
      cryptCode: cols[3],
      comName: cols[4],
      comColor: cols[5],
      comLogo: cols[6],
    );
  }
}

