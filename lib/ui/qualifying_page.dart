// lib/ui/qualifying_page.dart - Clean Professional F1 Design
import 'package:flutter/material.dart';
import 'package:real_formula/ui/minigames/qualifying_timing_challenge.dart';
import 'dart:async';
import '../models/driver.dart';
import '../models/track.dart';
import '../models/enums.dart';
import '../models/qualifying.dart';
import '../services/qualifying_engine.dart';
import '../data/track_data.dart';
import '../data/driver_data.dart';

class QualifyingPage extends StatefulWidget {
  const QualifyingPage({Key? key}) : super(key: key);

  @override
  _QualifyingPageState createState() => _QualifyingPageState();
}

class _QualifyingPageState extends State<QualifyingPage> with TickerProviderStateMixin {
  // Configuration
  List<Driver> drivers = [];
  Track currentTrack = TrackData.getDefaultTrack();
  WeatherCondition currentWeather = WeatherCondition.clear;
  SimulationSpeed currentSpeed = SimulationSpeed.normal;

  // Qualifying state
  QualifyingStatus status = QualifyingStatus.waiting;
  List<QualifyingResult> results = [];

  // PRESERVE: Add missing variable declaration
  QualifyingTimingResult? playerMinigameResult;

  // Clean animations - just fade
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      // Get configuration from arguments
      currentTrack = args['track'] ?? TrackData.getDefaultTrack();
      currentWeather = args['weather'] ?? WeatherCondition.clear;
      currentSpeed = args['speed'] ?? SimulationSpeed.normal;

      // Check if this is pre-configured from career mode loading screen
      bool isPreConfigured = args['preConfigured'] ?? false;

      List<Driver>? configDrivers = args['drivers'];
      if (configDrivers != null) {
        drivers = List.from(configDrivers);
      }

