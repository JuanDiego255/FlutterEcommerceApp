import 'package:flutter/material.dart';

class DefaultIconBack extends StatelessWidget {

  final double left;
  final double top;
  final Color color;

  const DefaultIconBack({super.key, 
    required this.left,
    required this.top,
    this.color = Colors.white
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.only(left: left, top: top),
      child: IconButton(
        onPressed: () { Navigator.pop(context); },               
        icon: Icon(
          Icons.arrow_back_ios,
          size: 35,
          color: color,
        )
      ),
    );
  }
}