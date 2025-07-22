// lib/ui/minigames/qualifying_timing_challenge.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../../models/driver.dart';
import '../../models/track.dart';
import '../../models/enums.dart';

// Define the result class that the qualifying page expects
class QualifyingTimingResult {
  final String quality;
  final double timeModifier;
  final String description;
  final Color color;

  QualifyingTimingResult({
    required this.quality,
    required this.timeModifier,
    required this.description,
    required this.color,
  });
}

class QualifyingTimingChallenge extends StatefulWidget {
  final Driver driver;
  final Track track;
  final WeatherCondition weather;

  const QualifyingTimingChallenge({
    Key? key,
    required this.driver,
    required this.track,
    required this.weather,
  }) : super(key: key);

  @override
  _QualifyingTimingChallengeState createState() => _QualifyingTimingChallengeState();
}

class _QualifyingTimingChallengeState extends State<QualifyingTimingChallenge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late GameSettings _settings;

  bool _hasAttempted = false;
  QualifyingTimingResult? _result;
  double _baseQualifyingTime = 0.0;

  @override
  void initState() {
    super.initState();

    // Calculate base qualifying time for this track
    _baseQualifyingTime = widget.track.baseLapTime * 0.97; // Qualifying pace

    // Get difficulty settings based on driver skill
    _settings = QualifyingDifficulty.getSettings(widget.driver);

    print('=== MINIGAME DEBUG ===');
    print('Driver: ${widget.driver.name}');
    print('Skill: ${(widget.driver.speed + widget.driver.consistency) ~/ 2}');
    print('Animation Speed: ${_settings.animationSpeed} seconds');

    // Create animation with skill-based speed (higher skill = slower = easier)
    _controller = AnimationController(
      duration: Duration(milliseconds: (_settings.animationSpeed * 1000).round()),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    // Add listener to debug animation
    _animation.addListener(() {
      if (mounted) {
        // This will trigger rebuilds to show the moving pointer
        setState(() {});
      }
    });

    // Start the animation with a small delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.repeat(reverse: true);
        print('Animation started!');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_hasAttempted) return;

    setState(() {
      _hasAttempted = true;
      _controller.stop();

      double currentPosition = _animation.value;
      _result = _evaluateTiming(currentPosition);
    });
  }

  // Calculate final qualifying lap time
  double _calculateFinalLapTime() {
    // Use same calculation as in qualifying_page.dart
    double baseTime = widget.track.baseLapTime * 0.97; // Qualifying pace

    // Apply driver skills
    double speedFactor = (100 - widget.driver.speed) * 0.015;
    double consistencyFactor = (100 - widget.driver.consistency) * 0.008;
    double carFactor = (100 - widget.driver.carPerformance) * 0.018;

    double driverAdjustedTime = baseTime + speedFactor + consistencyFactor + carFactor;

    // Apply weather penalty if any
    if (widget.weather == WeatherCondition.rain) {
      double weatherPenalty = 2.5 + ((100 - widget.driver.consistency) / 100.0 * 1.5);
      driverAdjustedTime += weatherPenalty;
    }

    // Apply minigame result
    if (_result != null) {
      driverAdjustedTime += _result!.timeModifier;
    }

    return driverAdjustedTime;
  }

  QualifyingTimingResult _evaluateTiming(double position) {
    // Zone boundaries (0.0 to 1.0)
    if (position >= 0.45 && position <= 0.55) {
      // Perfect zone (10% of bar, centered) - PURPLE
      return QualifyingTimingResult(
        quality: 'perfect',
        timeModifier: -0.3,
        description: 'PERFECT!',
        color: Colors.purple,
      );
    } else if (position >= 0.36 && position <= 0.64) {
      // Good zone (28% of bar) - GREEN
      return QualifyingTimingResult(
        quality: 'good',
        timeModifier: -0.1,
        description: 'Good',
        color: Colors.green,
      );
    } else if (position >= 0.25 && position <= 0.75) {
      // Okay zone (50% of bar) - ORANGE
      return QualifyingTimingResult(
        quality: 'okay',
        timeModifier: 0.0,
        description: 'Okay',
        color: Colors.orange,
      );
    } else {
      // Bad zone (rest of bar) - RED
      return QualifyingTimingResult(
        quality: 'bad',
        timeModifier: 0.4,
        description: 'Missed',
        color: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        height: 600,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[600]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // FIXED HEADER
            _buildHeader(),

            // MAIN CONTENT AREA - Expandable
            Expanded(
              child: Column(
                children: [
                  // TOP SECTION - Instructions or Results (More space)
                  Expanded(
                    flex: 3,
                    child: _buildTopSection(),
                  ),

                  // CENTER SECTION - Always contains the timing bar (Compact)
                  _buildCenterSection(),

                  // BOTTOM SECTION - Always contains the action button (Compact)
                  _buildBottomSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[900]!, Colors.red[600]!],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Column(
        children: [
          Text(
            '${widget.driver.name.toUpperCase()} - QUALIFYING',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${widget.track.name} • Target: ${_formatLapTime(_baseQualifyingTime)}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Skills: SPD ${widget.driver.speed} • CON ${widget.driver.consistency}',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_hasAttempted) ...[
            // INSTRUCTIONS STATE - Compact version
            Flexible(
              child: Icon(
                Icons.touch_app,
                color: Colors.purple[400],
                size: 40,
              ),
            ),
            SizedBox(height: 12),
            Flexible(
              child: Text(
                'TAP WHEN POINTER HITS PURPLE!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 8),
            Flexible(
              child: Text(
                _getInstructionText(),
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 6),
            Flexible(
              child: Text(
                'Purple = Perfect • Green = Good • Orange = Okay • Red = Bad',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else if (_result != null) ...[
            // RESULTS STATE - Compact version
            Flexible(
              child: Icon(
                _result!.quality == 'perfect'
                    ? Icons.star
                    : _result!.quality == 'good'
                        ? Icons.thumb_up
                        : _result!.quality == 'okay'
                            ? Icons.thumbs_up_down
                            : Icons.thumb_down,
                color: _result!.color,
                size: 48,
              ),
            ),
            SizedBox(height: 8),
            Flexible(
              child: Text(
                _result!.description,
                style: TextStyle(
                  color: _result!.color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 4),
            Flexible(
              child: Text(
                _result!.timeModifier >= 0
                    ? '+${_result!.timeModifier.toStringAsFixed(1)}s'
                    : '${_result!.timeModifier.toStringAsFixed(1)}s',
                style: TextStyle(
                  color: _result!.color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            // Lap time display - Compact
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[600]!, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'QUALIFYING TIME',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatLapTime(_calculateFinalLapTime()),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCenterSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Zone legend - More compact
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Timing Zones',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 8),

          // TIMING BAR - Slightly smaller
          Container(
            width: 320,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[600]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: TimingBarPainter(
                    indicatorPosition: _animation.value,
                    hasAttempted: _hasAttempted,
                    resultPosition: _hasAttempted ? _animation.value : null,
                  ),
                  size: Size(320, 50),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // ACTION BUTTON - Always at bottom
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _hasAttempted ? () => Navigator.of(context).pop(_result) : _onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasAttempted ? Colors.green[600] : Colors.purple[600],
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: (_hasAttempted ? Colors.green : Colors.purple).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _hasAttempted ? Icons.arrow_forward : Icons.touch_app,
                    size: 20,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _hasAttempted ? 'CONTINUE TO GRID' : 'TAP NOW!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),

          // Helper text - Compact
          Text(
            _hasAttempted ? 'Ready to proceed to the starting grid' : 'Watch the pointer and tap when it hits purple!',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getInstructionText() {
    int skill = (widget.driver.speed + widget.driver.consistency) ~/ 2;

    if (skill >= 80) {
      return 'Your skill gives you precise control';
    } else if (skill >= 60) {
      return 'Steady hands, you can do this!';
    } else {
      return 'Stay focused - the pointer moves fast!';
    }
  }

  String _formatLapTime(double seconds) {
    int minutes = seconds ~/ 60;
    double remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toStringAsFixed(3).padLeft(6, '0')}';
  }
}

// Supporting Classes
class GameSettings {
  final double perfectZoneSize;
  final double goodZoneSize;
  final double okayZoneSize;
  final double animationSpeed;
  final int attempts;

  GameSettings({
    required this.perfectZoneSize,
    required this.goodZoneSize,
    required this.okayZoneSize,
    required this.animationSpeed,
    required this.attempts,
  });
}

class QualifyingDifficulty {
  static GameSettings getSettings(Driver userDriver) {
    int overallSkill = (userDriver.speed + userDriver.consistency) ~/ 2;

    // HIGHER skill = SLOWER bar = EASIER timing
    // LOWER skill = FASTER bar = HARDER timing
    double animationSpeed = _calculateAnimationSpeed(overallSkill);

    return GameSettings(
      perfectZoneSize: 0.10,
      goodZoneSize: 0.18,
      okayZoneSize: 0.25,
      animationSpeed: animationSpeed,
      attempts: 1,
    );
  }

  static double _calculateAnimationSpeed(int skill) {
    // Inverse relationship: Higher skill = slower bar = easier
    if (skill >= 90) {
      return 1.0; // Very slow bar (easiest)
    } else if (skill >= 80) {
      return 1.3; // Slow bar
    } else if (skill >= 70) {
      return 1.7; // Medium bar
    } else if (skill >= 60) {
      return 2.0; // Fast bar
    } else {
      return 1.5; // Very fast bar (hardest) - This is Rookie!
    }
  }
}

// Custom Painter for the timing bar
class TimingBarPainter extends CustomPainter {
  final double indicatorPosition;
  final bool hasAttempted;
  final double? resultPosition;

  TimingBarPainter({
    required this.indicatorPosition,
    required this.hasAttempted,
    this.resultPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw timing zones with clean colors
    _drawZone(canvas, size, 0.0, 0.25, Colors.red[600]!, paint); // Bad (left)
    _drawZone(canvas, size, 0.25, 0.36, Colors.orange[600]!, paint); // Okay
    _drawZone(canvas, size, 0.36, 0.45, Colors.green[600]!, paint); // Good
    _drawZone(canvas, size, 0.45, 0.55, Colors.purple[600]!, paint); // Perfect
    _drawZone(canvas, size, 0.55, 0.64, Colors.green[600]!, paint); // Good
    _drawZone(canvas, size, 0.64, 0.75, Colors.orange[600]!, paint); // Okay
    _drawZone(canvas, size, 0.75, 1.0, Colors.red[600]!, paint); // Bad (right)

    // Draw moving indicator
    if (!hasAttempted) {
      _drawIndicator(canvas, size, indicatorPosition, Colors.white, paint);
    } else if (resultPosition != null) {
      _drawIndicator(canvas, size, resultPosition!, Colors.yellow[400]!, paint);
    }
  }

  void _drawZone(Canvas canvas, Size size, double start, double end, Color color, Paint paint) {
    paint.color = color;
    paint.style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        start * size.width,
        0,
        (end - start) * size.width,
        size.height,
      ),
      paint,
    );
  }

  void _drawIndicator(Canvas canvas, Size size, double position, Color color, Paint paint) {
    paint.color = color;
    paint.strokeWidth = 3;

    double x = position * size.width;

    // Draw vertical line indicator
    canvas.drawLine(
      Offset(x, 6),
      Offset(x, size.height - 6),
      paint,
    );

    // Draw triangle pointer at top
    Path triangle = Path();
    triangle.moveTo(x, 6);
    triangle.lineTo(x - 6, -3);
    triangle.lineTo(x + 6, -3);
    triangle.close();

    paint.style = PaintingStyle.fill;
    canvas.drawPath(triangle, paint);

    // Draw triangle pointer at bottom
    Path bottomTriangle = Path();
    bottomTriangle.moveTo(x, size.height - 6);
    bottomTriangle.lineTo(x - 6, size.height + 3);
    bottomTriangle.lineTo(x + 6, size.height + 3);
    bottomTriangle.close();

    canvas.drawPath(bottomTriangle, paint);
  }

  @override
  bool shouldRepaint(TimingBarPainter oldDelegate) {
    return oldDelegate.indicatorPosition != indicatorPosition ||
        oldDelegate.hasAttempted != hasAttempted ||
        oldDelegate.resultPosition != resultPosition;
  }
}
