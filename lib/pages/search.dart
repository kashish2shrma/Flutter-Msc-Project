import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ruh_b_ru/pages/activity_feed.dart';
import 'package:ruh_b_ru/pages/home.dart';
import 'package:ruh_b_ru/widgets/progress.dart';

import '../models/user.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot>? searchResultsFuture;

  handleSearch(String query) {
    Future<QuerySnapshot> users = usersRef
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThan: query + 'z')
        .get();

    //            OR bellow snippet also works fine

    //  Future<QuerySnapshot> users = usersRef
    //     .orderBy("displayName")
    //     .startAt([query]).endAt([query + '\uf8ff']).get();

    setState(() {
      searchResultsFuture = users;
    });
    //"displayName".toLowerCase().contains(query.toLowerCase())
  }

  clearSearch(context) {
    setState(() {
      searchController.clear();
    });
    // Navigator.push(context, MaterialPageRoute(builder: (context) => Search()));
    /*Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Search(),
      ),
    );*/
    // .then((value) {
    //This makes sure the textfield is cleared after page is pushed.
    //  searchController.clear();
    // });
    //setState(() {
    //  searchController.clear();
    // });
    //
  }

  AppBar buildSearchField(context) {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    final Orientation orientation = MediaQuery.of(context).orientation;
    return AppBar(
        backgroundColor: Colors.white,
        title: TextFormField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: "Search for a user...",
            hintStyle: TextStyle(
                fontSize: orientation == Orientation.portrait
                    ? 15 *
                        MediaQuery.of(context).size.height *
                        0.002 *
                        curScaleFactor
                    : 22.0 *
                        MediaQuery.of(context).size.height *
                        0.002 *
                        curScaleFactor),
            filled: true,
            prefixIcon: Icon(
              Icons.account_box,
              size: orientation == Orientation.portrait
                  ? MediaQuery.of(context).size.width * 0.1
                  : MediaQuery.of(context).size.width * 0.06,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.clear,
                size: orientation == Orientation.portrait
                    ? MediaQuery.of(context).size.width * 0.09
                    : MediaQuery.of(context).size.width * 0.05,
              ),
              onPressed: () => clearSearch(context),
            ),
          ),
          onFieldSubmitted: handleSearch,
        ));
  }

  Container buildNoContent(context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Image.asset(
              'images/search.jpg',
              height: orientation == Orientation.portrait
                  ? MediaQuery.of(context).size.width * 0.9
                  : MediaQuery.of(context).size.width * 0.3,
              // width: MediaQuery.of(context).size.width * 0.3,
            ),
            Text(
              "Find Users",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 50.0 *
                    MediaQuery.of(context).size.height *
                    0.002 *
                    curScaleFactor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildSearchResults() {
    return FutureBuilder<QuerySnapshot>(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data!.docs.forEach((doc) {
          User user = User.fromDocument(doc);
          UserResult searchResult = UserResult(user);
          searchResults.add(searchResult);
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
      appBar: buildSearchField(context),
      body: searchResultsFuture == null
          ? buildNoContent(context)
          : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                radius: 30.0,
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(
                user.displayName == null ? "no user found" : user.displayName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18 *
                      curScaleFactor *
                      MediaQuery.of(context).size.height *
                      0.002,
                ),
              ),
              subtitle: Text(
                user.username == null ? "no user found" : user.username,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14 *
                      curScaleFactor *
                      MediaQuery.of(context).size.height *
                      0.002,
                ),
              ),
            ),
          ),
          Divider(
            color: Colors.white54,
            height: 2.0,
            thickness: 5.0,
          ),
        ],
      ),
    );
  }
}
