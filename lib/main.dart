import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late PermissionStatus _galleyPermissionStatus;
  final picker = ImagePicker();
  File? galleryFile;
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);
  String imageRecognizedText = '';

  @override
  void initState() {
    super.initState();
    _requestGalleryPermission();
  }

  @override
  void dispose() {
    super.dispose();
    textRecognizer.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Get Infrastructure Cost'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              galleryFile == null
                  ? const Text('ここに解析結果が表示されるよ！')
                  : Text(imageRecognizedText),
              SizedBox(
                height: 200.0,
                width: 200.0,
                child: galleryFile == null
                    ? const Center(child: Text('画像を選んでね！'))
                    : Center(child: Image.file(galleryFile!)),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                ),
                onPressed: () {
                  _getImageFile();
                },
                child: const Text('Upload Photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _requestGalleryPermission() async {
    late PermissionStatus status;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        status = await Permission.storage.request();
      } else {
        status = await Permission.photos.request();
      }

      setState(() {
        _galleyPermissionStatus = status;
      });
    }
  }

  void _getImageFile() async {
    if (_galleyPermissionStatus == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }
    if (_galleyPermissionStatus == PermissionStatus.granted) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      setState(() {
        if (pickedFile != null) {
          galleryFile = File(pickedFile.path);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('画像を選んでください')));
        }
      });
      _getRecognizedText();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ストレージへのアクセス権限を付与してください')));
    }
  }

  void _getRecognizedText() async {
    if (galleryFile != null) {
      final inputImage = InputImage.fromFile(galleryFile!);
      final recognizedText = await textRecognizer.processImage(inputImage);
      setState(() {
        imageRecognizedText = recognizedText.text;
      });
    }
  }
}
