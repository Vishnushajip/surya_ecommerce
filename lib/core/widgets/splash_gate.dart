import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../personalization/splash/view/splash_view.dart';

class SplashGate extends StatefulWidget {
  final Widget child;
  const SplashGate({super.key, required this.child});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fadeOut;
  bool _hide = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeOut = CurvedAnimation(parent: _c, curve: Curves.easeOut);

    final showFor = kIsWeb
        ? const Duration(milliseconds: 3200)
        : const Duration(milliseconds: 3500);
    Future<void>.delayed(showFor, () async {
      if (!mounted) return;
      await _c.forward();
      if (!mounted) return;
      setState(() => _hide = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_hide)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0).animate(_fadeOut),
                child: const SplashScreen(),
              ),
            ),
          ),
        const SizedBox.shrink(),
      ],
    );
  }
}
