import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ruh_b_ru/models/user.dart';
import 'package:ruh_b_ru/pages/home.dart';
import 'package:ruh_b_ru/pages/search.dart';
import 'package:ruh_b_ru/widgets/header.dart';
import 'package:ruh_b_ru/widgets/post.dart';
import 'package:ruh_b_ru/widgets/progress.dart';

final usersRef = FirebaseFirestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User? currentUser;

  Timeline({required this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post>? posts;
  List<String> followingList = [];

  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowing();
  }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .doc(widget.currentUser!.id)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .get();
    List<Post> posts =
        snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .doc(currentUser!.id)
        .collection('userFollowing')
        .get();
    setState(() {
      followingList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts!.isEmpty) {
      return buildUsersToFollow();
    } else {
      return ListView(children: posts as List<Widget>);
    }
  }

  buildUsersToFollow() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          usersRef.orderBy('timestamp', descending: true).limit(30).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> userResults = [];
        (snapshot.data!).docs.forEach((doc) {
          User user = User.fromDocument(doc);
          final bool isAuthUser = currentUser!.id == user.id;
          final bool isFollowingUser = followingList.contains(user.id);
          // remove auth user from recommended list
          if (isAuthUser) {
            return;
          } else if (isFollowingUser) {
            return;
          } else {
            UserResult userResult = UserResult(user);
            userResults.add(userResult);
          }
        });
        return Container(
          color: Theme.of(context).accentColor.withOpacity(0.2),
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.person_add,
                      size: 35.0,
                    ),
                    SizedBox(
                      width: 8.0,
                    ),
                    Text(
                      "Users to Follow",
                      style: TextStyle(
                        fontSize: 30.0,
                      ),
                    ),
                  ],
                ),
              ),
              Column(children: userResults),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
        appBar: header(context, isAppTitle: true, titleText: ''),
        body: RefreshIndicator(
            onRefresh: () => getTimeline(), child: buildTimeline()));
  }
}
