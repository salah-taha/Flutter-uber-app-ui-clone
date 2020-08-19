import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutteruberapp/pages/index.dart';
import 'package:flutteruberapp/pages/splash.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashPage(),
      debugShowCheckedModeBanner: false,
      routes: {
        'home': (_) => HomePage(),
      },
    );
  }
}
