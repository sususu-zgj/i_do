import 'package:flutter/material.dart';
import 'package:i_do/data/config.dart';
import 'package:i_do/page/home_page.dart';
import 'package:intl/intl.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      reverseDuration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () async {
      await _controller.reverse();
      // 跳转到主页面
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
      Setting().startUp = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekday = DateFormat('EEEE').format(now); // 英文星期几
    final dayStr = DateFormat('dd').format(now);
    final monthStr = DateFormat('MM').format(now);
    final yearStr = DateFormat('yyyy').format(now);
    String sentence = Setting().startUpSentence
        .replaceAll(RegExp(r'\{<weekday>\}'), weekday)
        .replaceAll(RegExp(r'\{<day>\}'), dayStr)
        .replaceAll(RegExp(r'\{<month>\}'), monthStr)
        .replaceAll(RegExp(r'\{<year>\}'), yearStr);
    final sentences = sentence.split('\n');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sentences.isNotEmpty)
              Text(
                sentences.first,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
                overflow: TextOverflow.fade,
              ),
              if (sentences.length > 1)
                ...[
                  const SizedBox(height: 10),
                  Text(
                    sentences.sublist(1).join('\n'),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.fade,
                  ),
                ]
            ],
          ),
        ),
      ),
    );
  }
}