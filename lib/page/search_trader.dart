import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SearchTraderDelegate extends SearchDelegate<String> {

  SearchTraderDelegate({
    String hintText = '',
    required this.searchList,
  }) : super(
          searchFieldLabel: hintText,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
        );

  final List<String> searchList;

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => query = "", //清空搜索内容
      )
    ];
  }

  @override
  Widget buildResults(BuildContext context) {
    return Column();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? searchList
        : searchList.where((e) => e.contains(query)).toList();
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16.0),
      itemCount: suggestionList.length,
      itemBuilder: (context, index) => TextButton(
        child: Text(suggestionList[index]),
        onPressed: () => close(context, suggestionList[index]),
      ),
    );
  }
}