      // PRESERVE: Handle pre-configured career mode sessions
      if (isPreConfigured) {
        // Drivers and settings are already configured by loading screen
        // Just initialize if drivers are empty (fallback)
        if (drivers.isEmpty) {
          drivers = DriverData.createDefaultDrivers();
        }

        // Show career mode indicators
        if (args['careerMode'] == true) {}
      } else {
        // Original logic for manual race setup
        if (drivers.isEmpty) {
          drivers = DriverData.createDefaultDrivers();
        }
      }
    } else {
      // Fallback: No arguments provided
      if (drivers.isEmpty) {
        drivers = DriverData.createDefaultDrivers();
      }
    }
  }

  // PRESERVE: Handle the case where no "Rookie" driver exists
  Future<void> _startQualifying() async {
    if (!mounted) return;

    setState(() {
      status = QualifyingStatus.running;
    });

    // Show qualifying in progress for 1 second
    await Future.delayed(Duration(seconds: 1));

    if (!mounted) return;

    // Get route arguments to check for career mode
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    bool isCareerMode = args?['careerMode'] ?? false;

    // PRESERVE: Find player driver properly
    Driver? playerDriver;
    if (isCareerMode && args?['careerDriver'] != null) {
      // In career mode, find the career driver
      final careerDriver = args!['careerDriver'];
      playerDriver = drivers.where((d) => d.name == careerDriver.name).isNotEmpty
          ? drivers.firstWhere((d) => d.name == careerDriver.name)
          : drivers.first;
    } else {
      // In quick race, look for "Rookie" driver (original logic)
      try {
        playerDriver = drivers.firstWhere((d) => d.name.contains("Rookie"));
      } catch (e) {
        playerDriver = drivers.first; // Fallback to first driver
      }
    }

    if (isCareerMode && mounted) {
      // PRESERVE: Show timing mini-game for career mode with proper parameters
      final result = await Navigator.push<QualifyingTimingResult>(
        context,
        MaterialPageRoute(
          builder: (context) => QualifyingTimingChallenge(
            driver: playerDriver!,
            track: currentTrack,
            weather: currentWeather,
          ),
        ),
      );

      if (mounted) {
        playerMinigameResult = result;
      }
    }

    if (!mounted) return;

    // PRESERVE: Generate qualifying results with correct parameter order
    results = QualifyingEngine.simulateQualifying(
      drivers,
      currentWeather,
      currentTrack,
      playerDriver: playerDriver,
      playerMinigameResult: playerMinigameResult,
    );

    // CRITICAL: Apply qualifying results to set starting grid positions
    QualifyingEngine.applyQualifyingResults(drivers, results);

    if (mounted) {
      setState(() {
        status = QualifyingStatus.finished;
      });
    }
  }

  // PRESERVE: Navigation to race
  void _proceedToRace() {
    Map<String, dynamic> raceArguments = {
      'track': currentTrack,
      'weather': currentWeather,
      'speed': currentSpeed,
      'drivers': drivers, // Drivers now have correct positions from applyQualifyingResults
      'hasQualifyingResults': true, // Flag to use qualifying grid setup
    };

    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      raceArguments['careerMode'] = args['careerMode'] ?? false;
      raceArguments['careerDriver'] = args['careerDriver'];
      raceArguments['raceWeekend'] = args['raceWeekend'];
      raceArguments['isCalendarRace'] = args['isCalendarRace'] ?? false;
    }

    Navigator.pushNamed(context, '/race', arguments: raceArguments);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundGradient(),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildContent()),
                if (status == QualifyingStatus.finished) _buildProceedButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Match career home page background
  BoxDecoration _buildBackgroundGradient() {
    return BoxDecoration(
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
          // Back button - match career home style
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

          // Racing stripe - match career home style
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
                  'QUALIFYING SESSION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '${currentTrack.name} • ${currentWeather.name.toUpperCase()}',
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

          // Session status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
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

  Color _getStatusColor() {
    switch (status) {
      case QualifyingStatus.waiting:
        return Colors.orange[400]!;
      case QualifyingStatus.running:
        return Colors.green[400]!;
      case QualifyingStatus.finished:
        return Colors.blue[400]!;
    }
  }

  String _getStatusText() {
    switch (status) {
      case QualifyingStatus.waiting:
        return 'READY';
      case QualifyingStatus.running:
        return 'LIVE';
      case QualifyingStatus.finished:
        return 'COMPLETE';
    }
  }

  Widget _buildContent() {
    switch (status) {
      case QualifyingStatus.waiting:
        return _buildWaitingScreen();
      case QualifyingStatus.running:
        return _buildRunningScreen();
      case QualifyingStatus.finished:
        return _buildResultsScreen();
    }
  }

  Widget _buildWaitingScreen() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Spacer(),

          // Centered icon and title from v2
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red[600]!.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.red[600]!.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.sports_motorsports,
              size: 64,
              color: Colors.red[400],
            ),
          ),

          SizedBox(height: 32),

          // Main title from v2
          Text(
            'READY FOR QUALIFYING',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFamily: 'Formula1',
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16),

          // Subtitle
          Text(
            '${drivers.length} drivers will compete for pole position',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Formula1',
            ),
            textAlign: TextAlign.center,
          ),

          Spacer(),

          // Start Button - match career home style
          Container(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startQualifying,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
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
                    Icons.play_arrow,
                    size: 24,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'START QUALIFYING',
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

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRunningScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated progress indicator from v2
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    strokeWidth: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green[400]!),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green[400]!.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.timer,
                    size: 40,
                    color: Colors.green[400],
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),

            // Main status text
            Text(
              'QUALIFYING IN PROGRESS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: 'Formula1',
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),

            // Subtitle
            Text(
              'Drivers are setting their fastest laps...',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: 'Formula1',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Results Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'QUALIFYING RESULTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Formula1',
                      letterSpacing: 1,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'FINAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  return _buildResultItem(result, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(QualifyingResult result, int index) {
    bool isPole = index == 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Position
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isPole ? Colors.yellow[600] : Colors.grey[700],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
                  result.driver.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
                Text(
                  result.driver.team.name,
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

          // Lap time
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result.formattedLapTime,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Formula1',
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProceedButton() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _proceedToRace,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
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
                Icons.flag,
                size: 24,
                color: Colors.white,
              ),
              SizedBox(width: 12),
              Text(
                'PROCEED TO RACE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                  letterSpacing: 1,
                ),
              ),
              SizedBox(width: 12),
              Icon(
                Icons.arrow_forward,
                size: 20,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
