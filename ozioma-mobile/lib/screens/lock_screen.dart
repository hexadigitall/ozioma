import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../core/auth/biometric_auth_service.dart';
import '../core/database/database_providers.dart';

class LockScreen extends ConsumerStatefulWidget {
  final Widget child;
  final Duration autoLockTimeout;

  const LockScreen({
    super.key,
    required this.child,
    this.autoLockTimeout = const Duration(seconds: 30),
  });

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with WidgetsBindingObserver {
  late final BiometricAuthService _authService;
  bool _isUnlocked = false;
  DateTime? _pausedTime;
  String _pinBuffer = '';
  String? _errorMessage;
  Duration? _activeLockout;
  Timer? _lockoutCountdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authService = BiometricAuthService(
      keyManager: ref.read(secureKeyManagerProvider),
    );
    _checkInitialAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockoutCountdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null && _isUnlocked) {
        final elapsed = DateTime.now().difference(_pausedTime!);
        if (elapsed >= widget.autoLockTimeout) {
          // Auto-lock triggered by background inactivity
          ref.read(aesCipherProvider).clearMemory();
          setState(() {
            _isUnlocked = false;
            _pinBuffer = '';
            _errorMessage = 'Session locked due to inactivity';
          });
          _tryBiometricUnlock();
        }
      }
      _pausedTime = null;
    }
  }

  Future<void> _checkInitialAuth() async {
    final lockout = await _authService.checkLockoutDuration();
    if (lockout != null) {
      _startLockoutCountdown(lockout);
      return;
    }
    await _tryBiometricUnlock();
  }

  Future<void> _tryBiometricUnlock() async {
    final canBio = await _authService.canAuthenticateWithBiometrics();
    if (!canBio) return;

    final success = await _authService.authenticateWithBiometrics();
    if (success && mounted) {
      setState(() {
        _isUnlocked = true;
        _errorMessage = null;
        _pinBuffer = '';
      });
    }
  }

  void _onDigitPressed(String digit) {
    if (_activeLockout != null) return;
    if (_pinBuffer.length >= 6) return;

    setState(() {
      _pinBuffer += digit;
      _errorMessage = null;
    });

    if (_pinBuffer.length >= 4) {
      _submitPin();
    }
  }

  void _onDeletePressed() {
    if (_pinBuffer.isNotEmpty) {
      setState(() {
        _pinBuffer = _pinBuffer.substring(0, _pinBuffer.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _submitPin() async {
    final res = await _authService.verifyPin(_pinBuffer);

    if (!mounted) return;

    if (res.isSuccess) {
      setState(() {
        _isUnlocked = true;
        _pinBuffer = '';
        _errorMessage = null;
      });
    } else if (res.isDuress) {
      // Duress wipe activated
      ref.read(aesCipherProvider).clearMemory();
      setState(() {
        _pinBuffer = '';
        _errorMessage = 'Emergency security purge executed.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Security key purged. Local data locked.'),
        ),
      );
    } else if (res.lockoutDuration != null) {
      _startLockoutCountdown(res.lockoutDuration!);
    } else {
      setState(() {
        _pinBuffer = '';
        _errorMessage = res.remainingAttempts != null
            ? 'Incorrect PIN. ${res.remainingAttempts} attempts remaining.'
            : 'Incorrect PIN. Try again.';
      });
    }
  }

  void _startLockoutCountdown(Duration duration) {
    _lockoutCountdownTimer?.cancel();
    setState(() {
      _activeLockout = duration;
      _pinBuffer = '';
      _errorMessage = 'Too many failed attempts. Locked.';
    });

    _lockoutCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeLockout == null || _activeLockout!.inSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _activeLockout = null;
            _errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _activeLockout = Duration(seconds: _activeLockout!.inSeconds - 1);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  // Double tap to discreetly lock / stealth mode
                  GestureDetector(
                    onDoubleTap: () {
                      ref.read(aesCipherProvider).clearMemory();
                      setState(() => _errorMessage = 'Stealth Lock Active');
                    },
                    child: Container(
                      width: 78,
                      height: 78,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white10,
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.45)),
                      ),
                      child: Image.asset(
                        'assets/images/logo_mark.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.shield_outlined,
                          size: 40,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'OZIOMA FIELD SECURITY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Theocratic privacy & hardware keystore locked',
                    style: TextStyle(fontSize: 12, color: Colors.white60),
                  ),

                  const SizedBox(height: 24),

                  // PIN Dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final isFilled = i < _pinBuffer.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? const Color(0xFF10B981) : Colors.white24,
                          border: Border.all(
                            color: isFilled ? const Color(0xFF10B981) : Colors.white38,
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Error / Lockout countdown banner
                  if (_activeLockout != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Locked: ${_activeLockout!.inSeconds}s remaining',
                        style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    )
                  else if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Colors.amberAccent),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 20),

                  // Numeric PIN Pad
                  _buildKeypad(),

                  const SizedBox(height: 16),

                  // Biometric Trigger Button
                  TextButton.icon(
                    onPressed: _activeLockout == null ? _tryBiometricUnlock : null,
                    icon: const Icon(Icons.fingerprint, color: Color(0xFF10B981)),
                    label: const Text(
                      'Use Biometrics (Face ID / Fingerprint)',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((d) => _buildKeyBtn(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((d) => _buildKeyBtn(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((d) => _buildKeyBtn(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 64, height: 64),
            _buildKeyBtn('0'),
            SizedBox(
              width: 64,
              height: 64,
              child: IconButton(
                icon: const Icon(Icons.backspace_outlined, color: Colors.white70),
                onPressed: _onDeletePressed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyBtn(String digit) {
    return SizedBox(
      width: 64,
      height: 64,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: const BorderSide(color: Colors.white12),
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.04),
        ),
        onPressed: () => _onDigitPressed(digit),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
