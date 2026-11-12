import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

void main() {
  runApp(const ClockApp());
}

class ClockApp extends StatelessWidget {
  const ClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clock App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true)
          .copyWith(scaffoldBackgroundColor: const Color(0xFF0F1115)),
      home: const ClockScreen(),
    );
  }
}

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  late DateTime _now;
  late Timer _timer;
  bool _isAnalog = false;
  bool _is24Hour = true;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clock'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _is24Hour ? 'Use 12-hour format' : 'Use 24-hour format',
            icon: Icon(_is24Hour ? Icons.timer_10 : Icons.access_time),
            onPressed: () => setState(() => _is24Hour = !_is24Hour),
          ),
          IconButton(
            tooltip: _isAnalog ? 'Show digital' : 'Show analog',
            icon: Icon(_isAnalog ? Icons.watch_later_outlined : Icons.schedule),
            onPressed: () => setState(() => _isAnalog = !_isAnalog),
          ),
        ],
      ),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _isAnalog
              ? AnalogClock(key: const ValueKey('analog'), time: _now)
              : DigitalClock(
                  key: const ValueKey('digital'),
                  time: _now,
                  is24Hour: _is24Hour,
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Digital clock
// ---------------------------------------------------------------------------
class DigitalClock extends StatelessWidget {
  final DateTime time;
  final bool is24Hour;

  const DigitalClock({super.key, required this.time, required this.is24Hour});

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat(is24Hour ? 'HH:mm:ss' : 'hh:mm:ss')
        .format(time);
    final period = DateFormat('a').format(time);
    final dateText = DateFormat('EEEE, d MMMM yyyy').format(time);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeText,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (!is24Hour)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  period,
                  style: const TextStyle(fontSize: 20, color: Colors.white70),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          dateText,
          style: const TextStyle(fontSize: 18, color: Colors.white60),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Analog clock
// ---------------------------------------------------------------------------
class AnalogClock extends StatelessWidget {
  final DateTime time;

  const AnalogClock({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    final size = math.min(MediaQuery.of(context).size.width * 0.85, 360.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _ClockPainter(time)),
        ),
        const SizedBox(height: 24),
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(time),
          style: const TextStyle(fontSize: 18, color: Colors.white60),
        ),
      ],
    );
  }
}

class _ClockPainter extends CustomPainter {
  final DateTime time;

  _ClockPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Face
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF1A1D24));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Tick marks
    for (int i = 0; i < 60; i++) {
      final isHour = i % 5 == 0;
      final angle = i * 6 * math.pi / 180;
      final outer = radius - 8;
      final inner = outer - (isHour ? 16 : 7);
      canvas.drawLine(
        center + Offset(math.sin(angle), -math.cos(angle)) * inner,
        center + Offset(math.sin(angle), -math.cos(angle)) * outer,
        Paint()
          ..color = isHour ? Colors.white : Colors.white38
          ..strokeWidth = isHour ? 3 : 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Hour numbers
    for (int i = 1; i <= 12; i++) {
      final angle = i * 30 * math.pi / 180;
      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.14,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos =
          center +
          Offset(math.sin(angle), -math.cos(angle)) * (radius * 0.68) -
          Offset(tp.width / 2, tp.height / 2);
      tp.paint(canvas, pos);
    }

    // Hand angles
    final secondAngle = time.second * 6 * math.pi / 180;
    final minuteAngle = (time.minute + time.second / 60) * 6 * math.pi / 180;
    final hourAngle =
        ((time.hour % 12) + time.minute / 60) * 30 * math.pi / 180;

    _drawHand(canvas, center, hourAngle, radius * 0.45, 7, Colors.white);
    _drawHand(canvas, center, minuteAngle, radius * 0.65, 5, Colors.white70);
    _drawHand(canvas, center, secondAngle, radius * 0.75, 2, Colors.redAccent);

    // Center cap
    canvas.drawCircle(center, 8, Paint()..color = Colors.redAccent);
    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFF1A1D24));
  }

  void _drawHand(
    Canvas canvas,
    Offset center,
    double angle,
    double length,
    double width,
    Color color,
  ) {
    canvas.drawLine(
      center,
      center + Offset(math.sin(angle), -math.cos(angle)) * length,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) =>
      old.time.second != time.second;
}
