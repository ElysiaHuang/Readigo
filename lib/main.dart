import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:testapp3/LogInPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:testapp3/books/book_provider.dart';
import 'package:testapp3/books/preview.dart';
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
  runApp(ChangeNotifierProvider(create: (_)=>BookProvider(),child: const MyApp(),),);
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
      home: LandingPage()

    );
  }
}

