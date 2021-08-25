import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  Map<String, dynamic> lastRemoved = Map();
  int lastRemovedPos = 0;

  @override
  void initState() {
    super.initState();
    _readData().then((value) {
      setState(() {
        _toDoList = json.decode(value);
      });
    });
  }

  final toDoController = TextEditingController();

  void _addTodoList() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = toDoController.text;
      toDoController.text = "";
      newTodo["isFinished"] = false;
      _toDoList.add(newTodo);
      _saveData();
    });
  }

  Future<Null> refresh() async {
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        _toDoList.sort((a,b){
          if(a["isFinished"] && !b["isFinished"]) return 1;
          else if(!a["isFinished"] && b["isFinished"]) return -1;
          else return 0;
        });
        _saveData();
      });
      return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Lista de tarefas",
          ),
          backgroundColor: Colors.indigo,
          centerTitle: true,
        ),
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: toDoController,
                      decoration: InputDecoration(
                          labelText: "nova tarefa",
                          labelStyle: TextStyle(color: Colors.indigo)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _addTodoList,
                    child: Text("ADD"),
                    style: ElevatedButton.styleFrom(
                        primary: Colors.indigo,
                        textStyle: TextStyle(
                          color: Colors.white,
                        )),
                  ),
                ],
              ),
            ),
            Expanded(
                child: RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView.builder(
                      padding: EdgeInsets.only(top: 10),
                      itemCount: _toDoList.length,
                      itemBuilder: buildItem,
              ),
            ))
          ],
        ));
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()), //random value
      background: Container(
        color: Colors.red,
        child: Align(
            alignment: Alignment(-0.9, 0),
            child: Icon(Icons.delete, color: Colors.white)),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        onChanged: (c) {
          setState(() {
            _toDoList[index]["isFinished"] = c;
            _saveData();
          });
        },
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["isFinished"],
        secondary: CircleAvatar(
          child:
              Icon(_toDoList[index]["isFinished"] ? Icons.check : Icons.error),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          lastRemoved = Map.from(_toDoList[index]);
          lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text(
              "Tarefa ${lastRemoved["title"]} removida com sucesso!",
              style: TextStyle(color: Colors.white),
            ),
            action: SnackBarAction(
              label: "Desfazer",
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _toDoList.insert(lastRemovedPos, lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.indigo,
          );
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();

    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return "null";
    }
  }
}
