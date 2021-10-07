import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/styles.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/model/chat.dart';
import 'package:jxcmobile/part/extra_menu_meeting.dart';

/// MeetingChat
class MeetingChat extends StatefulWidget {
  const MeetingChat({
    Key? key,
    required this.conversation,
  }) : super(key: key);
  final Conversation conversation;
  @override
  _MeetingChatState createState() => _MeetingChatState();
}

class _MeetingChatState extends State<MeetingChat> {
  final editor = TextEditingController();

  late final Comm comm;

  void netResponsed() {
    if (comm.netErrorMsg.isNotEmpty) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    List<String> fens = comm.currentResponse;
    if (fens.isNotEmpty &&
        fens[0] == 'MESSAGE' &&
        fens.length == 4 &&
        fens[3] == 'OK') {
      int reqId = int.tryParse(fens[1]) ?? 0;
      Box box = comm.tableOf(chatHiveTable);
      for (int i = box.length - 1; i >= 0; --i) {
        Message msg = Message.parseFrom(box.getAt(i));
        if (msg.msgid == reqId) {
          msg.status = 1;
          comm.tableSave(chatHiveTable, msg.msgid.toString(), msg.joinMain(),
              notify: true);
          break;
        }
      }
    }
    setState(() {});
  }

  void msgClear() {
    Future.delayed(const Duration(milliseconds: 50)).then((_) {
      editor.clear(); //直接使用editor.clear()有BUG
      FocusScope.of(context).unfocus();
    });
  }

  void msgResend(Message msg) {
    List<String> params = [
      'MESSAGE',
      msg.msgid.toString(),
      comm.fronterHashHex,
      comm.fronterName,
      msg.conversationId,
      msg.content.replaceAll(RegExp(r'\n'), '\r'),
    ];
    comm.workRequest(context, params);
  }

  void msgNewSend(String content) {
    if (content.isEmpty) return; //必须

    int reqId = (DateTime.now()).microsecondsSinceEpoch;
    //Qt后端虽然也解密并记录，然而记录后为了减少重新构造包重新压缩加密的麻烦，采用原包照转方式，
    //因此为便于接收方识别，发送信息时加入了发送方冗余信息。也因此Qt端解包记录时需要验证防止伪造
    //发送人。
    List<String> params = [
      'MESSAGE',
      reqId.toString(),
      comm.fronterHashHex,
      comm.fronterName,
      widget.conversation.conversationId,
      content.replaceAll(RegExp(r'\n'), '\r'),
    ];
    comm.workRequest(context, params);

    //本地记录
    setState(() {
      Message one = Message(
        msgid: reqId,
        conversationId: widget.conversation.conversationId,
        sender: '',
        content: content,
        status: 0,
        netReqId: reqId,
      );
      comm.tableSave(chatHiveTable, one.msgid.toString(), one.joinMain(),
          notify: true);
      msgClear();
    });
  }

