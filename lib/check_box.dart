import 'package:flutter/material.dart';

class CheckBoxEx extends StatefulWidget {
  const CheckBoxEx({Key? key}) : super(key: key);

  @override
  State<CheckBoxEx> createState() => _CheckBoxExState();
}

class _CheckBoxExState extends State<CheckBoxEx> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('_CheckBoxExState'),
      ),
      body: Center(
        child: Checkbox(
          checkColor: Colors.white,
          value: isChecked,
          onChanged: (bool? value) {
            setState(() {
              isChecked = value!;
            });
          },
        ),
      ),
    );
  }
}
