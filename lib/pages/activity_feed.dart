import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ruh_b_ru/pages/home.dart';
import 'package:ruh_b_ru/pages/post_screen.dart';
import 'package:ruh_b_ru/pages/profile.dart';
import 'package:ruh_b_ru/widgets/header.dart';
import 'package:ruh_b_ru/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
      appBar: header(context, titleText: "Activity Feed"),
      body: Container(
          child: StreamBuilder<QuerySnapshot>(
        stream: activityFeedRef
            .doc(currentUser?.id)
            .collection('feedItems')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }

          List<ActivityFeedItem> feedItems = [];
          (snapshot.data!).docs.forEach((doc) {
            feedItems.add(ActivityFeedItem.fromDocument(doc));
          });
          return ListView(
            children: feedItems,
          );
        },
      )),
    );
  }
}

Widget? mediaPreview;
String? activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type; // 'like', 'follow', 'comment'
  final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;

  ActivityFeedItem({
    required this.username,
    required this.userId,
    required this.type,
    required this.mediaUrl,
    required this.postId,
    required this.userProfileImg,
    required this.commentData,
    required this.timestamp,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username:
          doc.data().toString().contains('username') ? doc.get('username') : '',
      userId: doc.data().toString().contains('userId') ? doc.get('userId') : '',
      type: doc.data().toString().contains('type') ? doc.get('type') : '',
      postId: doc.data().toString().contains('postId') ? doc.get('postId') : '',
      userProfileImg: doc.data().toString().contains('userProfileImg')
          ? doc.get('userProfileImg')
          : '',
      commentData: doc.data().toString().contains('commentData')
          ? doc.get('commentData')
          : '',
      timestamp: doc.data().toString().contains('timestamp')
          ? doc.get('timestamp')
          : '',
      mediaUrl:
          doc.data().toString().contains('mediaUrl') ? doc.get('mediaUrl') : '',
    );
  }

  showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: postId,
          userId: userId,
        ),
      ),
    );
  }

  configureMediaPreview(context) {
    if (type == "like" || type == 'comment') {
      mediaPreview = GestureDetector(
        onTap: () => showPost(context),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: CachedNetworkImageProvider(mediaUrl),
                  ),
                ),
              )),
        ),
      );
    } else {
      mediaPreview = Text('');
    }

    if (type == 'like') {
      activityItemText = "liked your post";
    } else if (type == 'follow') {
      activityItemText = "is following you";
    } else if (type == 'comment') {
      activityItemText = 'replied: $commentData';
    } else {
      activityItemText = "Error: Unknown type '$type'";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Theme.of(context).primaryColor.withOpacity(0.9),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.0 *
                        curScaleFactor *
                        MediaQuery.of(context).size.height *
                        0.002,
                  ),
                  children: [
                    TextSpan(
                      text: username,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' $activityItemText',
                    ),
                  ]),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(
              userProfileImg,
            ),
            radius: 25,
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.0 *
                  curScaleFactor *
                  MediaQuery.of(context).size.height *
                  0.002,
            ),
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}

showProfile(BuildContext context, {required String profileId}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Profile(
        profileId: profileId,
      ),
    ),
  );
}
