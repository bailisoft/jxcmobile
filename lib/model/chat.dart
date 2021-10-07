/// 沟通人或群（本地不存储）
class Conversation {
  Conversation({
    required this.conversationId,
    required this.conversationName,
    required this.members, //名表，非intID表也非hashID表
    this.arriving = false,
  });

  //如为16位则为单聊对象HexID，否则为meetEpoch.DecimalID（绝对少于16位）
  String conversationId;

  //群名或单聊对象可读名称
  String conversationName;

  //单聊则为空
  String members;

  //是否包含未读新消息
  bool arriving;

  //因仅用于从LOGIN请求返回数据中使用。而LOGIN返回数据中使用\v替换了数据中的\t，故而如下替换。
  static List<Conversation> parseListFrom(List<String> lines) {
    return lines.map((line) {
      List<String> cols = line.split('\t');
      return Conversation(
        conversationId: cols[0],
        conversationName: cols[1],
        members: cols[2].split('\v').join('\t'),
      );
    }).toList();
  }
}

/// 聊天消息
class Message {
  Message({
    required this.msgid,
    required this.conversationId,
    required this.sender,
    required this.content,
    this.status = 0,
    this.netReqId = 0,
  });
  int msgid; //CurrentMicroSecondsSinceEpoch，通初建网络请求的的reqId
  String conversationId; //等于16位表示单聊对象HashHexId
  String sender; //可读名称，非HexID（因仅为显示用）。自己为空。
  String content; //内容
  int status; //0未发送、1已发送、2未读、3已读
  int netReqId; //临时标记使用

  String joinMain() {
    List<String> cols = [
      msgid.toString(),
      conversationId,
      sender,
      content,
      status.toString(),
    ];
    return cols.join('\x1e');
  }

  static Message parseFrom(String data) {
    List<String> cols = data.split('\x1e');
    Message msg = Message(
      msgid: int.tryParse(cols[0]) ?? 0,
      conversationId: cols[1],
      sender: cols[2],
      content: cols[3],
      status: int.tryParse(cols[4]) ?? 0,
      netReqId: 0,
    );
    return msg;
  }

  static List<Message> parseListFrom(List<String> lines) {
    return lines.map((line) {
      List<String> cols = line.split('\t');
      return Message(
        msgid: int.tryParse(cols[0]) ?? 0,
        conversationId: ((cols[3].length == 16) ? cols[1] : cols[3]),
        sender: cols[2],
        content: cols[4],
        status: 2,
      );
    }).toList();
  }
}
