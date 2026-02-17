import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:himatch/models/suggestion.dart';

/// Generate shareable image cards for confirmed plans.
///
/// Uses Canvas/CustomPainter to draw a visually appealing card with
/// gradient background, date, activity, member names, and optional weather.
/// Returns PNG bytes suitable for sharing via share_plus.
class ShareCardGenerator {
  /// Card dimensions.
  static const double _cardWidth = 1080;
  static const double _cardHeight = 1350;

  /// Generate share card as PNG bytes.
  static Future<Uint8List> generateCard({
    required String groupName,
    required DateTime date,
    required String activityType,
    required String timeRange,
    required List<String> memberNames,
    WeatherSummary? weather,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(_cardWidth, _cardHeight);

    final painter = _ShareCardPainter(
      groupName: groupName,
      date: date,
      activityType: activityType,
      timeRange: timeRange,
      memberNames: memberNames,
      weather: weather,
    );

    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      _cardWidth.toInt(),
      _cardHeight.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    picture.dispose();

    if (byteData == null) {
      throw Exception('Failed to generate share card image');
    }

    return byteData.buffer.asUint8List();
  }
}

class _ShareCardPainter {
  final String groupName;
  final DateTime date;
  final String activityType;
  final String timeRange;
  final List<String> memberNames;
  final WeatherSummary? weather;

  static final DateFormat _dateFormat = DateFormat('M/d');
  static final DateFormat _weekdayFormat = DateFormat('E', 'ja');

  _ShareCardPainter({
    required this.groupName,
    required this.date,
    required this.activityType,
    required this.timeRange,
    required this.memberNames,
    this.weather,
  });

  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawDecorations(canvas, size);
    _drawContent(canvas, size);
    _drawFooter(canvas, size);
  }

  /// Draw gradient background.
  void _drawBackground(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: _gradientColorsForActivity(activityType),
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  /// Draw decorative circles and shapes.
  void _drawDecorations(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(25)
      ..style = PaintingStyle.fill;

    // Large circle top-right
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.08),
      180,
      paint,
    );

