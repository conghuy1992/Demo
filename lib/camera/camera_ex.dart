import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class PickImage extends StatefulWidget {
  const PickImage({Key? key}) : super(key: key);

  @override
  State<PickImage> createState() => _PickImageState();
}

class _PickImageState extends State<PickImage> {
  CroppedFile? _croppedFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Image'),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    _onPressed() async {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TakePictureScreen(onCroppedFile: (croppedFile) {
            setState(() {
              _croppedFile = croppedFile;
            });
          }),
        ),
      );
    }

    _buildImage() {
      if (_croppedFile != null) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: _image(),
              ),
            ),
          ),
        );
      }
      return Text('no image');
    }

    return Center(
      child: Column(
        children: [
          _buildImage(),
          SizedBox(
            width: 150,
            child: ElevatedButton.icon(
              //image capture button
              onPressed: _onPressed,
              icon: Icon(Icons.camera),
              label: Text("Capture"),
            ),
          ),
          SizedBox(
            width: 150,
            child: ElevatedButton.icon(
              onPressed: () async {
                final pickedFile = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (pickedFile == null) return;
                _cropImage(
                  pickedFile: pickedFile,
                  onCroppedFile: (croppedFile) {
                    setState(() {
                      _croppedFile = croppedFile;
                    });
                  },
                );
              },
              icon: Icon(Icons.photo),
              label: Text("Photo"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _image() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final path = _croppedFile!.path;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 0.8 * screenWidth,
        maxHeight: 0.7 * screenHeight,
      ),
      child: Image.file(File(path)),
    );
  }
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final Function(CroppedFile?)? onCroppedFile;

  const TakePictureScreen({
    Key? key,
    required this.onCroppedFile,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  loadCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );
    return _controller.initialize();
  }

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = loadCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _body();
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _body() {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CameraPreview(_controller),
        ),
        Positioned(
          bottom: 20.0,
          right: 0.0,
          left: 0.0,
          child: FloatingActionButton(
            heroTag: null,
            onPressed: () async {
              try {
                await _initializeControllerFuture;
                final image = await _controller.takePicture();
                if (!mounted) return;
                _cropImage(
                    pickedFile: image,
                    onCroppedFile: (c) {
                      Navigator.pop(context);
                      widget.onCroppedFile?.call(c);
                    });
              } catch (e) {
                print(e);
              }
            },
            backgroundColor: Colors.redAccent,
            tooltip: 'camera',
            child: const Icon(Icons.camera),
          ),
        ),
        Positioned(
          left: 20.0,
          top: 35.0,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.clear,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _cropImage({
  XFile? pickedFile,
  Function(CroppedFile?)? onCroppedFile,
}) async {
  if (pickedFile != null) {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        ),
      ],
    );
    onCroppedFile?.call(croppedFile);
  }
}
