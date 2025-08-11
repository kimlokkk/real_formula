// lib/ui/race/mini_games/launch_control_game.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../../models/interactive_race.dart';

class LaunchControlGame extends StatefulWidget {
  final Function(LaunchControlResult) onGameComplete;
  final int driverSpeed;
  final int carPerformance;

  const LaunchControlGame({
    Key? key,
    required this.onGameComplete,
    required this.driverSpeed,
    required this.carPerformance,
  }) : super(key: key);

  @override
  _LaunchControlGameState createState() => _LaunchControlGameState();
}

class _LaunchControlGameState extends State<LaunchControlGame> with TickerProviderStateMixin {
  // Game state
  GamePhase phase = GamePhase.ready; // Start in ready state
  double rpm = 0.0;
  double targetRpm = 0.0;
  bool hasReacted = false;
  DateTime? lightsOutTime;
  DateTime? reactionTime;

  // Button states
  bool isThrottlePressed = false;
  bool isClutchPressed = false;

  // UI Controllers
  late AnimationController _lightsController;

  // Game settings
  static const double MIN_RPM = 2000;
  static const double MAX_RPM = 8000;
  static const double OPTIMAL_RPM_START = 6200;
  static const double OPTIMAL_RPM_END = 6800;
  static const int LIGHTS_OUT_DELAY_MIN = 2000;
  static const int LIGHTS_OUT_DELAY_MAX = 4000;

