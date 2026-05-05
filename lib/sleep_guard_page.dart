import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data.dart';
import 'main.dart'; // 用 SleepOverlayManager

class SleepGuardPage extends StatefulWidget {
  const SleepGuardPage({super.key});

  @override
  State<SleepGuardPage> createState() => _SleepGuardPageState();
}

class _SleepGuardPageState extends State<SleepGuardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 0.98, end: 1.02)
        .animate(_breathController);
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/sleep.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(0x20FFFFFF),
              BlendMode.lighten,
            ),
          ),
        ),
        child: const Center(
          child: Text(
            '隐士已经睡着了。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Serif',
              fontSize: 14,
              color: Color(0x66B0C4DE),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}