import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:testapp3/LogInPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:testapp3/gradebook.dart';
import 'package:testapp3/homepage.dart';
import 'package:testapp3/landing.dart';
import 'package:testapp3/profile/profile.dart';
import 'package:testapp3/search.dart';
import 'firebase_options.dart';
void main() async {

  /*List<String> stuff=["hershey","kitkat","snickers","smarties","skittles"];
  List<int> letters=[];
  for(int i=0;i<stuff.length;i=i+1){
    letters.add(stuff[i].length);
  }
  print(stuff);
  print(stuff[3]);
  print(letters);*/

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: "assets/.env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home:homepage()
      //LandingPage()

    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String hello = 'hi';

  void _incrementCounter() {
    setState(() {
      _counter=_counter+1;
      if(_counter%2==0){
        hello="even";
      } else {
        hello="odd";
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor:Colors.greenAccent,
        title: Text(widget.title),

      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: ListView(
          children: <Widget>[
            ElevatedButton(onPressed: ()=>Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginPage())), child: Text("Click On Me")),
            ElevatedButton(onPressed: ()=>Navigator.of(context).push(MaterialPageRoute(builder: (context) => const homepage())), child: Text("Click On Me")),
            Row(
              children: [
                const Text('🫥🫥🫥🫥🫥🫥🫥🫥hello'),
                Text(
                  '$_counter$hello',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ]
            ),
            const Image(
              image: NetworkImage('https://img.freepik.com/premium-vector/cute-red-fox-cartoon-character-vector-illustration_720912-20.jpg'),
            ),
            Image.network('https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg'),
            Image.network('https://images.squarespace-cdn.com/content/v1/66a915244ca56a48947821db/c83ac024-abd2-4cb2-8aca-d81056f08a6c/santas-little-helper-simpsons-dog-character-800x566+2.jpg')
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'BE QUIET',
        child: const Icon(Icons.lightbulb_circle),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
