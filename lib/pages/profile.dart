import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ruh_b_ru/models/user.dart';
import 'package:ruh_b_ru/pages/edit_profile.dart';
import 'package:ruh_b_ru/pages/home.dart';
import 'package:ruh_b_ru/pages/personal_expenses.dart';
import 'package:ruh_b_ru/widgets/header.dart';
import 'package:ruh_b_ru/widgets/post_tile.dart';
import 'package:ruh_b_ru/widgets/progress.dart';
import 'package:ruh_b_ru/widgets/header.dart';
import 'package:ruh_b_ru/widgets/post.dart';

import '../dark_theme_provider.dart';

class Profile extends StatefulWidget {
  final String? profileId;

  Profile({required this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser!.id;
  String postOrientation = "grid";
  bool isFollowing = false;
  bool isLoading = false;
  int postCount = 0;
  List<Post> posts = [];
  int followerCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .get();
    setState(() {
      followerCount = snapshot.docs.length;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .doc(widget.profileId)
        .collection('userFollowing')
        .get();
    setState(() {
      followingCount = snapshot.docs.length;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .doc(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .get();
    setState(() {
      isLoading = false;
      postCount = snapshot.docs.length;
      posts = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  Column buildCountColumn(String label, int count) {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
              fontSize: 22.0 *
                  curScaleFactor *
                  MediaQuery.of(context).size.height *
                  0.002,
              fontWeight: FontWeight.bold),
        ),
        Container(
          margin:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.005),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14.0 *
                  curScaleFactor *
                  MediaQuery.of(context).size.height *
                  0.002,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(currentUserId: currentUserId)));
  }

  Container buildButton(
      {required String text, required VoidCallback function}) {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.05,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : Colors.blue,
            border: Border.all(
              color: isFollowing ? Colors.grey : Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Text(
            text,
            style: TextStyle(
                color: isFollowing ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13 *
                    curScaleFactor *
                    MediaQuery.of(context).size.height *
                    0.002),
          ),
        ),
      ),
    );
  }

  buildProfileButton() {
    // viewing your own profile - should show edit profile button
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(text: "Edit Profile", function: editProfile);
    } else if (isFollowing) {
      return buildButton(
        text: "Unfollow",
        function: handleUnfollowUser,
      );
    } else if (!isFollowing) {
      return buildButton(
        text: "Follow",
        function: handleFollowUser,
      );
    }
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
    });
    // remove follower
    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // remove following
    followingRef
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete activity feed item for them
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
    });
    // Make auth user follower of THAT user (update THEIR followers collection)
    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .set({});
    // Put THAT user on YOUR following collection (update your following collection)
    followingRef
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .set({});
    // add activity feed item for that user to notify about new follower (us)
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .set({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": currentUser!.username,
      "userId": currentUserId,
      "userProfileImg": currentUser!.photoUrl,
      "timestamp": timestamp,
    });
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.doc(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data as DocumentSnapshot);
        //snapshot.data.docs
        final curScaleFactor = MediaQuery.of(context).textScaleFactor;
        return Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.02),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", followerCount),
                            buildCountColumn("following", followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfileButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.02),
                child: Text(
                  user.username != null ? user.username : " ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0 *
                        curScaleFactor *
                        MediaQuery.of(context).size.height *
                        0.002,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.002),
                child: Text(
                  user.displayName != null ? user.displayName : "",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.0 *
                        curScaleFactor *
                        MediaQuery.of(context).size.height *
                        0.002,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.003),
                child: Text(
                  user.bio != null ? user.bio : ' ',
                  style: TextStyle(
                    fontSize: 12.0 *
                        curScaleFactor *
                        MediaQuery.of(context).size.height *
                        0.002,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'images/no_content.jpg',
              height: MediaQuery.of(context).size.height * 0.5,
            ),
            Padding(
              padding: EdgeInsets.only(top: 1.0),
              child: Text(
                "No Posts",
                style: TextStyle(
                  color: Theme.of(context).accentColor,
                  fontSize: 30.0 *
                      curScaleFactor *
                      MediaQuery.of(context).size.height *
                      0.002,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (postOrientation == "grid") {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == "list") {
      return Column(
        children: posts,
      );
    }
  }

  setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () => setPostOrientation("grid"),
          icon: Icon(
            Icons.grid_on,
            size: 35,
          ),
          color: postOrientation == 'grid'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        IconButton(
          onPressed: () => setPostOrientation("list"),
          icon: Icon(
            Icons.list,
            size: 35,
          ),
          color: postOrientation == 'list'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      endDrawer: Drawer(
        child: ListView(
          children: [
            Container(
              height: 180.0,
              child: DrawerHeader(
                // decoration: BoxDecoration(color: Colors.white),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey,
                  child: ClipOval(
                    child: Image.network(
                      currentUser!.photoUrl,
                      // fit: BoxFit.scaleDown,
                      fit: BoxFit.cover,
                      height: 150,
                      width: 150,
                    ),
                  ),
                ),
                /* child: Container(
                  height: 25,
                  // MediaQuery.of(context).size.height * 0.2,
                  child: CircleAvatar(
                    backgroundColor: Colors.grey,
                    backgroundImage:
                        CachedNetworkImageProvider(currentUser!.photoUrl),
                  ),
                ),*/
              ),
            ),
            CheckboxListTile(
                title: Text(
                  "Dark Mode",
                  style: TextStyle(
                      fontSize:
                          15 * MediaQuery.of(context).size.height * 0.002),
                ),
                value: themeChange.darkTheme,
                onChanged: (bool? value) {
                  themeChange.darkTheme = value!;
                }),
            SizedBox(height: 20),
            //  GestureDetector(
            ///  onTap: () {
            // PersonalExpenses();
            // },
            // child: Text(
            // "  Personal Expenses",
            // style: TextStyle(
            //   fontSize: 15 * MediaQuery.of(context).size.height * 0.002,
            // fontWeight: FontWeight.bold),
            // ),
            //)
          ],
        ),
      ),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts(),
        ],
      ),
    );
  }
}
