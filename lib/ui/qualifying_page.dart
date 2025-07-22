// lib/ui/qualifying_page.dart - Fixed version
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
  @override
  _QualifyingPageState createState() => _QualifyingPageState();
}

class _QualifyingPageState extends State<QualifyingPage> {
  // Configuration
  List<Driver> drivers = [];
  Track currentTrack = TrackData.getDefaultTrack();
  WeatherCondition currentWeather = WeatherCondition.clear;
  SimulationSpeed currentSpeed = SimulationSpeed.normal;

  // Qualifying state
  QualifyingStatus status = QualifyingStatus.waiting;
  List<QualifyingResult> results = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      currentTrack = args['track'] ?? TrackData.getDefaultTrack();
      currentWeather = args['weather'] ?? WeatherCondition.clear;
      currentSpeed = args['speed'] ?? SimulationSpeed.normal;
      List<Driver>? configDrivers = args['drivers'];
      if (configDrivers != null) {
        drivers = List.from(configDrivers);
      }
    }

    if (drivers.isEmpty) {
      drivers = DriverData.createDefaultDrivers();
    }
  }

  // FIXED: Handle the case where no "Rookie" driver exists
  Future<void> _startQualifying() async {
    setState(() {
      status = QualifyingStatus.running;
    });

    // Show qualifying in progress for 1 second
    await Future.delayed(Duration(seconds: 1));

    // FIXED: Properly handle null case when no "Rookie" driver exists
    Driver? userDriver;
    try {
      userDriver = drivers.firstWhere((d) => d.name == "Rookie");
    } catch (e) {
      userDriver = null; // No "Rookie" driver found
    }

    List<QualifyingResult> qualifyingResults = [];

    if (userDriver != null) {
      // User driver exists - show minigame for them, simulate others
      qualifyingResults = await _simulateQualifyingWithUserDriver(userDriver);
    } else {
      // No user driver - normal AI simulation for all drivers
      qualifyingResults = QualifyingEngine.simulateQualifying(
        drivers,
        currentWeather,
        currentTrack,
      );
    }

    // Apply results to drivers
    QualifyingEngine.applyQualifyingResults(drivers, qualifyingResults);

    setState(() {
      results = qualifyingResults;
      status = QualifyingStatus.finished;
    });
  }

  // Handle qualifying with user driver minigame
  Future<List<QualifyingResult>> _simulateQualifyingWithUserDriver(Driver userDriver) async {
    List<QualifyingResult> allResults = [];

    // First, simulate all AI drivers
    List<Driver> aiDrivers = drivers.where((d) => d.name != "Rookie").toList();

    for (Driver driver in aiDrivers) {
      double lapTime = QualifyingEngine.calculateQualifyingLapTime(
        driver,
        currentWeather,
        currentTrack,
      );

      TireCompound bestTire = currentWeather == WeatherCondition.rain ? TireCompound.intermediate : TireCompound.soft;

      // Apply tire performance
      lapTime += bestTire.lapTimeDelta;

      allResults.add(QualifyingResult(
        driver: driver,
        bestLapTime: lapTime,
        position: 0, // Will be set after sorting
        session: QualifyingSession.QUALIFYING,
        bestTire: bestTire,
      ));
    }

    // Show message that it's user's turn
    await _showUserTurnMessage();

    // Now show minigame for user driver
    QualifyingTimingResult? userResult = await showDialog<QualifyingTimingResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => QualifyingTimingChallenge(
        driver: userDriver,
        track: currentTrack,
        weather: currentWeather,
      ),
    );

    // Calculate user's lap time based on minigame result
    double userLapTime = _calculateUserQualifyingTime(userDriver, userResult);

    TireCompound userTire = currentWeather == WeatherCondition.rain ? TireCompound.intermediate : TireCompound.soft;

    // Add user result
    allResults.add(QualifyingResult(
      driver: userDriver,
      bestLapTime: userLapTime,
      position: 0, // Will be set after sorting
      session: QualifyingSession.QUALIFYING,
      bestTire: userTire,
    ));

    // Sort all results by lap time and assign positions
    allResults.sort((a, b) => a.bestLapTime.compareTo(b.bestLapTime));

    double poleTime = allResults.isNotEmpty ? allResults.first.bestLapTime : 0.0;

    for (int i = 0; i < allResults.length; i++) {
      double gapToPole = i == 0 ? 0.0 : allResults[i].bestLapTime - poleTime;

      allResults[i] = allResults[i].copyWith(
        position: i + 1,
        gapToPole: gapToPole,
      );
    }

    return allResults;
  }

  // Show user turn message
  Future<void> _showUserTurnMessage() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 300,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[600]!, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, color: Colors.blue[600], size: 48),
              SizedBox(height: 16),
              Text(
                'YOUR TURN!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Time to set your qualifying lap',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
                child: Text('START LAP'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Calculate user's qualifying time based on minigame result
  double _calculateUserQualifyingTime(Driver userDriver, QualifyingTimingResult? result) {
    // Base qualifying time for user driver
    double baseTime = currentTrack.baseLapTime * 0.97; // Qualifying pace

    // Apply driver skills
    double speedFactor = (100 - userDriver.speed) * 0.015;
    double consistencyFactor = (100 - userDriver.consistency) * 0.008;
    double carFactor = (100 - userDriver.team.carPerformance) * 0.018;

    double driverAdjustedTime = baseTime + speedFactor + consistencyFactor + carFactor;

    // Apply weather penalty if any
    if (currentWeather == WeatherCondition.rain) {
      double weatherPenalty = 2.5 + ((100 - userDriver.consistency) / 100.0 * 1.5);
      driverAdjustedTime += weatherPenalty;
    }

    // Apply minigame result
    if (result != null) {
      driverAdjustedTime += result.timeModifier;
    } else {
      // If somehow no result, apply bad penalty
      driverAdjustedTime += 0.4;
    }

    return driverAdjustedTime;
  }

  void _proceedToRace() {
    Navigator.pushReplacementNamed(
      context,
      '/race',
      arguments: {
        'track': currentTrack,
        'weather': currentWeather,
        'speed': currentSpeed,
        'drivers': drivers,
        'qualifyingResults': results,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
          if (status == QualifyingStatus.finished) _buildProceedButton(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.red[600],
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'F1',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'QUALIFYING',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUALIFYING SESSION',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Single session • Grid positions 1-${drivers.length}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: status.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                '${currentTrack.name.toUpperCase()} • ${currentWeather.icon} ${currentWeather.name.toUpperCase()}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag,
              size: 80,
              color: Colors.red[600],
            ),
            SizedBox(height: 24),
            Text(
              'READY FOR QUALIFYING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '${drivers.length} drivers will compete for pole position',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 48),
            Container(
              width: 300,
              height: 60,
              child: ElevatedButton(
                onPressed: _startQualifying,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      size: 28,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'START QUALIFYING',
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
          ],
        ),
      ),
    );
  }

  Widget _buildRunningScreen() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spinning animation
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'QUALIFYING IN PROGRESS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Drivers are setting their fastest laps...',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.yellow, size: 20),
                SizedBox(width: 8),
                Text(
                  'QUALIFYING RESULTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Spacer(),
                if (results.isNotEmpty) ...[
                  Text(
                    'POLE: ${results.first.driver.name.toUpperCase()}',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Results table header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(width: 40, child: Text('POS', style: _headerStyle())),
                Expanded(flex: 3, child: Text('DRIVER', style: _headerStyle())),
                Container(width: 80, child: Text('TIME', style: _headerStyle())),
                Container(width: 60, child: Text('TIRE', style: _headerStyle())),
                Container(width: 80, child: Text('GAP', style: _headerStyle())),
              ],
            ),
          ),

          // Results list
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                return _buildResultRow(results[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(QualifyingResult result, int index) {
    bool isPole = result.position == 1;
    bool isTopThree = result.position <= 3;

    Color rowColor = isPole
        ? Colors.yellow.withOpacity(0.1)
        : isTopThree
            ? Colors.green.withOpacity(0.05)
            : Colors.grey[900]!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
          left: isPole ? BorderSide(color: Colors.yellow, width: 4) : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // Position
          Container(
            width: 40,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _getTeamColor(result.driver.team.name),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '${result.position}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Driver
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.driver.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  result.driver.team.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Time
          Container(
            width: 80,
            child: Text(
              result.formattedLapTime,
              style: TextStyle(
                color: isPole ? Colors.yellow : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),

          // Tire
          Container(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  result.bestTire.icon,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 4),
                Text(
                  result.bestTire.name[0],
                  style: TextStyle(
                    color: result.bestTire.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Gap
          Container(
            width: 80,
            child: Text(
              result.formattedGap,
              style: TextStyle(
                color: isPole ? Colors.yellow : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProceedButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          top: BorderSide(color: Colors.green, width: 3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'QUALIFYING COMPLETE',
            style: TextStyle(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _proceedToRace,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_motorsports,
                    size: 24,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'PROCEED TO RACE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward,
                    size: 24,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTeamColor(String team) {
    switch (team) {
      case "Mercedes":
        return Colors.teal;
      case "Red Bull":
        return Colors.blue[700]!;
      case "Ferrari":
        return Colors.red[600]!;
      case "McLaren":
        return Colors.orange[600]!;
      case "Aston Martin":
        return Colors.green[600]!;
      case "Alpine":
        return Colors.pink[400]!;
      case "Haas":
        return Colors.grey[600]!;
      case "Racing Bulls":
        return Colors.blue[400]!;
      case "Williams":
        return Colors.blue[300]!;
      case "Sauber":
        return Colors.green[300]!;
      default:
        return Colors.grey[600]!;
    }
  }

  TextStyle _headerStyle() {
    return TextStyle(
      color: Colors.grey[400],
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );
  }
}
