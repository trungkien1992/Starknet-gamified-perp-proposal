import 'package:flutter/material.dart';

void main() => runApp(const StreetCredApp());

class StreetCredApp extends StatelessWidget {
  const StreetCredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('StreetCred Demo')),
        body: const Center(child: SwipeBar()),
      ),
    );
  }
}

class SwipeBar extends StatefulWidget {
  const SwipeBar({super.key});

  @override
  State<SwipeBar> createState() => _SwipeBarState();
}

class _SwipeBarState extends State<SwipeBar> {
  double _position = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _position += details.delta.dx;
        });
      },
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
        ),
        alignment: Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(left: _position.clamp(0, MediaQuery.of(context).size.width - 50)),
          width: 50,
          height: 50,
          color: Colors.white,
        ),
      ),
    );
  }
}
