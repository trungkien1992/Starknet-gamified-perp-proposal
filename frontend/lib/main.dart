import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

const _apiBase = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000');
const _inkWs = String.fromEnvironment('INK_WS_URL', defaultValue: 'ws://localhost:3000/ws/ink');
const _rewardWs = String.fromEnvironment('REWARD_WS_URL', defaultValue: 'ws://localhost:3000/ws/rewards');

final inkProvider = StreamProvider.autoDispose<int>((ref) async* {
  final uri = Uri.parse(_inkWs);
  while (true) {
    final channel = WebSocketChannel.connect(uri, pingInterval: const Duration(seconds: 25));
    ref.onDispose(() => channel.sink.close());
    try {
      await for (final msg in channel.stream) {
        try {
          final data = jsonDecode(msg);
          if (data is Map && data['ink_delta'] is int) {
            yield data['ink_delta'] as int;
          }
        } catch (_) {
          // ignore parse errors
        }
      }
    } catch (_) {
      // connection closed; retry
    }
    await Future.delayed(const Duration(seconds: 1));
  }
});

final rewardProvider = StreamProvider.autoDispose<String>((ref) async* {
  final uri = Uri.parse(_rewardWs);
  while (true) {
    final channel = WebSocketChannel.connect(uri, pingInterval: const Duration(seconds: 25));
    ref.onDispose(() => channel.sink.close());
    try {
      await for (final msg in channel.stream) {
        try {
          final data = jsonDecode(msg);
          if (data is Map && data['kind'] is String) {
            yield data['kind'] as String;
          }
        } catch (_) {
          // ignore parse errors
        }
      }
    } catch (_) {
      // connection closed; retry
    }
    await Future.delayed(const Duration(seconds: 1));
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
        body: Stack(
          children: [
            Column(
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
            const RewardListener(),
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
  double _dragTotal = 0;
  String userWallet = '0xabc';
  String selectedAsset = 'BTC';
  int leverage = 1;

  Future<void> _sendTrade(int dir) async {
    final body = jsonEncode({
      'user':   userWallet,
      'asset':  selectedAsset,
      'dir': dir,
      'lev':    leverage,
    });
    await http.post(
      Uri.parse('$_apiBase/trades/open'),
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
          _dragTotal -= details.delta.dy;
          _dragTotal = _dragTotal.clamp(0, height - 50);
          final t = (_dragTotal / (height - 50)).clamp(0.0, 1.0);
          final mapped = kIsWeb ? (1 + 9 * t) : ui.lerpDouble(1, 10, t)!;
          leverage = mapped.round();
        });
      },
      onVerticalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dy < -100) {
          _sendTrade(1);
        } else if (details.velocity.pixelsPerSecond.dy > 100) {
          _sendTrade(-1);
        }
        setState(() {
          _dragTotal = 0;
        });
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

class RewardListener extends ConsumerStatefulWidget {
  const RewardListener({super.key});

  @override
  ConsumerState<RewardListener> createState() => _RewardListenerState();
}

class _RewardListenerState extends ConsumerState<RewardListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AsyncValue<String>>(rewardProvider, (prev, next) {
        next.whenData((kind) {
          _showBurst(kind);
        });
      });
    });
  }

  Future<void> _showBurst(String kind) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BurstModal(kind: kind),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _BurstModal extends StatelessWidget {
  const _BurstModal({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Text('Reward unlocked: $kind'),
    );
  }
}