    // Medium circle bottom-left
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.85),
      120,
      paint,
    );

    // Small circles scattered
    paint.color = Colors.white.withAlpha(15);
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.15),
      60,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.7),
      90,
      paint,
    );
  }

  /// Draw main content.
  void _drawContent(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    double currentY = size.height * 0.12;

    // ── App branding ──
    _drawTextCentered(
      canvas,
      'Himatch',
      centerX,
      currentY,
      fontSize: 28,
      color: Colors.white.withAlpha(200),
      fontWeight: FontWeight.w300,
    );
    currentY += 60;

    // ── Group name ──
    _drawTextCentered(
      canvas,
      groupName,
      centerX,
      currentY,
      fontSize: 36,
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );
    currentY += 80;

    // ── Date display (large) ──
    final dateStr = _dateFormat.format(date);
    _drawTextCentered(
      canvas,
      dateStr,
      centerX,
      currentY,
      fontSize: 120,
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    currentY += 140;

    // ── Day of week ──
    final weekdayStr = _weekdayFormat.format(date);
    _drawTextCentered(
      canvas,
      weekdayStr,
      centerX,
      currentY,
      fontSize: 40,
      color: Colors.white.withAlpha(230),
      fontWeight: FontWeight.w400,
    );
    currentY += 80;

    // ── Divider line ──
    final dividerPaint = Paint()
      ..color = Colors.white.withAlpha(100)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(centerX - 100, currentY),
      Offset(centerX + 100, currentY),
      dividerPaint,
    );
    currentY += 40;

    // ── Activity type ──
    _drawTextCentered(
      canvas,
      activityType,
      centerX,
      currentY,
      fontSize: 52,
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    currentY += 70;

    // ── Time range ──
    _drawTextCentered(
      canvas,
      timeRange,
      centerX,
      currentY,
      fontSize: 36,
      color: Colors.white.withAlpha(220),
      fontWeight: FontWeight.w400,
    );
    currentY += 70;

    // ── Weather info ──
    if (weather != null) {
      final weatherText = StringBuffer();
      if (weather!.icon != null) {
        weatherText.write('${weather!.icon} ');
      }
      weatherText.write(weather!.condition);
      if (weather!.tempHigh != null && weather!.tempLow != null) {
        weatherText.write(
          '  ${weather!.tempLow!.round()}-${weather!.tempHigh!.round()}C',
        );
      }
      _drawTextCentered(
        canvas,
        weatherText.toString(),
        centerX,
        currentY,
        fontSize: 30,
        color: Colors.white.withAlpha(200),
        fontWeight: FontWeight.w400,
      );
      currentY += 60;
    }

    // ── Member names ──
    currentY += 20;
    final membersText = memberNames.join('  ');
    _drawTextCentered(
      canvas,
      membersText,
      centerX,
      currentY,
      fontSize: 28,
      color: Colors.white.withAlpha(200),
      fontWeight: FontWeight.w400,
    );

    // ── Member avatars (colored circles with initials) ──
    currentY += 50;
    _drawMemberAvatars(canvas, size, currentY);
  }

  /// Draw member avatar circles.
  void _drawMemberAvatars(Canvas canvas, Size size, double y) {
    final count = memberNames.length;
    if (count == 0) return;

    final avatarRadius = 28.0;
    final spacing = 70.0;
    final totalWidth = count * spacing - (spacing - avatarRadius * 2);
    final startX = (size.width - totalWidth) / 2 + avatarRadius;

    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFF95E1D3),
      const Color(0xFFF38181),
      const Color(0xFFAA96DA),
      const Color(0xFFFCBAD3),
      const Color(0xFFA8D8EA),
    ];

    for (int i = 0; i < count; i++) {
      final cx = startX + i * spacing;
      final color = colors[i % colors.length];

      // Circle
      final circlePaint = Paint()..color = color;
      canvas.drawCircle(Offset(cx, y), avatarRadius, circlePaint);

      // Initial letter
      final name = memberNames[i];
      if (name.isNotEmpty) {
        _drawTextCentered(
          canvas,
          name.characters.first,
          cx,
          y - 12,
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        );
      }
    }
  }

  /// Draw footer branding.
  void _drawFooter(Canvas canvas, Size size) {
    _drawTextCentered(
      canvas,
      'Created with Himatch',
      size.width / 2,
      size.height - 60,
      fontSize: 20,
      color: Colors.white.withAlpha(150),
      fontWeight: FontWeight.w300,
    );
  }

  /// Draw centered text using Canvas API.
  void _drawTextCentered(
    Canvas canvas,
    String text,
    double x,
    double y, {
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final textStyle = ui.TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
    final paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.center,
      maxLines: 1,
    );
    final builder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: _ShareCardPainter._cardWidth()));

    canvas.drawParagraph(
      paragraph,
      Offset(x - paragraph.maxIntrinsicWidth / 2, y),
    );
  }

  /// Card width accessor for paragraph layout.
  static double _cardWidth() => ShareCardGenerator._cardWidth;

  /// Get gradient colors based on activity type.
  List<Color> _gradientColorsForActivity(String activity) {
    // Match common activity types to color themes
    final lower = activity.toLowerCase();

    if (lower.contains('bbq') ||
        lower.contains('アウトドア') ||
        lower.contains('ピクニック')) {
      return const [Color(0xFFFF9A56), Color(0xFFFF6B6B)];
    }
    if (lower.contains('飲み') ||
        lower.contains('ディナー') ||
        lower.contains('食事')) {
      return const [Color(0xFF667EEA), Color(0xFF764BA2)];
    }
    if (lower.contains('ランチ') || lower.contains('カフェ')) {
      return const [Color(0xFFFDA085), Color(0xFFF6D365)];
    }
    if (lower.contains('映画') || lower.contains('ゲーム')) {
      return const [Color(0xFFA18CD1), Color(0xFFFBC2EB)];
    }
    if (lower.contains('スポーツ') ||
        lower.contains('運動') ||
        lower.contains('ジム')) {
      return const [Color(0xFF43E97B), Color(0xFF38F9D7)];
    }
    if (lower.contains('旅行') || lower.contains('ドライブ')) {
      return const [Color(0xFF4FACFE), Color(0xFF00F2FE)];
    }
    if (lower.contains('勉強') || lower.contains('ミーティング')) {
      return const [Color(0xFF6A11CB), Color(0xFF2575FC)];
    }

    // Default gradient
    return const [Color(0xFF667EEA), Color(0xFF764BA2)];
  }
}
