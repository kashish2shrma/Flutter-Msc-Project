import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ruh_b_ru/pages/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ruh_b_ru/styles.dart';
import 'package:ruh_b_ru/widgets/progress.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dark_theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Future<FirebaseApp> _fbApp = Firebase.initializeApp();
  DarkThemeProvider themeChangeProvider = new DarkThemeProvider();

  @override
  void initState() {
    super.initState();
    getCurrentAppTheme();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
        await themeChangeProvider.darkThemePreference.getTheme();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        return themeChangeProvider;
      },
      child: Consumer<DarkThemeProvider>(
        builder: (BuildContext context, value, Widget? child) {
          return MaterialApp(
              title: 'Ruh-B-Ru',
              debugShowCheckedModeBanner: false,
              theme: Styles.themeData(themeChangeProvider.darkTheme, context),
              home: FutureBuilder(
                future: _fbApp,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('you have an error ${snapshot.error.toString()}');
                    return Text('Something Went wrong!');
                  } else if (snapshot.hasData) {
                    return Home();
                  } else {
                    return Center(
                      child: circularProgress(),
                    );
                  }
                },
              ));
        },
      ),
    );
  }
}
