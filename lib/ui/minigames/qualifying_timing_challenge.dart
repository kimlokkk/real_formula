// lib/ui/minigames/qualifying_timing_challenge.dart - Enhanced F1 Design
import 'package:flutter/material.dart';
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

class _QualifyingTimingChallengeState extends State<QualifyingTimingChallenge> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeController;
  late Animation<double> _animation;
  late Animation<double> _fadeAnimation;
  late GameSettings _settings;

  bool _hasAttempted = false;
  QualifyingTimingResult? _result;

  @override
  void initState() {
    super.initState();

    // Get difficulty settings based on driver skill
    _settings = QualifyingDifficulty.getSettings(widget.driver);

    _initializeAnimations();

    // Start the animation with a small delay
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  void _initializeAnimations() {
    // Timing bar animation
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

    // Fade in animation
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();

    // Add listener for rebuilds
    _animation.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
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
        timeModifier: -0.4,
        description: 'PERFECT!',
        color: Colors.purple,
      );
    } else if (position >= 0.36 && position <= 0.64) {
      // Good zone (28% of bar) - GREEN
      return QualifyingTimingResult(
        quality: 'good',
        timeModifier: -0.3,
        description: 'Good',
        color: Colors.green,
      );
    } else if (position >= 0.25 && position <= 0.75) {
      // Okay zone (50% of bar) - ORANGE
      return QualifyingTimingResult(
        quality: 'okay',
        timeModifier: -0.2,
        description: 'Okay',
        color: Colors.orange,
      );
    } else {
      // Bad zone (rest of bar) - RED
      return QualifyingTimingResult(
        quality: 'bad',
        timeModifier: -0.1,
        description: 'Missed',
        color: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
              Color(0xFF0A1128),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildTopSection(),
                      ),
                      _buildCenterSection(),
                      _buildBottomSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.red[600]!.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button - match other pages
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          SizedBox(width: 16),

          // Racing stripe
          Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[400]!, Colors.red[600]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          SizedBox(width: 12),

          // Title section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUALIFYING LAP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '${widget.driver.name} • ${widget.track.name}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Formula1',
                  ),
                ),
              ],
            ),
          ),

          // Weather indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.weather.icon,
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(width: 4),
                Text(
                  widget.weather.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    if (_hasAttempted && _result != null) {
      return _buildResultDisplay();
    } else {
      return _buildInstructions();
    }
  }

  Widget _buildInstructions() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Motorsports icon
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[600]!.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red[600]!.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.speed,
              size: 48,
              color: Colors.red[400],
            ),
          ),

          SizedBox(height: 24),

          Text(
            'FIND THE PERFECT MOMENT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'Formula1',
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 12),

          Text(
            _getInstructionText(),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Formula1',
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 20),

          // Skill indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Colors.orange[400],
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'DRIVER SKILL: ${((widget.driver.speed + widget.driver.consistency) ~/ 2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultDisplay() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Result icon with color
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _result!.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _result!.color,
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                _getResultIcon(),
                size: 40,
                color: _result!.color,
              ),
            ),
          ),

          SizedBox(height: 20),

          Text(
            _result!.description.toUpperCase(),
            style: TextStyle(
              color: _result!.color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Formula1',
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16),

          // Time display
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'LAP TIME',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Formula1',
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatLapTime(_calculateFinalLapTime()),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getResultIcon() {
    switch (_result!.quality) {
      case 'perfect':
        return Icons.star;
      case 'good':
        return Icons.thumb_up;
      case 'okay':
        return Icons.horizontal_rule;
      case 'bad':
        return Icons.thumb_down;
      default:
        return Icons.help;
    }
  }

  Widget _buildCenterSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Zone legend
          if (!_hasAttempted) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildZoneLegend('PERFECT', Colors.purple),
                SizedBox(width: 16),
                _buildZoneLegend('GOOD', Colors.green),
                SizedBox(width: 16),
                _buildZoneLegend('OKAY', Colors.orange),
                SizedBox(width: 16),
                _buildZoneLegend('MISS', Colors.red),
              ],
            ),
            SizedBox(height: 16),
          ],

          // Timing bar
          Container(
            width: 340,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: TimingBarPainter(
                      indicatorPosition: _animation.value,
                      hasAttempted: _hasAttempted,
                      resultPosition: _hasAttempted ? _animation.value : null,
                    ),
                    size: Size(340, 60),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneLegend(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'Formula1',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _hasAttempted ? () => Navigator.of(context).pop(_result) : _onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasAttempted ? Colors.green[600] : Colors.red[600],
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _hasAttempted ? Icons.check : Icons.touch_app,
                size: 24,
                color: Colors.white,
              ),
              SizedBox(width: 12),
              Text(
                _hasAttempted ? 'CONTINUE' : 'TAP NOW!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInstructionText() {
    int skill = (widget.driver.speed + widget.driver.consistency) ~/ 2;

    if (skill >= 80) {
      return 'Your high skill gives you precise control';
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
      return 0.8; // Very slow bar (easiest)
    } else if (skill >= 80) {
      return 0.6; // Slow bar
    } else if (skill >= 70) {
      return 0.5; // Medium bar
    } else if (skill >= 60) {
      return 0.4; // Fast bar
    } else {
      return 0.2; // Very fast bar (hardest)
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
    final double width = size.width;
    final double height = size.height;

    // Draw colored zones
    _drawZone(canvas, 0.0, 0.25, Colors.red.withValues(alpha: 0.6), width, height);
    _drawZone(canvas, 0.25, 0.36, Colors.orange.withValues(alpha: 0.6), width, height);
    _drawZone(canvas, 0.36, 0.45, Colors.green.withValues(alpha: 0.6), width, height);
    _drawZone(canvas, 0.45, 0.55, Colors.purple.withValues(alpha: 0.6), width, height);
    _drawZone(canvas, 0.55, 0.64, Colors.green.withValues(alpha: 0.6), width, height);
    _drawZone(canvas, 0.64, 0.75, Colors.orange.withValues(alpha: 0.6), width, height);
    _drawZone(canvas, 0.75, 1.0, Colors.red.withValues(alpha: 0.6), width, height);

    // Draw moving indicator
    if (!hasAttempted) {
      _drawIndicator(canvas, indicatorPosition, Colors.white, width, height);
    }

    // Draw result indicator
    if (hasAttempted && resultPosition != null) {
      Color resultColor = _getResultColor(resultPosition!);
      _drawIndicator(canvas, resultPosition!, resultColor, width, height);
    }
  }

  void _drawZone(Canvas canvas, double start, double end, Color color, double width, double height) {
    final paint = Paint()..color = color;
    final rect = Rect.fromLTWH(
      start * width,
      0,
      (end - start) * width,
      height,
    );
    canvas.drawRect(rect, paint);
  }

  void _drawIndicator(Canvas canvas, double position, Color color, double width, double height) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final x = position * width;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, height),
      paint,
    );

    // Draw arrow at top
    final arrowPaint = Paint()..color = color;
    final path = Path();
    path.moveTo(x, 8);
    path.lineTo(x - 6, 0);
    path.lineTo(x + 6, 0);
    path.close();
    canvas.drawPath(path, arrowPaint);
  }

  Color _getResultColor(double position) {
    if (position >= 0.45 && position <= 0.55) {
      return Colors.purple;
    } else if (position >= 0.36 && position <= 0.64) {
      return Colors.green;
    } else if (position >= 0.25 && position <= 0.75) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
