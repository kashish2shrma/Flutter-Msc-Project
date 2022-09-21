import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:ruh_b_ru/models/user.dart';
import 'package:ruh_b_ru/pages/home.dart';
import 'package:ruh_b_ru/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String? currentUserId;

  EditProfile({required this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  User? user;
  bool _displayNameValid = true;
  bool _bioValid = true;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.doc(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user!.displayName;
    bioController.text = user!.bio;
    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayNameField() {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              "Display Name",
              style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14 *
                      curScaleFactor *
                      MediaQuery.of(context).size.height *
                      0.002),
            )),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            errorText: _displayNameValid ? null : "Display Name too short",
            errorStyle: TextStyle(
                fontSize: 12 *
                    curScaleFactor *
                    MediaQuery.of(context).size.height *
                    0.002),
            hintText: "Update Display Name",
            hintStyle: TextStyle(
                fontSize: 15 *
                    curScaleFactor *
                    MediaQuery.of(context).size.height *
                    0.002),
          ),
        )
      ],
    );
  }

  Column buildBioField() {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              "Bio",
              style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 15 *
                      curScaleFactor *
                      MediaQuery.of(context).size.height *
                      0.002),
            )),
        TextField(
          autocorrect: true,
          controller: bioController,
          decoration: InputDecoration(
            errorText: _bioValid ? null : "Bio too long",
            errorStyle: TextStyle(
                fontSize: 12 *
                    curScaleFactor *
                    MediaQuery.of(context).size.height *
                    0.002),
            hintText: "Update Bio",
            hintStyle: TextStyle(
              fontSize: 14 *
                  curScaleFactor *
                  MediaQuery.of(context).size.height *
                  0.002,
            ),
          ),
        )
      ],
    );
  }

  updateProfileData() {
    setState(() {
      displayNameController.text.trim().length < 4 ||
              displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;
      bioController.text.trim().length > 100
          ? _bioValid = false
          : _bioValid = true;
    });

    if (_displayNameValid && _bioValid) {
      usersRef.doc(widget.currentUserId).update({
        "displayName": displayNameController.text,
        "bio": bioController.text,
      });
      SnackBar snackbar = SnackBar(content: Text("Profile updated!"));
      _scaffoldKey.currentState?.showSnackBar(snackbar);
    }
  }

  logout() async {
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  @override
  Widget build(BuildContext context) {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Container(
          alignment: Alignment.center,
          child: Text(
            "Edit Profile",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.black,
                fontSize: 18 *
                    curScaleFactor *
                    MediaQuery.of(context).size.height *
                    0.002),
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.done,
              size: 35.0,
              color: Colors.green,
            ),
          ),
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.04,
                          bottom: MediaQuery.of(context).size.height * 0.01,
                        ),
                        child: CircleAvatar(
                          radius: 70.0,
                          backgroundImage:
                              CachedNetworkImageProvider(user!.photoUrl),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.height * 0.03),
                        child: Column(
                          children: <Widget>[
                            buildDisplayNameField(),
                            buildBioField(),
                          ],
                        ),
                      ),
                      RaisedButton(
                        onPressed: updateProfileData,
                        child: Text(
                          "Update Profile",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 20.0 *
                                MediaQuery.of(context).size.height *
                                0.002 *
                                curScaleFactor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.height * 0.02),
                        child: FlatButton.icon(
                          onPressed: logout,
                          icon: Icon(Icons.cancel, color: Colors.red),
                          label: Text(
                            "Logout",
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 18.0 *
                                    curScaleFactor *
                                    MediaQuery.of(context).size.height *
                                    0.002),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