  Widget makeBubble(Conversation conversation, Message msg, bool lastt) {
    bool self = (msg.sender.isEmpty);
    Color primaryColor = Theme.of(context).primaryColor;

    //状态图标
    Widget statusIcon = (msg.status == 0)
        ? GestureDetector(
            child: Icon(
              Icons.refresh,
              size: 12.0,
              color: (self) ? const Color(0xffcccccc) : Colors.grey,
            ),
            onTap: () => msgResend(msg),
          )
        : Container();

    //发言人
    Widget author = Container();
    if (conversation.members.isNotEmpty) {
      author = (self)
          ? const Text(
              ' 我',
              textScaleFactor: 0.75,
              style: TextStyle(color: Colors.white),
            )
          : Text(
              '${msg.sender} ',
              textScaleFactor: 0.75,
              style: TextStyle(color: (self) ? Colors.white : primaryColor),
            );
    }

    //别人信息头
    final othersTitle = Row(
      children: <Widget>[
        author,
        Text(
          formatAsDateTime(
            DateTime.fromMillisecondsSinceEpoch(msg.msgid ~/ 1000),
            timeDevide: false,
          ),
          textScaleFactor: 0.75,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(width: 6),
        statusIcon,
      ],
    );

    //自己信息头
    final selfTitle = Row(
      children: <Widget>[
        Expanded(child: Container()),
        statusIcon,
        const SizedBox(width: 6),
        Text(
          formatAsDateTime(
            DateTime.fromMillisecondsSinceEpoch(msg.msgid ~/ 1000),
            timeDevide: false,
          ),
          textScaleFactor: 0.75,
          style: const TextStyle(color: Color(0xffcccccc)),
        ),
        author,
      ],
    );

    //未读图标
    final unreadMark = GestureDetector(
      child: Row(
        children: <Widget>[
          Transform.rotate(
            angle: 90 * pi / 180,
            child: const Icon(Icons.attach_file, size: 32, color: Colors.grey),
          ),
          const Text('点击读取', style: TextStyle(color: Colors.grey)),
        ],
      ),
      onTap: () {
        setState(() {
          msg.status = 3;
          comm.tableSave(chatHiveTable, msg.msgid.toString(), msg.joinMain());
        });
      },
    );

    //读取内容
    final openContent = Text(
      msg.content,
      textAlign: (self) ? TextAlign.right : TextAlign.left,
    );

    //气泡整体
    return Padding(
      padding: EdgeInsets.only(
        left: (self) ? 60 : 6,
        right: (self) ? 6 : 60,
        top: 18,
        bottom: (lastt) ? 120 : 0,
      ),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 0.5), // 边色与边宽度
          color: (self) ? primaryColor : Colors.white, // 底色
          borderRadius: BorderRadius.circular(12), // 圆角度
        ),
        child: Align(
          alignment: (self) ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
                (self) ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: <Widget>[
              (self) ? selfTitle : othersTitle,
              (msg.status == 2) ? unreadMark : openContent,
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    comm = Provider.of<Comm>(context, listen: false);
    comm.addListener(netResponsed);
  }

  @override
  void dispose() {
    editor.dispose();
    comm.removeListener(netResponsed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //取得本群（人）消息
    List<Message> msgs = [];
    final Conversation conversation = widget.conversation;
    Box box = comm.tableOf(chatHiveTable);
    for (int i = 0, iLen = box.length; i < iLen; ++i) {
      Message msg = Message.parseFrom(box.getAt(i));
      if (msg.conversationId == conversation.conversationId) {
        msgs.add(msg);
      }
    }

    //页面总布局
    return Scaffold(
      appBar: AppBar(
        title: Text(conversation.conversationName),
        actions: (comm.fronterIsBoss && conversation.members.isNotEmpty)
            ? <Widget>[ExtraMenuMeeting(conversation: conversation)]
            : <Widget>[],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              child: Container(
                color: const Color(0xffdddddd),
                child: ListView.builder(
                  itemCount: msgs.length,
                  itemBuilder: (BuildContext context, int i) {
                    return makeBubble(conversation, msgs[i], i == msgs.length - 1);
                  },
                ),
              ),
              onTap: () {
                FocusScope.of(context).unfocus();
              },
            ),
          ),
          Container(
            color: const Color(0xffdddddd),
            //padding: const EdgeInsets.all(3),
            child: TextFormField(
              controller: editor,
              maxLines: 5,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: '在此输入',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(6),
                isDense: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColorDark,
                    width: 3,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColorDark,
                    width: 3,
                  ),
                ),
                prefixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: msgClear,
                ),
                suffixIcon: IconButton(
                  icon: Transform.translate(
                    offset: const Offset(0, -3),
                    child: Transform.rotate(
                      angle: 225 * pi / 180,
                      child: const Icon(Icons.send),
                    ),
                  ),
                  onPressed: () => msgNewSend(editor.text),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
