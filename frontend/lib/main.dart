import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

final inkBalanceProvider = StateNotifierProvider<InkNotifier, int>((ref) {
  return InkNotifier();
});

class InkNotifier extends StateNotifier<int> {
  InkNotifier() : super(0) {
    final channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:3000/ws/ink'),
    );
    channel.stream.listen((event) {
      final data = jsonDecode(event);
      state += data['ink_delta'] as int;
      // ignore: avoid_print
      print('ink balance: $state');
    });
  }
}

void main() => runApp(const ProviderScope(child: StreetCredApp()));

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

class SwipeBar extends ConsumerStatefulWidget {
  const SwipeBar({super.key});

  @override
  ConsumerState<SwipeBar> createState() => _SwipeBarState();
}

class _SwipeBarState extends ConsumerState<SwipeBar> {
  double _position = 150;
  static const double _height = 200;

  Future<void> _openTrade() async {
    final res = await http.post(
      Uri.parse('http://localhost:3000/trades/open'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'lev': 3, 'asset': 'BTC', 'dir': 'long'}),
    );
    // ignore: avoid_print
    print(res.body);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(inkBalanceProvider);
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _position -= details.delta.dy;
          _position = _position.clamp(0, _height - 50);
        });
      },
      onVerticalDragEnd: (_) {
        if (_position <= 0) {
          _openTrade();
          setState(() => _position = _height - 50);
        }
      },
      child: Container(
        width: 50,
        height: _height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue, Colors.purple], begin: Alignment.bottomCenter, end: Alignment.topCenter),
        ),
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.only(bottom: _position),
          width: 50,
          height: 50,
          color: Colors.white,
        ),
      ),
    );
  }
}
