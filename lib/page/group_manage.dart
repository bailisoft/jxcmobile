import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:jxcmobile/share/toasts.dart';

class LabelCheckbox extends StatelessWidget {
  const LabelCheckbox({
    required this.label,
    required this.padding,
    required this.value,
    required this.selectedColor,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  final String label;
  final EdgeInsets padding;
  final bool value;
  final Color selectedColor;
  final Function onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: (value) ? selectedColor : Colors.black),
            ),
          ),
          Checkbox(
            value: value,
            activeColor: selectedColor,
            onChanged: (bool? newValue) {
              onChanged(newValue);
            },
          ),
        ],
      ),
    );
  }
}

enum GroupManageAction { create, add, kick, rename }

class GroupManage extends StatefulWidget {
  const GroupManage({
    Key? key,
    required this.manAct,
    required this.title,
    required this.allMembers,
  }) : super(key: key);

  final GroupManageAction manAct;
  final String title;
  final List<String> allMembers;

  @override
  GroupManageState createState() => GroupManageState();
}

class GroupManageState extends State<GroupManage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String meetingName = '';
  List<String> checkedList = [];

  @override
  Widget build(BuildContext context) {
    final allMembers = widget.allMembers;

    //返回函数
    void pickedOk() {
      if (widget.manAct == GroupManageAction.rename ||
          widget.manAct == GroupManageAction.create) {
        formKey.currentState!.save();
        if (meetingName.isEmpty) {
          AppToast.show('新群名必填！', context);
          return;
        }
      }

      if (widget.manAct == GroupManageAction.create &&
          checkedList.length < 2) {
        AppToast.show('建群至少需要2人！', context);
        return;
      }

      if (widget.manAct == GroupManageAction.add ||
          widget.manAct == GroupManageAction.kick) {
        if (checkedList.isEmpty) {
          AppToast.show('未选择具体人！', context);
          return;
        }
      }

      if (widget.manAct == GroupManageAction.rename) {
        Navigator.pop(context, meetingName);
      } else {
        if (widget.manAct == GroupManageAction.create) {
          checkedList.add(meetingName);
        }
        Navigator.pop(context, checkedList);
      }
    }

    //群名
    final Widget nameField = Padding(
      padding: const EdgeInsets.only(left: 60, right: 60, top: 30),
      child: Form(
        key: formKey,
        child: TextFormField(
          initialValue: meetingName,
          decoration: const InputDecoration(
            labelText: '新群名',
            isDense: true,
          ),
          onSaved: (String? value) {
            meetingName = value ?? '';
          },
        ),
      ),
    );

    //对话框按钮
    final Widget buttonPanel = Padding(
      padding: const EdgeInsets.all(60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ElevatedButton(
            child: const Text('确定'),
            onPressed: pickedOk,
          ),
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    //创建群布局
    final bodyCreate = ListView.builder(
      itemCount: allMembers.length + 2,
      itemBuilder: (context, i) {
        return (i < allMembers.length)
            ? LabelCheckbox(
                label: allMembers[i],
                padding: const EdgeInsets.only(left: 30, right: 12),
                value: checkedList.contains(allMembers[i]),
                selectedColor: Theme.of(context).primaryColor,
                onChanged: (v) {
                  setState(() {
                    if (v) {
                      checkedList.add(allMembers[i]);
                    } else {
                      checkedList.remove(allMembers[i]);
                    }
                  });
                },
              )
            : ((i == allMembers.length) ? nameField : buttonPanel);
      },
    );

    //拉人或踢人布局
    final bodyAddOrKick = ListView.builder(
      itemCount: allMembers.length + 1,
      itemBuilder: (context, i) {
        return (i < allMembers.length)
            ? LabelCheckbox(
                label: allMembers[i],
                padding: const EdgeInsets.only(left: 30, right: 12),
                value: checkedList.contains(allMembers[i]),
                selectedColor: (widget.manAct == GroupManageAction.kick)
                    ? Colors.red
                    : Theme.of(context).primaryColor,
                onChanged: (v) {
                  setState(() {
                    if (v) {
                      checkedList.add(allMembers[i]);
                    } else {
                      checkedList.remove(allMembers[i]);
                    }
                  });
                },
              )
            : buttonPanel;
      },
    );

    //改名布局
    final bodyRename = Column(
      children: <Widget>[nameField, buttonPanel],
    );

    //最终布局
    Widget pageBody;
    if (widget.manAct == GroupManageAction.create) {
      pageBody = bodyCreate;
    } else if (widget.manAct == GroupManageAction.rename) {
      pageBody = bodyRename;
    } else {
      pageBody = bodyAddOrKick;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: pageBody,
    );
  }
}
