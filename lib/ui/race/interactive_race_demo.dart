// lib/ui/race/interactive_race_demo.dart
import 'package:flutter/material.dart';
import 'package:real_formula/ui/minigames/launch_control_game.dart';
import 'dart:async';
import '../../models/driver.dart';
import '../../models/interactive_race.dart';
import '../../services/interactive_race_engine.dart';

class InteractiveRaceDemo extends StatefulWidget {
  const InteractiveRaceDemo({Key? key}) : super(key: key);

  @override
  _InteractiveRaceDemoState createState() => _InteractiveRaceDemoState();
}

class _InteractiveRaceDemoState extends State<InteractiveRaceDemo> with TickerProviderStateMixin {
  // Race state
  List<Driver> startingGrid = [];
  List<Driver> raceResults = [];
  bool showMiniGame = false;
  bool raceCompleted = false;
  LaunchControlResult? playerResult;

  // UI controllers
  late AnimationController _fadeController;
  late AnimationController _gridController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _gridAnimation;

  // Demo settings
  static const String PLAYER_NAME = "YOUR DRIVER";
  static const int PLAYER_STARTING_POSITION = 8;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupRace();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _gridController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _gridAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gridController, curve: Curves.elasticOut),
    );
  }

  void _setupRace() {
    setState(() {
      startingGrid = InteractiveRaceEngine.createDemoStartingGrid();
    });

    _fadeController.forward();

    // Automatically start race simulation after 2 seconds
    Timer(Duration(seconds: 2), () {
      _startRaceSimulation();
    });
  }

  void _startRaceSimulation() {
    // Start background AI simulation
    InteractiveRaceEngine.simulateRaceStart(startingGrid, playerDriverName: PLAYER_NAME);

    // Show mini-game for player
    setState(() {
      showMiniGame = true;
    });
  }

  void _onMiniGameComplete(LaunchControlResult result) {
    setState(() {
      showMiniGame = false;
      playerResult = result;
    });

    // Integrate player result with AI simulation
    List<Driver> finalResults = InteractiveRaceEngine.integratePlayerStartResult(
      startingGrid, // Use original grid, engine will sort AI drivers
      result,
      PLAYER_NAME,
      PLAYER_STARTING_POSITION,
    );

    setState(() {
      raceResults = finalResults;
      raceCompleted = true;
    });

    // Animate results
    _gridController.forward();

    // Show completion message after animation
    Timer(Duration(seconds: 2), () {
      _showCompletionDialog();
    });
  }

  void _showCompletionDialog() {
    Driver playerDriver = raceResults.firstWhere((d) => d.name == PLAYER_NAME);
    int positionChange = PLAYER_STARTING_POSITION - playerDriver.position;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'RACE START COMPLETE!',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Formula1',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Performance: ${playerResult!.performance.displayName}',
              style: TextStyle(
                color: playerResult!.performance.color,
                fontFamily: 'Formula1',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              positionChange > 0
                  ? 'Gained $positionChange position${positionChange > 1 ? 's' : ''}!'
                  : positionChange < 0
                      ? 'Lost ${-positionChange} position${-positionChange > 1 ? 's' : ''}'
                      : 'Maintained position',
              style: TextStyle(
                color: positionChange > 0
                    ? Colors.green
                    : positionChange < 0
                        ? Colors.red
                        : Colors.white,
                fontFamily: 'Formula1',
                fontSize: 14,
              ),
            ),
            SizedBox(height: 15),
            Text(
              'P$PLAYER_STARTING_POSITION → P${playerDriver.position}',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Formula1',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetDemo();
            },
            child: Text(
              'TRY AGAIN',
              style: TextStyle(
                color: Colors.red[400],
                fontFamily: 'Formula1',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: Text(
              'CONTINUE',
              style: TextStyle(
                color: Colors.green[400],
                fontFamily: 'Formula1',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetDemo() {
    setState(() {
      raceCompleted = false;
      showMiniGame = false;
      playerResult = null;
      raceResults.clear();
    });

    _fadeController.reset();
    _gridController.reset();

    _setupRace();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Background gradient
          Container(
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
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: raceCompleted ? _buildResults() : _buildStartingGrid(),
                ),
              ],
            ),
          ),

          // Mini-game overlay
          if (showMiniGame) _buildMiniGameOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.red[600]!.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INTERACTIVE RACE DEMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Formula1',
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  raceCompleted
                      ? 'Race start completed - See results!'
                      : showMiniGame
                          ? 'Playing mini-game...'
                          : 'Preparing for race start...',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Formula1',
                  ),
                ),
              ],
            ),
          ),

          // Reset button (when race completed)
          if (raceCompleted)
            Container(
              decoration: BoxDecoration(
                color: Colors.red[600]!.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.refresh, color: Colors.red[400]),
                onPressed: _resetDemo,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStartingGrid() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.yellow[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'STARTING GRID',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Expanded(
                  child: ListView.builder(
                    itemCount: startingGrid.length,
                    itemBuilder: (context, index) {
                      Driver driver = startingGrid[index];
                      bool isPlayer = driver.name == PLAYER_NAME;

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPlayer
                                ? [Colors.red[600]!.withOpacity(0.3), Colors.red[800]!.withOpacity(0.1)]
                                : [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPlayer ? Colors.red[600]!.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Position
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isPlayer ? Colors.red[600] : Colors.grey[700],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: Text(
                                  '${driver.position}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Formula1',
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: 16),

                            // Driver info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driver.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Formula1',
                                    ),
                                  ),
                                  Text(
                                    driver.team.name,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                      fontFamily: 'Formula1',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Stats
                            if (!isPlayer)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'SPD ${driver.speed}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 10,
                                      fontFamily: 'Formula1',
                                    ),
                                  ),
                                  Text(
                                    'CAR ${driver.team.carPerformance}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 10,
                                      fontFamily: 'Formula1',
                                    ),
                                  ),
                                ],
                              ),

                            if (isPlayer)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[600],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'YOU',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Formula1',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Instructions
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.yellow[600]!.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.yellow[400], size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Get ready! You\'ll play a Launch Control mini-game to determine your race start performance.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Formula1',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResults() {
    return AnimatedBuilder(
      animation: _gridAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _gridAnimation.value)),
          child: Opacity(
            opacity: _gridAnimation.value,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'RACE START RESULTS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Formula1',
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Player result summary
                  if (playerResult != null) _buildPlayerSummary(),

                  SizedBox(height: 20),

                  Expanded(
                    child: ListView.builder(
                      itemCount: raceResults.length,
                      itemBuilder: (context, index) {
                        Driver driver = raceResults[index];
                        Driver originalDriver = startingGrid.firstWhere((d) => d.name == driver.name);
                        bool isPlayer = driver.name == PLAYER_NAME;
                        int positionChange = originalDriver.position - driver.position;

                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isPlayer
                                  ? [Colors.green[600]!.withOpacity(0.3), Colors.green[800]!.withOpacity(0.1)]
                                  : [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPlayer ? Colors.green[600]!.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Position
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: isPlayer ? Colors.green[600] : Colors.grey[700],
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Text(
                                    '${driver.position}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Formula1',
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: 16),

                              // Driver info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driver.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Formula1',
                                      ),
                                    ),
                                    Text(
                                      driver.team.name,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                        fontFamily: 'Formula1',
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Position change
                              if (positionChange != 0)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: positionChange > 0
                                        ? Colors.green[600]!.withOpacity(0.3)
                                        : Colors.red[600]!.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: positionChange > 0 ? Colors.green[600]! : Colors.red[600]!,
                                    ),
                                  ),
                                  child: Text(
                                    '${positionChange > 0 ? '+' : ''}$positionChange',
                                    style: TextStyle(
                                      color: positionChange > 0 ? Colors.green[400] : Colors.red[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Formula1',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            playerResult!.performance.color.withOpacity(0.3),
            playerResult!.performance.color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: playerResult!.performance.color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR PERFORMANCE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Formula1',
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playerResult!.performance.displayName,
                    style: TextStyle(
                      color: playerResult!.performance.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Formula1',
                    ),
                  ),
                  Text(
                    'Reaction: ${playerResult!.reactionTime.round()}ms',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontFamily: 'Formula1',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RPM Accuracy',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontFamily: 'Formula1',
                    ),
                  ),
                  Text(
                    '${(playerResult!.rpmAccuracy * 100).round()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Formula1',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGameOverlay() {
    Driver playerDriver = startingGrid.firstWhere((d) => d.name == PLAYER_NAME);

    return Container(
      color: Colors.black.withOpacity(0.9),
      child: LaunchControlGame(
        onGameComplete: _onMiniGameComplete,
        driverSpeed: playerDriver.speed,
        carPerformance: playerDriver.team.carPerformance,
      ),
    );
  }
}
