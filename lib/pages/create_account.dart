import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ruh_b_ru/widgets/header.dart';

import '../widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  late String? username;

  submit() {
    final form = _formKey.currentState;

    if (form!.validate()) {
      form.save();
      SnackBar snackbar = SnackBar(content: Text("Welcome $username!"));
      _scaffoldKey.currentState?.showSnackBar(snackbar);
      Timer(Duration(seconds: 2), () {
        Navigator.pop(context, username);
      });
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context,
          titleText: "Set up your profile", removeBackButton: true),
      body: ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.05),
                  child: Center(
                    child: Text(
                      "Create a username",
                      style: TextStyle(
                          fontSize: 25.0 *
                              curScaleFactor *
                              MediaQuery.of(context).size.height *
                              0.002),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.height * 0.03),
                  child: Container(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.always,
                      child: TextFormField(
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "This field is required";
                          }
                          if (val.trim().length < 3) {
                            return "Username too short";
                          } else if (val.trim().length > 12) {
                            return "Username too long";
                          } else {
                            return null;
                          }
                        },
                        onSaved: (val) => username = val,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Username",
                            labelStyle: TextStyle(
                                fontSize: 19.0 *
                                    MediaQuery.of(context).size.height *
                                    0.002 *
                                    curScaleFactor),
                            hintText: "Must be at least 3 characters",
                            errorStyle: TextStyle(
                              color: Colors.red[400],
                              fontSize: 13 *
                                  MediaQuery.of(context).size.height *
                                  0.002 *
                                  curScaleFactor,
                            )),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: submit,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.09,
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                    child: Center(
                      child: Text(
                        "Submit",
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18.0 *
                                curScaleFactor *
                                MediaQuery.of(context).size.height *
                                0.002,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
