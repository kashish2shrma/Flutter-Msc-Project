import 'package:flutter/material.dart';

Container circularProgress() {
  return Container(
      alignment: Alignment.center,
      //height:30 ,
      //width: 30,
      padding: const EdgeInsets.only(top: 10.0),
      child: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.purple),
      ));
}

Container linearProgress() {
  return Container(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: const LinearProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.purple),
    ),
  );
}
