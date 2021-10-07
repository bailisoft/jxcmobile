import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jxcmobile/share/comm.dart';
import 'package:jxcmobile/share/toasts.dart';
import 'package:jxcmobile/model/chat.dart';
import 'package:jxcmobile/page/group_manage.dart';

class ExtraMenuMeeting extends StatelessWidget {
  const ExtraMenuMeeting({
    Key? key,
    required this.conversation,
  }) : super(key: key);

  final Conversation conversation;

  void groupAdd(BuildContext context, Comm comm) async {
    List<String> existsMembers = conversation.members.split('\t');
    List<String> candidates = [];

    for (var m in comm.talks) {
      //print('conversationId:${m.conversationId}, conversationName:${m.conversationName}, members:${m.members}');
      //16位名为meet实为单聊人，真实meet的meetid为绝不超过16位的EpochSeconds
      if ( m.conversationId.length == 16 && !existsMembers.contains(m.conversationName) ) {
        candidates.add(m.conversationName);
      }
    }
    if ( candidates.isEmpty ) {
      AppToast.show('本群已添加所有人', context);
      return;
    }

    final List<String>? news = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupManage(
          manAct: GroupManageAction.add,
          title: '添加新人',
          allMembers: candidates,
        ),
      ),
    );
    if ( news == null || news.isEmpty ) return;

    int reqId = DateTime.now().microsecondsSinceEpoch;
    List<String> params = [
      'GRPINVITE',
      reqId.toString(),
      conversation.conversationId,
      conversation.conversationName,
      conversation.members,
      news.join('\t'),
    ];
    comm.workRequest(context, params);
  }

  void groupKick(BuildContext context, Comm comm) async {
    final List<String>? members = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupManage(
          manAct: GroupManageAction.kick,
          title: '移除成员',
          allMembers: conversation.members.split('\t'),
        ),
      ),
    );
    if ( members == null || members.isEmpty ) return;

    int reqId = DateTime.now().microsecondsSinceEpoch;
    List<String> params = [
      'GRPKICKOFF',
      reqId.toString(),
      conversation.conversationId,
      members.join('\t'),
    ];
    comm.workRequest(context, params);
  }

  void groupRename(BuildContext context, Comm comm) async {
    final newName = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GroupManage(
          manAct: GroupManageAction.rename,
          title: '改群名',
          allMembers: <String>[],
        ),
      ),
    );
    if ( newName == null || newName.isEmpty ) return;

    int reqId = DateTime.now().microsecondsSinceEpoch;
    List<String> params = [
      'GRPRENAME',
      reqId.toString(),
      conversation.conversationId,
      newName,
    ];
    comm.workRequest(context, params);
  }

  void groupDismiss(BuildContext context, Comm comm) async {
    Navigator.pop(context);
    int reqId = DateTime.now().microsecondsSinceEpoch;
    List<String> params = [
      'GRPDISMISS',
      reqId.toString(),
      conversation.conversationId,
    ];
    comm.workRequest(context, params);
  }

  @override
  Widget build(BuildContext context) {
    final comm = Provider.of<Comm>(context);

    return PopupMenuButton<ExtraMeetingAction>(
      onSelected: (action) {
        switch (action) {
          case ExtraMeetingAction.add:
            groupAdd(context, comm);
            break;
          case ExtraMeetingAction.kick:
            groupKick(context, comm);
            break;
          case ExtraMeetingAction.rename:
            groupRename(context, comm);
            break;
          case ExtraMeetingAction.dismiss:
            groupDismiss(context, comm);
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return const <PopupMenuItem<ExtraMeetingAction>>[
          PopupMenuItem<ExtraMeetingAction>(
            value: ExtraMeetingAction.add,
            child: Text('添加新人'),
          ),
          PopupMenuItem<ExtraMeetingAction>(
            value: ExtraMeetingAction.kick,
            child: Text('移除成员'),
          ),
          PopupMenuItem<ExtraMeetingAction>(
            value: ExtraMeetingAction.rename,
            child: Text('改群名'),
          ),
          PopupMenuItem<ExtraMeetingAction>(
            value: ExtraMeetingAction.dismiss,
            child: Text('解散群'),
          ),
        ];
      },
    );
  }
}

enum ExtraMeetingAction { add, kick, rename, dismiss }
