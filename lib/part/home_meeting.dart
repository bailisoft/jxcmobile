import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/define.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/page/chat.dart';
import 'package:jxcmobile/model/chat.dart';
import 'package:jxcmobile/page/group_manage.dart';

class MeetingItem extends StatelessWidget {
  const MeetingItem({
    Key? key,
    required this.conversation,
    required this.onOpen,
  }) : super(key: key);

  final Conversation conversation;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final List<String> members = conversation.members.split('\t');
    final comm = Provider.of<Comm>(context, listen: false);

    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.transparent,
        child: Row(
          children: <Widget>[
            Icon(
              (conversation.members.isNotEmpty) ? Icons.group : Icons.person,
              color: primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              conversation.conversationName,
              style: TextStyle(color: primaryColor),
            ),
            const SizedBox(width: 6),
            Text(
              (members.length > 1) ? '(${members.length + 1}人)' : '',
              style: const TextStyle(color: Colors.black54),
            ),
            Expanded(child: Container()),
            (conversation.arriving)
                ? Icon(Icons.attachment, size: 16, color: primaryColor)
                : Container(),
          ],
        ),
      ),
      onTap: () async {
        await comm.tableOpen(chatHiveTable);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return MeetingChat(conversation: conversation);
          }),
        );
        onOpen();
      },
    );
  }
}

class HomeMeeting extends StatefulWidget {
  const HomeMeeting({Key? key}) : super(key: key);

  @override
  _HomeMeetingState createState() => _HomeMeetingState();
}

class _HomeMeetingState extends State<HomeMeeting> {
  late final Comm comm;

  void netResponsed() {
    List<String> req = comm.currentRequest;
    List<String> res = comm.currentResponse;
    if (req.isNotEmpty && req[0].startsWith('GRP') && res.length > 2) {
      if (res[res.length - 1] == 'OK') {
        comm.saveMeetingEvent(res, false); //此为总经理收到后台反馈
      }
      comm.clearResponse();
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    comm = Provider.of<Comm>(context, listen: false);
    comm.addListener(netResponsed);
  }

  @override
  void dispose() {
    comm.removeListener(netResponsed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bossButton = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 20),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.group_add),
        label: const Text('创建沟通群'),
        onPressed: () async {
          List<String> persons = [];
          for (var m in comm.talks) {
            if (m.members.isEmpty && m.conversationId.length == 16) {
              persons.add(m.conversationName);
            }
          }

          final List<String>? members = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GroupManage(
                manAct: GroupManageAction.create,
                title: '创建沟通群',
                allMembers: persons,
              ),
            ),
          );

          if (members != null) {
            int reqId = (DateTime.now()).microsecondsSinceEpoch;
            int newMeetId = (DateTime.now()).millisecondsSinceEpoch;
            List<String> params = [
              'GRPCREATE',
              reqId.toString(),
              newMeetId.toString(),
              members[members.length - 1], //群名，对话页面中已经有确保验证
              members.sublist(0, members.length - 1).join('\t'),
            ];
            comm.workRequest(context, params);
          }
        },
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: comm.talks.length + 1,
        separatorBuilder: (context, i) => Container(
          height: 1,
          color: Theme.of(context).primaryColor,
        ),
        itemBuilder: (context, i) {
          if (i == comm.talks.length) {
            return (comm.fronterIsBoss) ? bossButton : Container();
          }
          final conversation = comm.talks[i];
          final box = comm.tableOf(chatHiveTable);
          conversation.arriving = false;
          for (int i = box.length - 1; i >= 0; --i) {
            Message msg = Message.parseFrom(box.getAt(i));
            if (msg.conversationId == conversation.conversationId && msg.status == 2) {
              conversation.arriving = true;
              break;
            }
          }
          return MeetingItem(
            conversation: conversation,
            onOpen: () {
              setState(() {});
            },
          );
        },
      ),
    );
  }
}
