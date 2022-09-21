import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ruh_b_ru/models/user.dart';
import 'package:ruh_b_ru/pages/home.dart';
import 'package:ruh_b_ru/widgets/progress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  User? currentUser;

  Upload({required this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  Position? currentPosition;
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  XFile? file;
  bool isUploading = false;
  String postId = Uuid().v4();
  String currentAddress = "";

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen() : buildUploadForm();
  }

  Future<XFile?> handleTakePhoto() async {
    Navigator.pop(context);
    return await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
  }

  Future<XFile?> handleChooseFromGallery() async {
    Navigator.pop(context);
    return await ImagePicker().pickImage(source: ImageSource.gallery);
  }

  selectImage(parentContext) {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text(
            "Create Post",
            style: TextStyle(
                fontSize: 18 *
                    curScaleFactor *
                    MediaQuery.of(context).size.height *
                    0.002,
                fontWeight: FontWeight.bold),
          ),
          children: <Widget>[
            SimpleDialogOption(
                onPressed: () async {
                  file = await handleTakePhoto();
                  if (file != null && file!.path.isNotEmpty) {
                    setState(() {});
                  }
                },
                child: Text(
                  "Photo with Camera",
                  style: TextStyle(
                    fontSize: 15 *
                        curScaleFactor *
                        MediaQuery.of(context).size.height *
                        0.002,
                  ),
                )),
            SimpleDialogOption(
                onPressed: () async {
                  file = await handleChooseFromGallery();
                  if (file != null && file!.path.isNotEmpty) {
                    setState(() {});
                  }
                },
                child: Text(
                  "Image from Gallery",
                  style: TextStyle(
                    fontSize: 15 *
                        curScaleFactor *
                        MediaQuery.of(context).size.height *
                        0.002,
                  ),
                )),
            SimpleDialogOption(
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontSize: 15 *
                      curScaleFactor *
                      MediaQuery.of(context).size.height *
                      0.002,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  Container buildSplashScreen() {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset('images/upload.jpg',
              height: MediaQuery.of(context).size.width * 0.8),
          Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.05),
            child: RaisedButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                color: Colors.deepOrange,
                onPressed: () => selectImage(context),
                child: Text(
                  "Upload Image",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.0 *
                          curScaleFactor *
                          MediaQuery.of(context).size.height *
                          0.002),
                )),
          ),
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(await file!.readAsBytes()) as Im.Image;
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytes(Im.encodeJpg(imageFile, quality: 85));
    setState(() {
      file = compressedImageFile as XFile?;
    });
  }

  Future<String> uploadImage(XFile? imageFile) async {
    Reference db = FirebaseStorage.instance.ref('_path/img_$postId.jpg');
    await db.putFile(File(imageFile!.path));
    return await db.getDownloadURL();
    //  UploadTask uploadTask =
    //    storageRef.child("post_$postId.jpg").putFile(imageFile);
    //TaskSnapshot storageSnap = await uploadTask.onComplete();

    // await storageSnap.ref.getDownloadURL();
    //String downloadUrl = await storageRef.getDownloadURL();
    //return downloadUrl;
  }

  createPostInFirestore(
      {required String mediaUrl,
      required String location,
      required String description}) {
    postsRef
        .doc(widget.currentUser!.id)
        .collection("userPosts")
        .doc(postId)
        .set({
      "postId": postId,
      "ownerId": widget.currentUser!.id,
      "username": widget.currentUser!.username,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": timestamp,
      "likes": {},
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    // await compressImage();
    // String mediaUrl =
    String mediaUrl = await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  getUserLocation() async {
    await Geolocator.requestPermission();

    Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            forceAndroidLocationManager: true)
        .then((Position position) {
      setState(() {
        currentPosition = position;
        _getAddressFromLatLng();
      });
    }).catchError((e) {
      print(e);
    });
    /* Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String completeAddress =
        '${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';
    print(completeAddress);
    String formattedAddress = "${placemark.locality}, ${placemark.country}";
    locationController.text = formattedAddress;*/
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          currentPosition!.latitude, currentPosition!.longitude);

      Placemark place = placemarks[0];

      setState(() {
        currentAddress = "${place.locality},  ${place.country}";
        locationController.text = currentAddress;
      });
    } catch (e) {
      print(e);
    }
  }

  Scaffold buildUploadForm() {
    final curScaleFactor = MediaQuery.of(context).textScaleFactor;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
              size: 35.0,
            ),
            onPressed: clearImage),
        title: Text(
          "Caption Post",
          style: TextStyle(
              color: Colors.black,
              fontSize: 15 *
                  curScaleFactor *
                  MediaQuery.of(context).size.height *
                  0.002),
        ),
        actions: [
          FlatButton(
            onPressed: () {
              handleSubmit();
            },
            //isUploading ? null :,
            child: Text(
              "Post",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 17.0 *
                    curScaleFactor *
                    MediaQuery.of(context).size.height *
                    0.002,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? linearProgress() : Text(""),
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Center(
              child: AspectRatio(
                aspectRatio: 35 / 45,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: FileImage(File(file!.path)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser!.photoUrl),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: "Write a caption...",
                  hintStyle: TextStyle(
                      fontSize: 18 *
                          curScaleFactor *
                          MediaQuery.of(context).size.height *
                          0.002),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35.0,
            ),
            title: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: "Where was this photo taken?",
                  hintStyle: TextStyle(
                      fontSize: 16 *
                          curScaleFactor *
                          MediaQuery.of(context).size.height *
                          0.0015),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.width * 0.3,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              label: Text(
                "Use Current Location",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 *
                        curScaleFactor *
                        MediaQuery.of(context).size.height *
                        0.002),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              color: Colors.blue,
              onPressed: getUserLocation,
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
