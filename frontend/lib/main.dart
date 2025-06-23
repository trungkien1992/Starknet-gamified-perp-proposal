import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

final inkProvider = StreamProvider<int>((ref) async* {
  final channel = WebSocketChannel.connect(
    Uri.parse('ws://localhost:3000/ws/ink'),
    pingInterval: const Duration(seconds: 25),
  );
  await for (final msg in channel.stream) {
    final delta = jsonDecode(msg)['ink_delta'] as int;
    yield delta;
  }
});

class _InkTotal extends StateNotifier<int> {
  _InkTotal() : super(0);
  void add(int delta) => state += delta;
}

final totalInkProvider = StateNotifierProvider<_InkTotal, int>((ref) {
  final notifier = _InkTotal();
  ref.listen<AsyncValue<int>>(inkProvider, (_, next) {
    next.whenData(notifier.add);
  });
  return notifier;
});

void main() => runApp(const ProviderScope(child: StreetCredApp()));

class StreetCredApp extends StatelessWidget {
  const StreetCredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('StreetCred Demo')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer(
              builder: (context, ref, _) {
                final ink = ref.watch(totalInkProvider);
                return Text('Ink: $ink');
              },
            ),
            const SizedBox(height: 20),
            const Expanded(child: Center(child: SwipeBar())),
          ],
        ),
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

  Future<void> _sendTrade(int dir) async {
    final body = jsonEncode({
      'user': '0xabc',
      'asset': 'BTC',
      'dir': dir,
      'lev': 3,
    });
    await http.post(
      Uri.parse('http://localhost:3000/trades/open'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _position -= details.delta.dy;
          _position = _position.clamp(0, height - 50);
        });
      },
      onVerticalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dy < -100) {
          _sendTrade(1);
        } else if (details.velocity.pixelsPerSecond.dy > 100) {
          _sendTrade(-1);
        }
      },
      child: Container(
        width: 50,
        height: double.infinity,
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
