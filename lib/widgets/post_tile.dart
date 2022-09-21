import 'package:flutter/material.dart';
import 'package:ruh_b_ru/pages/post_screen.dart';
import 'package:ruh_b_ru/widgets/custom_images.dart';
import 'package:ruh_b_ru/widgets/post.dart';
import 'package:ruh_b_ru/pages/activity_feed.dart';

class PostTile extends StatelessWidget {
  final Post post;

  PostTile(this.post);

  showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: post.postId,
          userId: post.ownerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPost(context),
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}
