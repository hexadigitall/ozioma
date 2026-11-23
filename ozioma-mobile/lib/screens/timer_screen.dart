import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../core/database/database_providers.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  Timer? _ticker;
  int _secondsElapsed = 0;
  bool _isRunning = false;

  void _toggleTimer() {
    if (_isRunning) {
      _ticker?.cancel();
      setState(() => _isRunning = false);
    } else {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _secondsElapsed++);
      });
      setState(() => _isRunning = true);
    }
  }

  void _resetTimer() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _secondsElapsed = 0;
    });
  }

  Future<void> _logAndSaveSession() async {
    if (_secondsElapsed == 0) return;
    final logDao = ref.read(serviceLogDaoProvider);
    final duration = Duration(seconds: _secondsElapsed);

    await logDao.logSession(
      userId: 'publisher_me',
      date: DateTime.now(),
      duration: duration,
    );

    _resetTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session saved: ${duration.inMinutes} minutes logged to monthly S-4')),
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = (_secondsElapsed ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_secondsElapsed % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Service Timer'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$hours:$minutes:$seconds',
                style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, fontFeatures: []),
              ),
              const SizedBox(height: 8),
              Text(
                _isRunning ? 'Logging Ministry Time...' : 'Timer Paused',
                style: TextStyle(color: _isRunning ? const Color(0xFF10B981) : Colors.grey, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    iconSize: 32,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reset',
                    onPressed: _secondsElapsed > 0 ? _resetTimer : null,
                  ),
                  const SizedBox(width: 24),
                  IconButton.filled(
                    iconSize: 48,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    tooltip: _isRunning ? 'Pause' : 'Start',
                    onPressed: _toggleTimer,
                  ),
                  const SizedBox(width: 24),
                  IconButton.filledTonal(
                    iconSize: 32,
                    icon: const Icon(Icons.save),
                    tooltip: 'Save Session',
                    onPressed: _secondsElapsed > 0 ? _logAndSaveSession : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
