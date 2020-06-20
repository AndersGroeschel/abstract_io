import 'package:abstract_io/abstract_io.dart';
import 'package:file_io_interface/file_io_interface.dart';
import 'package:flutter/material.dart';


/// the translator used for [Counter]
class StringIntTranslator extends Translator<String, int>{
  @override
  String translateReadable(int readable) {
    return "$readable";
  }

  @override
  int translateWritable(String writable) {
    return int.parse(writable);
  }
}

/// counts a value and stores it in a file
/// 
/// gives an initial value of 0
class Counter extends AbstractIO<String, int> with ValueStorage, ValueAccess, ValueListenableSupport, InitialValue{

  Counter(
    String filePath
  ):super(
    StringFileInterface(filePath),
    translator: StringIntTranslator()
  );

  @override
  int get initialValue => 0;

}



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Counter _count;

  // increments the value in the counter
  void _incrementCounter() {
    _count.value += 1;
  }

  @override
  void initState() {
    _count = Counter("counter");
    _count.load();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),

            // listens to the counter object and rebuilds whenever the value is updated
            ValueListenableBuilder(
              valueListenable: _count, 
              builder: (context, count, child){
                return Text(
                  "$count",
                  style: Theme.of(context).textTheme.headline6,
                );
              }
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