  // Visual elements
  int currentLights = 5;
  Timer? lightsOutTimer;
  Timer? gameTimer;
  Timer? _rpmTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Don't start game automatically - wait for user to click start
  }

  void _initializeAnimations() {
    _lightsController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _startGame() {
    print("🎮 Game starting...");
    setState(() {
      phase = GamePhase.preparation;
      targetRpm = OPTIMAL_RPM_START + Random().nextDouble() * (OPTIMAL_RPM_END - OPTIMAL_RPM_START);
      rpm = MIN_RPM; // Reset RPM
      hasReacted = false;
      lightsOutTime = null;
      reactionTime = null;
      isThrottlePressed = false;
      isClutchPressed = false;
      currentLights = 5;
    });

    // Cancel any existing timers
    _rpmTimer?.cancel();
    _startLightsSequence();
  }

  void _onStartButtonPressed() {
    print("🚀 User pressed start button");
    _startGame();
  }

  void _startLightsSequence() {
    Timer.periodic(Duration(milliseconds: 800), (timer) {
      if (currentLights > 0) {
        setState(() {
          currentLights--;
        });
        _lightsController.forward().then((_) => _lightsController.reset());
      } else {
        timer.cancel();
        _waitForLightsOut();
      }
    });
  }

  void _waitForLightsOut() {
    setState(() {
      phase = GamePhase.waiting;
    });

    int delay = LIGHTS_OUT_DELAY_MIN + Random().nextInt(LIGHTS_OUT_DELAY_MAX - LIGHTS_OUT_DELAY_MIN);

    lightsOutTimer = Timer(Duration(milliseconds: delay), () {
      setState(() {
        phase = GamePhase.lightsOut;
        lightsOutTime = DateTime.now();
        currentLights = 0;
      });

      gameTimer = Timer(Duration(seconds: 2), () {
        if (!hasReacted) {
          _completeGame();
        }
      });
    });
  }

  // THROTTLE BUTTON LOGIC - Only works when clutch is engaged
  void _onThrottlePressed() {
    print("🟢 THROTTLE PRESSED");
    if (phase == GamePhase.lightsOut || phase == GamePhase.ready) return;

    setState(() {
      isThrottlePressed = true;
    });

    // IMPORTANT: Throttle only works if clutch is pressed
    if (!isClutchPressed) {
      print("🟢 THROTTLE BLOCKED - Clutch not engaged!");
      return;
    }

    print("🟢 THROTTLE ACTIVE - Starting RPM build (clutch engaged)");

    // Cancel any existing timer and start building
    _rpmTimer?.cancel();
    _rpmTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!isThrottlePressed || !isClutchPressed) {
        timer.cancel();
        return;
      }
      setState(() {
        rpm += 120;
        rpm = rpm.clamp(MIN_RPM, MAX_RPM);
      });
    });
  }

  void _onThrottleReleased() {
    print("🟢 THROTTLE RELEASED");
    if (phase == GamePhase.ready) return;

    setState(() {
      isThrottlePressed = false;
    });

    // Cancel any existing timer and start dropping RPM
    _rpmTimer?.cancel();
    _startRpmDrop();
  }

  // CLUTCH BUTTON LOGIC - Controls throttle functionality
  void _onClutchPressed() {
    print("🔵 CLUTCH PRESSED");
    if (phase == GamePhase.ready) return;

    setState(() {
      isClutchPressed = true;
    });

    // If throttle is already pressed, start building RPM now
    if (isThrottlePressed) {
      print("🔵 CLUTCH ENGAGED - Throttle can now work!");
      _startRpmBuilding();
    }
  }

  void _onClutchReleased() {
    print("🔵 CLUTCH RELEASED");
    if (phase == GamePhase.ready) return;

    setState(() {
      isClutchPressed = false;
    });

    // Stop RPM building immediately when clutch is released
    _rpmTimer?.cancel();
    print("🔵 CLUTCH DISENGAGED - Throttle stopped working, RPM dropping");

    // FALSE START DETECTION: Clutch released before lights out
    if (phase == GamePhase.waiting) {
      print("🚨 FALSE START! Clutch released before lights out!");
      setState(() {
        hasReacted = true;
        reactionTime = DateTime.now();
        lightsOutTime = DateTime.now(); // Set to same time for penalty calculation
      });
      _completeGameWithFalseStart();
      return;
    }

    // Start RPM drop when clutch is released (even if throttle still held)
    _startRpmDrop();

    // Check if this is during lights out phase for launch reaction
    if (phase == GamePhase.lightsOut && !hasReacted) {
      print("🏁 LAUNCH! Clutch released after lights out - measuring reaction time");
      setState(() {
        hasReacted = true;
        reactionTime = DateTime.now();
      });
      _completeGame();
    }
  }

  void _startRpmBuilding() {
    print("⚡ Starting RPM building (clutch + throttle engaged)...");
    _rpmTimer?.cancel();
    _rpmTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!isThrottlePressed || !isClutchPressed) {
        print("⚡ Stopping RPM building - conditions not met");
        timer.cancel();
        return;
      }

      setState(() {
        rpm += 120; // Build RPM
        rpm = rpm.clamp(MIN_RPM, MAX_RPM);
      });

      if (rpm % 1000 < 120) {
        // Print every ~1000 RPM
        print("⚡ RPM: ${rpm.round()}");
      }
    });
  }

  void _startRpmDrop() {
    print("⬇️ Starting RPM drop (clutch disengaged)...");
    _rpmTimer?.cancel();
    _rpmTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      // Stop dropping if clutch is engaged again AND throttle is pressed
      if (isClutchPressed && isThrottlePressed) {
        print("⬇️ Stopping RPM drop - clutch re-engaged with throttle");
        timer.cancel();
        _startRpmBuilding(); // Resume building
        return;
      }

      // Stop dropping during lights out phase
      if (phase == GamePhase.lightsOut) {
        timer.cancel();
        return;
      }

      setState(() {
        rpm -= 120; // Drop RPM
        rpm = rpm.clamp(MIN_RPM, MAX_RPM);
      });

      if (rpm <= MIN_RPM) {
        print("⬇️ RPM reached minimum, stopping drop");
        timer.cancel();
      }
    });
  }

  void _completeGameWithFalseStart() {
    gameTimer?.cancel();
    lightsOutTimer?.cancel();
    _rpmTimer?.cancel();

    print("🚨 FALSE START PENALTY APPLIED");

    // False start = massive penalty
    double falseStartPenalty = 9999.0; // Impossibly bad reaction time
    double rpmAccuracy = _calculateRpmAccuracy();

    // Create result with false start penalty
    LaunchControlResult result = LaunchControlResult(
      reactionTime: falseStartPenalty,
      rpmAccuracy: rpmAccuracy,
      perfectLaunch: false,
      performance: MiniGamePerformance.terrible,
      positionChange: 5, // Massive position loss for false start
    );

    widget.onGameComplete(result);
  }

  void _completeGame() {
    gameTimer?.cancel();
    lightsOutTimer?.cancel();
    _rpmTimer?.cancel();

    // Calculate reaction time: From lights out to clutch RELEASE
    double reactionMs = 0;
    if (lightsOutTime != null && reactionTime != null) {
      reactionMs = reactionTime!.difference(lightsOutTime!).inMilliseconds.toDouble();
    } else {
      reactionMs = 2000; // Maximum penalty for no reaction
    }

    double rpmAccuracy = _calculateRpmAccuracy();
    double overallScore = _calculateOverallScore(reactionMs, rpmAccuracy);
    double skillModifier = _calculateSkillModifier();
    double finalScore = (overallScore * skillModifier).clamp(0.0, 1.0);

    print("🏁 LAUNCH CONTROL RESULTS:");
    print("   RPM Accuracy: ${(rpmAccuracy * 100).round()}%");
    print("   Reaction Time (Clutch Release): ${reactionMs.round()}ms");
    print("   Final Score: ${(finalScore * 100).round()}%");

    MiniGamePerformance performance = _calculatePerformance(reactionMs, rpmAccuracy);
    int positionChange = _calculatePositionChange(performance);

    LaunchControlResult result = LaunchControlResult(
      reactionTime: reactionMs,
      rpmAccuracy: rpmAccuracy,
      perfectLaunch: performance == MiniGamePerformance.perfect,
      performance: performance,
      positionChange: positionChange,
    );

    widget.onGameComplete(result);
  }

  double _calculateRpmAccuracy() {
    double optimalCenter = (OPTIMAL_RPM_START + OPTIMAL_RPM_END) / 2;
    double optimalRange = OPTIMAL_RPM_END - OPTIMAL_RPM_START;
    double distance = (rpm - optimalCenter).abs();

    if (distance <= optimalRange / 2) {
      return 1.0 - (distance / (optimalRange / 2)) * 0.2;
    } else {
      double maxDistance = MAX_RPM - MIN_RPM;
      return (0.8 * (1.0 - (distance - optimalRange / 2) / maxDistance)).clamp(0.0, 0.8);
    }
  }

  double _calculateOverallScore(double reactionMs, double rpmAccuracy) {
    double reactionScore = 0.0;

    // NEW: Expanded reaction time window (120-350ms = perfect)
    if (reactionMs >= 120 && reactionMs <= 350) {
      reactionScore = 1.0; // Perfect reaction zone
    } else if (reactionMs < 120) {
      reactionScore = 0.0; // Too early (should be caught as false start anyway)
    } else if (reactionMs <= 500) {
      // Decent reaction zone: 350-500ms
      reactionScore = (500 - reactionMs) / 150; // Linear decline from 1.0 to 0.0
    } else if (reactionMs <= 800) {
      // Poor reaction zone: 500-800ms
      reactionScore = (800 - reactionMs) / 300 * 0.3; // Linear decline from 0.3 to 0.0
    } else {
      reactionScore = 0.05; // Very slow reaction
    }

    // NEW: Rebalanced weights - 40% RPM + 60% Reaction Time
    return (rpmAccuracy * 0.40) + (reactionScore * 0.60);
  }

  MiniGamePerformance _calculatePerformance(double reactionMs, double rpmAccuracy) {
    double overallScore = _calculateOverallScore(reactionMs, rpmAccuracy);
    double skillModifier = _calculateSkillModifier();
    double finalScore = (overallScore * skillModifier).clamp(0.0, 1.0);

    if (finalScore >= 0.90) return MiniGamePerformance.perfect;
    if (finalScore >= 0.75) return MiniGamePerformance.excellent;
    if (finalScore >= 0.60) return MiniGamePerformance.good;
    if (finalScore >= 0.45) return MiniGamePerformance.average;
    if (finalScore >= 0.25) return MiniGamePerformance.poor;
    return MiniGamePerformance.terrible;
  }

  double _calculateSkillModifier() {
    double driverFactor = widget.driverSpeed / 100.0;
    double carFactor = widget.carPerformance / 100.0;
    return 0.85 + (driverFactor * 0.1) + (carFactor * 0.05);
  }

  int _calculatePositionChange(MiniGamePerformance performance) {
    Map<MiniGamePerformance, int> baseChanges = {
      MiniGamePerformance.perfect: -3,
      MiniGamePerformance.excellent: -2,
      MiniGamePerformance.good: -1,
      MiniGamePerformance.average: 0,
      MiniGamePerformance.poor: 1,
      MiniGamePerformance.terrible: 2,
    };
    return baseChanges[performance] ?? 0;
  }

  @override
  void dispose() {
    _lightsController.dispose();
    gameTimer?.cancel();
    lightsOutTimer?.cancel();
    _rpmTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMainArea()),
            // Only show controls during actual game, not on ready screen
            if (phase != GamePhase.ready) _buildControlsArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            phase == GamePhase.ready ? 'F1 LAUNCH CONTROL' : 'RACE START IN PROGRESS',
            style: TextStyle(
              color: Colors.white,
              fontSize: phase == GamePhase.ready ? 28 : 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'Formula1',
              letterSpacing: 2,
            ),
          ),
          if (phase != GamePhase.ready) ...[
            SizedBox(height: 8),
            Text(
              _getPhaseDescription(),
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                fontFamily: 'Formula1',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainArea() {
    if (phase == GamePhase.ready) {
      return _buildReadyScreen();
    }

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // F1 Start Lights
          _buildStartLights(),

          SizedBox(height: 40),

          // RPM Display
          _buildRpmDisplay(),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReadyScreen() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // F1 Car Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red[600]!.withOpacity(0.2),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.red[600]!, width: 3),
            ),
            child: Icon(
              Icons.sports_motorsports,
              color: Colors.red[400],
              size: 60,
            ),
          ),

          SizedBox(height: 40),

          // Title
          Text(
            'F1 LAUNCH CONTROL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'Formula1',
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16),

          // Instructions
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(
                  'HOW TO PLAY',
                  style: TextStyle(
                    color: Colors.yellow[400],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Formula1',
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 12),
                _buildInstructionRow('1.', '🔵 PRESS clutch first to engage'),
                _buildInstructionRow('2.', '🟢 HOLD throttle to build RPM (needs clutch!)'),
                _buildInstructionRow('3.', '🚦 Keep both held - DON\'T release early!'),
                _buildInstructionRow('4.', '⚫ RELEASE clutch instantly (120-350ms = perfect)!'),
              ],
            ),
          ),

          SizedBox(height: 40),

          // Start Button
          GestureDetector(
            onTap: _onStartButtonPressed,
            child: Container(
              width: 200,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green[400]!, Colors.green[600]!, Colors.green[800]!],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.green[300]!, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'START RACE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Formula1',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(String number, String instruction) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            child: Text(
              number,
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Formula1',
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Formula1',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartLights() {
    return Container(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          bool isLit = index < (5 - currentLights);
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            width: 30,
            height: 80,
            decoration: BoxDecoration(
              color: phase == GamePhase.lightsOut ? Colors.black : (isLit ? Colors.red : Colors.grey[800]),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: isLit && phase != GamePhase.lightsOut
                  ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.8),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRpmDisplay() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ENGINE RPM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Formula1',
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRpmStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getRpmStatusColor(), width: 1),
                ),
                child: Text(
                  _getRpmStatus(),
                  style: TextStyle(
                    color: _getRpmStatusColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Formula1',
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // RPM Number Display
          Text(
            '${rpm.round()}',
            style: TextStyle(
              color: _getRpmColor(),
              fontSize: 36,
              fontWeight: FontWeight.w900,
              fontFamily: 'Formula1',
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: _getRpmColor().withOpacity(0.5),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),

          Text(
            'RPM',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Formula1',
              letterSpacing: 3,
            ),
          ),

          SizedBox(height: 24),

          // RPM Bar - Clean Design
          Stack(
            children: [
              // Background Track
              Container(
                width: 320,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),

              // Optimal Zone Background (Green Zone)
              Positioned(
                left: _getRpmPosition(OPTIMAL_RPM_START, 320),
                child: Container(
                  width: _getRpmPosition(OPTIMAL_RPM_END, 320) - _getRpmPosition(OPTIMAL_RPM_START, 320),
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green[400]!.withOpacity(0.3),
                        Colors.green[600]!.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),

              // Current RPM Fill
              Container(
                width: _getRpmPosition(rpm, 320),
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getRpmGradient(),
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: _getRpmColor().withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),

              // Optimal Zone Markers
              Positioned(
                left: _getRpmPosition(OPTIMAL_RPM_START, 320) - 1,
                top: -3,
                child: Container(
                  width: 2,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.green[400],
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              Positioned(
                left: _getRpmPosition(OPTIMAL_RPM_END, 320) - 1,
                top: -3,
                child: Container(
                  width: 2,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.green[400],
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // RPM Scale Labels
          Container(
            width: 320,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRpmLabel('2K', MIN_RPM),
                _buildRpmLabel('4K', 4000),
                _buildRpmLabel('6K', 6000),
                _buildRpmLabel('8K', MAX_RPM),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRpmLabel(String label, double rpmValue) {
    bool isInOptimalZone = rpmValue >= OPTIMAL_RPM_START && rpmValue <= OPTIMAL_RPM_END;

    return Column(
      children: [
        Container(
          width: 1,
          height: 8,
          color: isInOptimalZone ? Colors.green[400] : Colors.grey[600],
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isInOptimalZone ? Colors.green[400] : Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'Formula1',
          ),
        ),
      ],
    );
  }

  List<Color> _getRpmGradient() {
    if (rpm >= OPTIMAL_RPM_START && rpm <= OPTIMAL_RPM_END) {
      return [Colors.green[400]!, Colors.green[600]!];
    } else if (rpm < OPTIMAL_RPM_START) {
      return [Colors.yellow[400]!, Colors.orange[600]!];
    } else {
      return [Colors.orange[500]!, Colors.red[600]!];
    }
  }

  Color _getRpmStatusColor() {
    if (rpm >= OPTIMAL_RPM_START && rpm <= OPTIMAL_RPM_END) {
      return Colors.green[400]!;
    } else if (rpm < OPTIMAL_RPM_START) {
      return Colors.yellow[400]!;
    } else {
      return Colors.red[400]!;
    }
  }

  String _getRpmStatus() {
    if (rpm >= OPTIMAL_RPM_START && rpm <= OPTIMAL_RPM_END) {
      return 'OPTIMAL';
    } else if (rpm < OPTIMAL_RPM_START) {
      return 'LOW';
    } else {
      return 'HIGH';
    }
  }

  Widget _buildControlsArea() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          // THROTTLE BUTTON (Left) - Hold/release behavior
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => _onThrottlePressed(),
              onTapUp: (_) => _onThrottleReleased(),
              onTapCancel: () => _onThrottleReleased(),
              child: Container(
                height: 120,
                margin: EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isThrottlePressed
                        ? [Colors.green[400]!, Colors.green[600]!, Colors.green[800]!]
                        : [Colors.grey[600]!, Colors.grey[700]!, Colors.grey[800]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isThrottlePressed ? Colors.green[300]! : Colors.grey[500]!,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isThrottlePressed ? Colors.green : Colors.grey).withOpacity(0.4),
                      blurRadius: isThrottlePressed ? 20 : 10,
                      spreadRadius: isThrottlePressed ? 5 : 2,
                      offset: Offset(0, isThrottlePressed ? 2 : 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.speed,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'THROTTLE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Formula1',
                      ),
                    ),
                    Text(
                      isThrottlePressed
                          ? (isClutchPressed ? 'REVVING' : 'BLOCKED')
                          : (isClutchPressed ? 'HOLD TO REV' : 'CLUTCH FIRST'),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontFamily: 'Formula1',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CLUTCH BUTTON (Right) - Simple press/release behavior like real clutch
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => _onClutchPressed(),
              onTapUp: (_) => _onClutchReleased(),
              onTapCancel: () => _onClutchReleased(),
              child: Container(
                height: 120,
                margin: EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isClutchPressed
                        ? [Colors.blue[400]!, Colors.blue[600]!, Colors.blue[800]!]
                        : [Colors.grey[600]!, Colors.grey[700]!, Colors.grey[800]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isClutchPressed ? Colors.blue[300]! : Colors.grey[500]!,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isClutchPressed ? Colors.blue : Colors.grey).withOpacity(0.4),
                      blurRadius: isClutchPressed ? 20 : 10,
                      spreadRadius: isClutchPressed ? 5 : 2,
                      offset: Offset(0, isClutchPressed ? 2 : 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'CLUTCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Formula1',
                      ),
                    ),
                    Text(
                      isClutchPressed ? 'ENGAGED' : 'HOLD TO ENGAGE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontFamily: 'Formula1',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getRpmPosition(double rpmValue, double barWidth) {
    double percent = (rpmValue - MIN_RPM) / (MAX_RPM - MIN_RPM);
    return percent * barWidth;
  }

  Color _getRpmColor() {
    if (rpm >= OPTIMAL_RPM_START && rpm <= OPTIMAL_RPM_END) {
      return Colors.green;
    } else if (rpm < OPTIMAL_RPM_START) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  String _getPhaseDescription() {
    switch (phase) {
      case GamePhase.ready:
        return 'Get ready for F1 race start challenge';
      case GamePhase.preparation:
        return 'Press clutch first, then hold throttle to build RPM';
      case GamePhase.waiting:
        return 'Hold both: clutch engaged + throttle for RPM - DON\'T release early!';
      case GamePhase.lightsOut:
        return 'Release clutch NOW!';
      default:
        return 'Get ready for F1 race start';
    }
  }
}

enum GamePhase {
  ready,
  waiting,
  preparation,
  lightsOut,
  completed,
}
