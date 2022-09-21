import 'package:flutter/material.dart';

AppBar header(context,
    {bool isAppTitle = false,
    required String titleText,
    removeBackButton = false}) {
  final curScaleFactor = MediaQuery.of(context).textScaleFactor;
  return AppBar(
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(
      isAppTitle ? "Ruh-B-Ru" : titleText,
      style: TextStyle(
        color: Colors.white,
        fontFamily: isAppTitle ? "Signatra" : "",
        fontSize: isAppTitle
            ? 45.0 * curScaleFactor * MediaQuery.of(context).size.height * 0.002
            : 35.0 *
                curScaleFactor *
                MediaQuery.of(context).size.height *
                0.001,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
