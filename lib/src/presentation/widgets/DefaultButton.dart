import 'package:flutter/material.dart';

class DefaultButton extends StatelessWidget {

  final String text;
  final Function() onPressed;
  final Color color;
  final Color? colorText;

  const DefaultButton({super.key, 
    required this.text,
    required this.onPressed,
    this.color = Colors.black,
    this.colorText = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 55,
      child: ElevatedButton(
        onPressed: () {
         onPressed();
        }, 
        style: ElevatedButton.styleFrom(
          backgroundColor: color
        ),
        child: Text(
          text,
          style: TextStyle(
            color: colorText
          ),
        ),
      ),
    );
  }
}