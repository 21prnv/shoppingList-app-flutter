import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';

import 'package:shopping_list/data/dummy_items.dart';
import 'package:shopping_list/models/grocery_Item.dart';
import 'package:shopping_list/widgets/new_items.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _newGroceryList = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'shoppinglist-flutter-76dbc-default-rtdb.firebaseio.com',
        'shopping-list.json');

    try {
      final res = await http.get(url);
      if (res.statusCode >= 400) {
        setState(() {
          _error = 'Error While Fetching Data..plz try again later';
        });
      }

      if (res.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      print(res.body);
      final Map<String, dynamic> listData = jsonDecode(res.body);
      final List<GroceryItem> _loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        _loadedItems.add(GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category));
      }
      setState(() {
        _newGroceryList = _loadedItems;
        _isLoading = false;
      });
    } catch (err) {
      setState(() {
        _error = 'Something went wrong! Please try again later.';
      });
    }
  }

  void _additem() async {
    final newItem = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (ctx) => const NewItem()));
    if (newItem == null) {
      return;
    }
    setState(() {
      _newGroceryList.add(newItem);
    });
  }

  void _removeExpese(GroceryItem groceryItem) {
    final _undoDelete = _newGroceryList.indexOf(groceryItem);
    final url = Uri.https(
        'shoppinglist-flutter-76dbc-default-rtdb.firebaseio.com',
        'shopping-list/${groceryItem.id}.json');
    http.delete(url);
    setState(() {
      _newGroceryList.remove(groceryItem);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: Duration(seconds: 5),
      content: const Text('Item Was Deleted'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          setState(() {
            _newGroceryList.insert(_undoDelete, groceryItem);
          });
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    Widget cotent = const Center(
      child: Text('oops..nothing is here :)'),
    );

    if (_isLoading) {
      cotent = const Center(
        child: const CircularProgressIndicator(),
      );
    }
    if (_newGroceryList.isNotEmpty) {
      cotent = ListView.builder(
        itemCount: _newGroceryList.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_newGroceryList[index]),
          onDismissed: (direction) {
            _removeExpese(_newGroceryList[index]);
          },
          child: ListTile(
            title: Text(_newGroceryList[index].name),
            leading: Container(
              height: 24,
              width: 24,
              color: _newGroceryList[index].category.color,
            ),
            trailing: Text(_newGroceryList[index].quantity.toString()),
          ),
        ),
      );
    }
    if (_error != null) {
      Center(
        child: Text(_error!),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _additem, icon: Icon(Icons.add))],
      ),
      body: cotent,
    );
  }
}
