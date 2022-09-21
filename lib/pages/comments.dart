import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ruh_b_ru/pages/home.dart';
import 'package:ruh_b_ru/widgets/header.dart';
import 'package:ruh_b_ru/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({
    required this.postId,
    required this.postOwnerId,
    required this.postMediaUrl,
  });

  @override
  CommentsState createState() => CommentsState(
        postId: this.postId,
        postOwnerId: this.postOwnerId,
        postMediaUrl: this.postMediaUrl,
      );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  CommentsState({
    required this.postId,
    required this.postOwnerId,
    required this.postMediaUrl,
  });

  buildComments() {
    return StreamBuilder<QuerySnapshot>(
        stream: commentsRef
            .doc(postId)
            .collection('comments')
            .orderBy("timestamp", descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<Comment> comments = [];
          (snapshot.data!).docs.forEach((doc) {
            comments.add(Comment.fromDocument(doc));
          });
          return ListView(
            children: comments,
          );
        });
  }

  addComment() {
    commentsRef.doc(postId).collection("comments").add({
      "username": currentUser!.username,
      "comment": commentController.text,
      "timestamp": timestamp,
      "avatarUrl": currentUser!.photoUrl,
      "userId": currentUser!.id,
    });
    bool isNotPostOwner = postOwnerId != currentUser!.id;
    if (isNotPostOwner) {
      activityFeedRef.doc(postOwnerId).collection('feedItems').add({
        "type": "comment",
        "commentData": commentController.text,
        "timestamp": timestamp,
        "postId": postId,
        "userId": currentUser!.id,
        "username": currentUser!.username,
        "userProfileImg": currentUser!.photoUrl,
        "mediaUrl": postMediaUrl,
      });
    }
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(
                  labelText: "Write a comment...",
                  labelStyle: TextStyle(
                      fontSize: 15 *
                          MediaQuery.of(context).size.height *
                          0.002 *
                          curScaleFactor)),
            ),
            trailing: OutlinedButton(
              onPressed: addComment,
              child: Text("Post",
                  style: TextStyle(
                      fontSize: 15 *
                          MediaQuery.of(context).size.height *
                          0.002 *
                          curScaleFactor)),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment({
    required this.username,
    required this.userId,
    required this.avatarUrl,
    required this.comment,
    required this.timestamp,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment,
              style: TextStyle(
                  fontSize: 15 *
                      MediaQuery.of(context).size.height *
                      0.002 *
                      curScaleFactor)),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
            radius: 25,
          ),
          subtitle: Text(timeago.format(timestamp.toDate()),
              style: TextStyle(
                  fontSize: 13 *
                      MediaQuery.of(context).size.height *
                      0.002 *
                      curScaleFactor)),
        ),
        Divider(),
      ],
    );
  }
}
