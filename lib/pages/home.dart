import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ruh_b_ru/pages/activity_feed.dart';
import 'package:ruh_b_ru/pages/create_account.dart';
import 'package:ruh_b_ru/pages/personal_expenses.dart';
import 'package:ruh_b_ru/pages/profile.dart';
import 'package:ruh_b_ru/pages/search.dart';
import 'package:ruh_b_ru/pages/timeline.dart';
import 'package:ruh_b_ru/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';

final activityFeedRef = FirebaseFirestore.instance.collection("feed");
final timelineRef = FirebaseFirestore.instance.collection("timeline");
final commentsRef = FirebaseFirestore.instance.collection("comments");
final followersRef = FirebaseFirestore.instance.collection('followers');
final followingRef = FirebaseFirestore.instance.collection('following');

final GoogleSignIn googleSignIn = GoogleSignIn();

final Reference storageRef = FirebaseStorage.instance.ref();
final usersRef = FirebaseFirestore.instance.collection('users');
final postsRef = FirebaseFirestore.instance.collection('posts');
final DateTime timestamp = DateTime.now();
User? currentUser;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int pageIndex = 0;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // ignore: unused_field
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool isAuth = false;
  late PageController pageController;

  @override
  void initState() {
    pageController = PageController();
    super.initState();
    // Detects when user signed in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      print('Error signing in: $err');
    });
    // Reauthenticate user when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
      print('Error signing in: $err');
    });
  }

  handleSignIn(GoogleSignInAccount? account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount? user = googleSignIn.currentUser;

    _firebaseMessaging.getToken().then((token) {
      print("Firebase Messaging Token: $token\n");
      usersRef.doc(user!.id).update({"androidNotificationToken": token});
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("on message: $message\n");
      final String recipientId = message.data['data']['recipient'];
      final String body = message.data['notification']['body'];
      if (recipientId == user!.id) {
        print("Notification shown!");
        SnackBar snackbar = SnackBar(
            content: Text(
          body,
          overflow: TextOverflow.ellipsis,
        ));
        // ignore: deprecated_member_use
        _scaffoldKey.currentState?.showSnackBar(snackbar);
      }
      print("Notification NOT shown");
    });
    /*_firebaseMessaging.configure(
      // onLaunch: (Map<String, dynamic> message) async {},
      // onResume: (Map<String, dynamic> message) async {},
      onMessage: (Map<String, dynamic> message) async {
        print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if (recipientId == user.id) {
          print("Notification shown!");
          SnackBar snackbar = SnackBar(
              content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        print("Notification NOT shown");
      },
    );*/
  }

  createUserInFirestore() async {
    // 1) check if user exists in users collection in database
    //(according to their id)
    final GoogleSignInAccount? user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.doc(user?.id).get();

    if (!doc.exists) {
      // 2) if the user doesn't exist, then we want to take them to the
      // create account page
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));

      // 3) get username from create account,
      // use it to make new user document
      // in users collection
      usersRef.doc(user?.id).set({
        "id": user?.id,
        "username": username,
        "photoUrl": user?.photoUrl,
        "email": user?.email,
        "displayName": user?.displayName,
        "bio": "",
        "timestamp": timestamp
      });
      // make new user their own follower (to include their posts in their timeline)
      await followersRef
          .doc(user!.id)
          .collection('userFollowers')
          .doc(user.id)
          .set({});

      doc = await usersRef.doc(user.id).get();
    }

    currentUser = User.fromDocument(doc);
    print(currentUser);
    print(currentUser!.username);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.bounceInOut,
    );
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      body: PageView(
        // ignore: sort_child_properties_last
        children: <Widget>[
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(
            profileId: currentUser?.id,
          ),
          PersonalExpenses()
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
          currentIndex: pageIndex,
          onTap: onTap,
          activeColor: Theme.of(context).primaryColor,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.whatshot),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.photo_camera,
                size: 35.0,
              ),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
            ),
            BottomNavigationBarItem(
                icon: Icon(
              Icons.money,
            )),
          ]),
    );
  }

  Scaffold buildUnAuthScreen() {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Ruh-B-Ruh',
              style: TextStyle(
                fontFamily: "Signatra",
                fontSize: 60.0 *
                    curScaleFactor *
                    MediaQuery.of(context).size.height *
                    0.002,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.1,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'images/google_signin_button.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
