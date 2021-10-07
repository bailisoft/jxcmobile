import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// containsHeaderChar 用于那些有些选择项只是为了显示，因为禁止权限，不让选择。
/// 约定方法为 ———— pickList的item文字第一字符为 + 表示许可，否则为禁止。
class SearchSimple extends StatelessWidget {
  const SearchSimple({
    Key? key,
    required this.title,
    required this.noResultMsg,
    required this.pickList,
    this.containsHeaderChar = false,
  }) : super(key: key);

  final String title;
  final String noResultMsg;
  final List<String> pickList;
  final bool containsHeaderChar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: <Widget>[
          const SizedBox(height: 6.0),
          Expanded(
            child: (pickList.isEmpty)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(noResultMsg),
                    ),
                  )
                : ListView.builder(
                    itemCount: pickList.length,
                    itemBuilder: (context, i) {
                      String itemText = (containsHeaderChar)
                          ? pickList[i].substring(1)
                          : pickList[i];
                      bool canPick =
                          (!containsHeaderChar || pickList[i].startsWith('+'));
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 3.0,
                        ),
                        child: ElevatedButton(
                          child: Text(itemText),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.white70,
                            onPrimary: Theme.of(context).primaryColor,
                          ),
                          onPressed: (canPick)
                              ? (() => Navigator.pop(context, itemText))
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
