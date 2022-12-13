import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

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
      dynamic croppedFile = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TakePictureScreen(),
        ),
      );
      if (croppedFile != null) {
        setState(() {
          _croppedFile = croppedFile;
        });
      }
    }

    if (_croppedFile != null) {
      return Center(
        child: InkWell(
          onTap: _onPressed,
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
        ),
      );
    }
    return Center(
      child: ElevatedButton.icon(
        //image capture button
        onPressed: _onPressed,
        icon: Icon(Icons.camera),
        label: Text("Capture"),
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
  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  XFile? xFile;

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
    if (xFile == null) {
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
              onPressed: () async {
                try {
                  await _initializeControllerFuture;
                  final image = await _controller.takePicture();
                  if (!mounted) return;

                  setState(() {
                    xFile = image;
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
    return DisplayPictureScreen(
      pickedFile: xFile,
    );
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final XFile? pickedFile;

  const DisplayPictureScreen({
    Key? key,
    required this.pickedFile,
  }) : super(key: key);

  @override
  _DisplayPictureScreen createState() => _DisplayPictureScreen();
}

class _DisplayPictureScreen extends State<DisplayPictureScreen> {
  XFile? _pickedFile;
  CroppedFile? _croppedFile;

  @override
  void initState() {
    _pickedFile = widget.pickedFile;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('title')),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_croppedFile != null || _pickedFile != null) {
      return _imageCard();
    } else {
      return TakePictureScreen();
    }
  }

  Widget _imageCard() {
    return  Stack(
      children: [
        _image(),
        const SizedBox(height: 24.0),
        Positioned(
          bottom: 20.0,
          right: 0.0,
          left: 0.0,
          child: _menu(),
        ),
      ],
    );
  }

  Widget _image() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    if (_croppedFile != null) {
      final path = _croppedFile!.path;
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
      );
    } else if (_pickedFile != null) {
      final path = _pickedFile!.path;
      return Image.file(File(path));
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _menu() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: () {
            _clear();
          },
          backgroundColor: Colors.redAccent,
          tooltip: 'Delete',
          child: const Icon(Icons.delete),
        ),
        if (_croppedFile == null)
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: FloatingActionButton(
              onPressed: () {
                _cropImage();
              },
              backgroundColor: const Color(0xFFBC764A),
              tooltip: 'Crop',
              child: const Icon(Icons.crop),
            ),
          )
      ],
    );
  }

  Future<void> _cropImage() async {
    if (_pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _pickedFile!.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
        ],
      );
      Navigator.pop(context, croppedFile);
    }
  }

  void _clear() {
    setState(() {
      _pickedFile = null;
      _croppedFile = null;
    });
  }
}
