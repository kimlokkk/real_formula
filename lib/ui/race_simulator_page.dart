import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/driver.dart';
import '../models/enums.dart';
import '../models/track.dart';
import '../services/performance_calculator.dart';
import '../services/incident_simulator.dart';
import '../services/strategy_engine.dart';
import '../data/driver_data.dart';
import '../data/track_data.dart';
import '../utils/constants.dart';

class F1RaceSimulator extends StatefulWidget {
  @override
  _F1RaceSimulatorState createState() => _F1RaceSimulatorState();
}

class _F1RaceSimulatorState extends State<F1RaceSimulator> with TickerProviderStateMixin {
  List<Driver> drivers = [];
  int currentLap = 0;
  int totalLaps = F1Constants.defaultTotalLaps;
  bool isRacing = false;
  Timer? raceTimer;
  SimulationSpeed currentSpeed = SimulationSpeed.normal;
  WeatherCondition currentWeather = WeatherCondition.clear;
  Track currentTrack = TrackData.getDefaultTrack();

  late AnimationController _pulseController;

  // Track visualization animations
  late AnimationController _trackController;
  late Animation<double> _trackAnimation;

  int selectedTab = 0; // 0: Standings, 1: Track View, 2: Incidents

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
    _initializeTrackAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get configuration from setup page if available
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

    // Initialize race if not already done
    if (drivers.isEmpty) {
      _initializeRace();
    } else {
      _resetRaceWithCurrentConfig();
    }
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController.repeat(reverse: true);
  }

  void _initializeTrackAnimation() {
    _trackController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _trackAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _trackController, curve: Curves.linear),
    );
  }

  void _initializeRace() {
    drivers = DriverData.createDefaultDrivers();
    DriverData.initializeStartingGrid(drivers);
    totalLaps = currentTrack.totalLaps;

    for (Driver driver in drivers) {
      driver.currentCompound = driver.getWeatherAppropriateStartingCompound(currentWeather);
    }
  }

  void _resetRaceWithCurrentConfig() {
    DriverData.initializeStartingGrid(drivers);
    totalLaps = currentTrack.totalLaps;
    currentLap = 0;
    isRacing = false;
    raceTimer?.cancel();

    for (Driver driver in drivers) {
      driver.resetForNewRace();
      driver.currentCompound = driver.getWeatherAppropriateStartingCompound(currentWeather);
    }
  }

  List<String> _getAllIncidents() {
    List<String> allIncidents = [];
    for (Driver driver in drivers) {
      for (String incident in driver.raceIncidents) {
        allIncidents.add("${driver.name}: $incident");
      }
    }
    return allIncidents.reversed.take(20).toList();
  }

  void _simulateLap() {
    if (currentLap >= totalLaps) {
      print("=== RACE FINISHED ===");
      print("Final lap: $currentLap, Total laps: $totalLaps");
      _stopRace();
      _navigateToResults();
      return;
    }

    setState(() {
      currentLap++;

      for (int i = 0; i < drivers.length; i++) {
        Driver driver = drivers[i];
        if (driver.isDNF()) continue;

        double gapBehind = (i >= drivers.length - 1) ? 999.0 : drivers[i + 1].totalTime - driver.totalTime;
        double gapAhead = (i <= 0) ? 999.0 : driver.totalTime - drivers[i - 1].totalTime;

        if (StrategyEngine.shouldPitStop(driver, currentLap, totalLaps, gapBehind, gapAhead, currentTrack)) {
          StrategyEngine.executePitStop(
              driver, currentWeather, currentLap, totalLaps, gapAhead, gapBehind, currentTrack);
        }
      }

      for (Driver driver in drivers) {
        if (driver.isDNF()) continue;

        IncidentSimulator.processLapIncidents(driver, currentLap, totalLaps, currentWeather, currentTrack);
        if (driver.isDNF()) continue;

        double lapTime = PerformanceCalculator.calculateCurrentLapTime(driver, currentWeather, currentTrack);
        driver.totalTime += lapTime;
        driver.lapsCompleted++;
        driver.lapsOnCurrentTires++;
      }

      drivers.sort((a, b) {
        if (a.isDNF() && b.isDNF()) return 0;
        if (a.isDNF()) return 1;
        if (b.isDNF()) return -1;
        return a.totalTime.compareTo(b.totalTime);
      });

      for (int i = 0; i < drivers.length; i++) {
        drivers[i].updatePosition(i + 1);
      }
    });

    // Update track animation
    _trackController.forward().then((_) {
      _trackController.reset();
    });
  }

  void _changeSpeed(SimulationSpeed newSpeed) {
    setState(() {
      currentSpeed = newSpeed;
    });

    if (isRacing) {
      raceTimer?.cancel();
      raceTimer = Timer.periodic(Duration(milliseconds: currentSpeed.intervalMs), (timer) {
        _simulateLap();
      });
    }
  }

  void _startRace() {
    if (currentLap >= totalLaps) {
      _resetRace();
    }

    setState(() {
      isRacing = true;
    });

    raceTimer = Timer.periodic(Duration(milliseconds: currentSpeed.intervalMs), (timer) {
      _simulateLap();
    });
  }

  void _stopRace() {
    setState(() {
      isRacing = false;
    });
    raceTimer?.cancel();
  }

  void _resetRace() {
    setState(() {
      currentLap = 0;
      isRacing = false;
      totalLaps = currentTrack.totalLaps;
      DriverData.resetAllDriversForNewRace(drivers, currentWeather);
    });
    raceTimer?.cancel();
  }

  void _navigateToResults() {
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/results',
          arguments: {
            'drivers': drivers,
            'track': currentTrack,
            'weather': currentWeather,
            'totalLaps': totalLaps,
          },
        );
      }
    });
  }

  @override
  void dispose() {
    raceTimer?.cancel();
    _pulseController.dispose();
    _trackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildF1AppBar(),
      body: Column(
        children: [
          _buildSimpleRaceHeader(),
          _buildTabBar(),
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildF1AppBar() {
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
            'RACE SIMULATOR',
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
        onPressed: () {
          _showExitDialog();
        },
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              isRacing ? 'LIVE' : 'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'EXIT RACE',
            style: TextStyle(color: Colors.white, letterSpacing: 1),
          ),
          content: Text(
            'Are you sure you want to exit the race?',
            style: TextStyle(color: Colors.grey[400]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('CANCEL', style: TextStyle(color: Colors.grey[400])),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: Text('EXIT', style: TextStyle(color: Colors.red[600])),
            ),
          ],
        );
      },
    );
  }

  // Simplified race header - removed unnecessary controls
  Widget _buildSimpleRaceHeader() {
    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Essential race info only
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Lap counter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAP',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$currentLap / $totalLaps',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Track and weather info (compact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    currentTrack.name.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentWeather.icon,
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(width: 4),
                      Text(
                        currentWeather.name.toUpperCase(),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Race status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isRacing ? Colors.red[600] : Colors.grey[600],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isRacing ? 'RACING' : (currentLap >= totalLaps ? 'FINISHED' : 'STOPPED'),
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

          // Control buttons
          Row(
            children: [
              // Race controls
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    _buildControlButton(
                      label: currentLap >= totalLaps ? 'NEW RACE' : 'START',
                      onPressed: isRacing ? null : _startRace,
                      isPrimary: true,
                    ),
                    SizedBox(width: 8),
                    _buildControlButton(
                      label: 'STOP',
                      onPressed: isRacing ? _stopRace : null,
                      isPrimary: false,
                    ),
                    SizedBox(width: 8),
                    _buildControlButton(
                      label: 'RESET',
                      onPressed: isRacing ? null : _resetRace,
                      isPrimary: false,
                    ),
                  ],
                ),
              ),

              SizedBox(width: 16),

              // Speed control only
              Expanded(
                flex: 2,
                child: _buildSpeedControl(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isPrimary,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? (isPrimary ? Colors.red[600] : Colors.grey[700]) : Colors.grey[800],
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedControl() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPEED',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: SimulationSpeed.values.map((speed) {
              bool isSelected = currentSpeed == speed;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: speed != SimulationSpeed.values.last ? 2 : 0),
                  child: GestureDetector(
                    onTap: () => _changeSpeed(speed),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red[600] : Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          speed.label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    List<String> tabs = ['STANDINGS', 'LIVE TRACK', 'INCIDENTS'];
    List<IconData> icons = [Icons.format_list_numbered, Icons.track_changes, Icons.warning];

    return Container(
      color: Colors.grey[800],
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          int index = entry.key;
          String tab = entry.value;
          bool isSelected = selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = index),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red[600] : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Colors.red[600]! : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icons[index],
                      color: isSelected ? Colors.white : Colors.grey[400],
                      size: 16,
                    ),
                    SizedBox(height: 4),
                    Text(
                      tab,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedTab) {
      case 0:
        return _buildStandingsTable();
      case 1:
        return _buildCleanTrackVisualization();
      case 2:
        return _buildIncidentsPanel();
      default:
        return _buildStandingsTable();
    }
  }

  // Clean, simple track visualization - Linear view only
  Widget _buildCleanTrackVisualization() {
    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
          // Simple header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.track_changes, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text(
                  'LIVE TRACK POSITIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                // Live statistics
                Row(
                  children: [
                    _buildQuickStat('ACTIVE', '${drivers.where((d) => !d.isDNF()).length}', Colors.green),
                    SizedBox(width: 16),
                    _buildQuickStat('ERRORS', '${drivers.fold(0, (sum, d) => sum + d.errorCount)}', Colors.red),
                    SizedBox(width: 16),
                    _buildQuickStat('PITS', '${drivers.fold(0, (sum, d) => sum + d.pitStops)}', Colors.blue),
                  ],
                ),
              ],
            ),
          ),

          // Track visualization takes most of the space
          Expanded(
            child: CustomPaint(
              painter: CleanTrackPainter(
                drivers: drivers,
                currentLap: currentLap,
                totalLaps: totalLaps,
                trackAnimation: _trackAnimation,
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStandingsTable() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      color: Colors.grey[900],
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                return _buildDriverRow(drivers[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(
          bottom: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            child: Text(
              'POS',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'DRIVER',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 60,
            child: Text(
              'TIRE',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 100,
            child: Text(
              'TIME/GAP',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverRow(Driver driver, int index) {
    double gapToLeader = index == 0 ? 0.0 : (driver.isDNF() ? 0.0 : driver.totalTime - drivers[0].totalTime);
    bool isLeader = index == 0;

    return AnimatedContainer(
      key: ValueKey(driver.name),
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getRowColor(driver, index),
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: driver.isDNF() ? Colors.grey[600] : _getTeamColor(driver.team),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Text(
                      driver.isDNF() ? 'DNF' : '${driver.position}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: driver.isDNF() ? 8 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                if (driver.positionChangeFromStart != 0)
                  Icon(
                    driver.positionChangeFromStart > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: driver.positionChangeFromStart > 0 ? Colors.green : Colors.red,
                    size: 12,
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      driver.name.toUpperCase(),
                      style: TextStyle(
                        color: driver.isDNF() ? Colors.grey[500] : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (driver.hasActiveMechanicalIssue) ...[
                      SizedBox(width: 6),
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                    ],
                    if (driver.errorCount > 0) ...[
                      SizedBox(width: 6),
                      Icon(Icons.error, color: Colors.red, size: 16),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Text(
                      driver.team.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (driver.pitStops > 0) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${driver.pitStops} PIT${driver.pitStops > 1 ? 'S' : ''}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            child: Row(
              children: [
                Text(
                  driver.currentCompound.icon,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${driver.lapsOnCurrentTires}',
                        style: TextStyle(
                          color: _getTireWearColor(driver.calculateTyreDegradation()),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        height: 2,
                        width: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(1),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (driver.calculateTyreDegradation() / 3.0).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getTireWearColor(driver.calculateTyreDegradation()),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 100,
            child: Text(
              driver.isDNF() ? 'DNF' : (isLeader ? 'LEADER' : '+${gapToLeader.toStringAsFixed(1)}'),
              style: TextStyle(
                color: driver.isDNF() ? Colors.grey[500] : (isLeader ? Colors.yellow : Colors.white),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTireWearColor(double degradation) {
    if (degradation <= 0.5) return Colors.green;
    if (degradation <= 1.0) return Colors.yellow[700]!;
    if (degradation <= 1.5) return Colors.orange;
    if (degradation <= 2.0) return Colors.red[600]!;
    return Colors.red[800]!;
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
      case "Williams":
        return Colors.grey[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Color _getRowColor(Driver driver, int index) {
    if (driver.isDNF()) return Colors.grey[850]!;
    if (index == 0) return Colors.yellow.withOpacity(0.1);
    if (index == 1) return Colors.grey[300]!.withOpacity(0.1);
    if (index == 2) return Colors.orange.withOpacity(0.1);
    if (index < 10) return Colors.green.withOpacity(0.05);
    return Colors.grey[900]!;
  }

  Widget _buildIncidentsPanel() {
    List<String> incidents = _getAllIncidents();

    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
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
                Icon(Icons.warning, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text(
                  'RACE INCIDENTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
                    ),
                  ),
                  child: Text(
                    incidents[index],
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Clean, simple track painter - Linear view optimized for clarity
class CleanTrackPainter extends CustomPainter {
  final List<Driver> drivers;
  final int currentLap;
  final int totalLaps;
  final Animation<double> trackAnimation;

  CleanTrackPainter({
    required this.drivers,
    required this.currentLap,
    required this.totalLaps,
    required this.trackAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintLinearTrack(canvas, size);
  }

  void _paintLinearTrack(Canvas canvas, Size size) {
    // Use much more space - track takes up most of the screen
    final trackHeight = size.height * 0.5; // 50% of screen height
    final trackY = size.height * 0.15; // Start higher up
    final trackWidth = size.width - 40; // Use almost full width
    final trackStartX = 20.0;

    // Draw track
    _drawCleanTrack(canvas, trackStartX, trackY, trackWidth, trackHeight);

    // Draw lap markers
    _drawLapMarkers(canvas, trackStartX, trackY, trackWidth, trackHeight);

    // Draw cars
    _drawCarsOnTrack(canvas, trackStartX, trackY, trackWidth, trackHeight);

    // Draw info
    _drawTrackInfo(canvas, size, trackStartX, trackY, trackWidth);
  }

  void _drawCleanTrack(Canvas canvas, double startX, double trackY, double width, double height) {
    // Much larger track background
    final trackPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.fill;

    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX, trackY, width, height),
      Radius.circular(16),
    );

    canvas.drawRRect(trackRect, trackPaint);

    // Thicker track boundaries
    final boundaryPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawRRect(trackRect, boundaryPaint);

    // More prominent racing line in center
    final racingLinePaint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawLine(
      Offset(startX + 40, trackY + height / 2),
      Offset(startX + width - 40, trackY + height / 2),
      racingLinePaint,
    );

    // Larger start/finish line
    final startLinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawLine(
      Offset(startX + 40, trackY - 10),
      Offset(startX + 40, trackY + height + 10),
      startLinePaint,
    );

    // Larger checkered pattern for start/finish
    final checkerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 10; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(startX + 36 + (i % 2) * 4, trackY + i * 8, 4, 8),
          checkerPaint,
        );
      }
    }

    // Add "START/FINISH" text
    final startTextPainter = TextPainter(
      text: TextSpan(
        text: 'START/FINISH',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    startTextPainter.layout();
    startTextPainter.paint(
      canvas,
      Offset(startX + 45, trackY - 50),
    );
  }

  void _drawLapMarkers(Canvas canvas, double startX, double trackY, double width, double height) {
    // Draw lap markers every 10 laps
    for (int lap = 0; lap <= totalLaps; lap += 10) {
      if (lap == 0) continue; // Skip start line

      double x = startX + 40 + (lap / totalLaps) * (width - 80);

      final markerPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawLine(
        Offset(x, trackY + 20),
        Offset(x, trackY + height - 20),
        markerPaint,
      );

      // Larger lap numbers
      final lapTextPainter = TextPainter(
        text: TextSpan(
          text: '$lap',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      lapTextPainter.layout();
      lapTextPainter.paint(canvas, Offset(x - lapTextPainter.width / 2, trackY - 30));
    }
  }

  void _drawCarsOnTrack(Canvas canvas, double startX, double trackY, double width, double height) {
    if (drivers.isEmpty || totalLaps == 0) return;

    // Calculate car positions based on their progress
    List<CarTrackPosition> carPositions = _calculateCarTrackPositions(startX, trackY, width, height);

    // Draw cars in order
    for (CarTrackPosition carPos in carPositions) {
      _drawCarOnTrack(canvas, carPos);
    }

    // Draw position gaps
    _drawPositionGaps(canvas, carPositions);
  }

  List<CarTrackPosition> _calculateCarTrackPositions(double startX, double trackY, double width, double height) {
    List<CarTrackPosition> positions = [];

    if (drivers.isEmpty) return positions;

    // Get leader for reference
    Driver leader = drivers.firstWhere((d) => !d.isDNF(), orElse: () => drivers.first);
    double leaderTime = leader.totalTime;

    // Available height for cars - use more lanes to spread them out
    final availableHeight = height - 40; // Leave margins
    final numLanes = min(12, max(8, drivers.length)); // 8-12 lanes depending on driver count
    final laneHeight = availableHeight / numLanes;

    for (int i = 0; i < drivers.length; i++) {
      Driver driver = drivers[i];
      if (driver.isDNF()) continue;

      // Better progress calculation - spread cars out more
      double progress;
      if (currentLap == 0) {
        // At start, spread cars out in starting grid formation
        progress = 0.02 + (i * 0.015); // Small spacing at start
      } else {
        // During race, use time gaps
        double timeGap = driver.totalTime - leaderTime;
        double averageLapTime = 90.0;
        double lapsBehind = timeGap / averageLapTime;

        // Enhanced progress calculation
        progress = ((currentLap + driver.lapsCompleted - lapsBehind) / totalLaps);
        progress = progress.clamp(0.0, 0.95); // Don't let cars go off track
      }

      // Position on track - use more width
      double x = startX + 40 + progress * (width - 80);

      // Better lane assignment - distribute more evenly
      int lane;
      if (i < 3) {
        // Top 3 in center lanes
        lane = numLanes ~/ 2 + (i - 1);
      } else {
        // Others distributed around
        lane = i % numLanes;
      }

      double y = trackY + 20 + (lane * laneHeight) + (laneHeight / 2);

      positions.add(CarTrackPosition(
        driver: driver,
        x: x,
        y: y,
        progress: progress,
        timeGap: driver.totalTime - leaderTime,
      ));
    }

    return positions;
  }

  void _drawCarOnTrack(Canvas canvas, CarTrackPosition carPos) {
    final driver = carPos.driver;
    final x = carPos.x;
    final y = carPos.y;

    // Much larger car body since we have more space
    final carPaint = Paint()
      ..color = _getTeamColor(driver.team)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Larger car shape
    final carRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y), width: 60, height: 24),
      Radius.circular(12),
    );

    canvas.drawRRect(carRect, carPaint);
    canvas.drawRRect(carRect, outlinePaint);

    // Much larger position number
    final positionTextPainter = TextPainter(
      text: TextSpan(
        text: '${driver.position}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    positionTextPainter.layout();

    // Position background
    final numberBgPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final numberRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y),
        width: positionTextPainter.width + 10,
        height: positionTextPainter.height + 6,
      ),
      Radius.circular(6),
    );

    canvas.drawRRect(numberRect, numberBgPaint);
    positionTextPainter.paint(
      canvas,
      Offset(x - positionTextPainter.width / 2, y - positionTextPainter.height / 2),
    );

    // Driver name above car (larger)
    final nameTextPainter = TextPainter(
      text: TextSpan(
        text: driver.name.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    nameTextPainter.layout();
    nameTextPainter.paint(
      canvas,
      Offset(x - nameTextPainter.width / 2, y - 45),
    );

    // Larger tire compound indicator
    final tireColor = _getTireCompoundColor(driver.currentCompound);
    final tirePaint = Paint()
      ..color = tireColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x + 35, y - 15), 8, tirePaint);

    // Larger status indicators
    if (driver.hasActiveMechanicalIssue) {
      final mechanicalPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x + 35, y + 15), 6, mechanicalPaint);
    }

    if (driver.errorCount > 0) {
      final errorPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x - 35, y + 15), 6, errorPaint);
    }
  }

  void _drawPositionGaps(Canvas canvas, List<CarTrackPosition> positions) {
    // Draw gap lines between consecutive positions
    final gapPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i < positions.length; i++) {
      CarTrackPosition current = positions[i];
      CarTrackPosition previous = positions[i - 1];

      // Only show gaps less than 30 seconds
      if (current.timeGap > 30.0) continue;

      // Draw connection line
      canvas.drawLine(
        Offset(previous.x, previous.y + 12),
        Offset(current.x, current.y + 12),
        gapPaint,
      );

      // Gap time text
      if (current.timeGap > 0.1) {
        final gapTextPainter = TextPainter(
          text: TextSpan(
            text: '+${current.timeGap.toStringAsFixed(1)}s',
            style: TextStyle(
              color: Colors.yellow,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        gapTextPainter.layout();

        double midX = (previous.x + current.x) / 2;
        double midY = (previous.y + current.y) / 2 + 20;

        gapTextPainter.paint(
          canvas,
          Offset(midX - gapTextPainter.width / 2, midY),
        );
      }
    }
  }

  void _drawTrackInfo(Canvas canvas, Size size, double startX, double trackY, double width) {
    // Position progress bar below the track
    double progressBarY = trackY + size.height * 0.5 + 20;
    double progress = (currentLap / totalLaps).clamp(0.0, 1.0);

    // Progress background
    final progressBgPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, progressBarY, width, 12),
        Radius.circular(6),
      ),
      progressBgPaint,
    );

    // Progress fill
    final progressPaint = Paint()
      ..color = Colors.red[600]!
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, progressBarY, width * progress, 12),
        Radius.circular(6),
      ),
      progressPaint,
    );

    // Lap indicator (larger text)
    final lapTextPainter = TextPainter(
      text: TextSpan(
        text: 'LAP $currentLap / $totalLaps',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    lapTextPainter.layout();
    lapTextPainter.paint(canvas, Offset(startX, progressBarY + 25));

    // Race completion percentage
    final percentTextPainter = TextPainter(
      text: TextSpan(
        text: '${(progress * 100).toInt()}% COMPLETE',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    percentTextPainter.layout();
    percentTextPainter.paint(canvas, Offset(size.width - startX - percentTextPainter.width, progressBarY + 25));

    // Legend at bottom
    _drawSimpleLegend(canvas, size);
  }

  void _drawSimpleLegend(Canvas canvas, Size size) {
    final legendY = size.height - 60; // Closer to bottom

    // Tire compounds (more compact)
    final compounds = [
      {'name': 'SOFT', 'color': Colors.red},
      {'name': 'MED', 'color': Colors.yellow},
      {'name': 'HARD', 'color': Colors.white},
      {'name': 'INTER', 'color': Colors.green},
      {'name': 'WET', 'color': Colors.blue},
    ];

    double compoundStartX = 30.0;
    for (int i = 0; i < compounds.length; i++) {
      final compound = compounds[i];
      final x = compoundStartX + i * 70;

      final tirePaint = Paint()
        ..color = compound['color'] as Color
        ..style = PaintingStyle.fill;

      // Larger tire indicators
      canvas.drawCircle(Offset(x, legendY), 10, tirePaint);

      // White outline for visibility
      final outlinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(x, legendY), 10, outlinePaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: compound['name'] as String,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, legendY + 15));
    }

    // Status indicators (right side, more compact)
    final statusStartX = size.width - 180;
    final statusItems = [
      {'label': 'ERROR', 'color': Colors.red},
      {'label': 'MECHANICAL', 'color': Colors.orange},
    ];

    for (int i = 0; i < statusItems.length; i++) {
      final item = statusItems[i];
      final x = statusStartX + i * 90;

      final statusPaint = Paint()
        ..color = item['color'] as Color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, legendY), 8, statusPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: item['label'] as String,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 12, legendY - textPainter.height / 2));
    }
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
      case "Williams":
        return Colors.grey[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Color _getTireCompoundColor(TireCompound compound) {
    switch (compound) {
      case TireCompound.soft:
        return Colors.red;
      case TireCompound.medium:
        return Colors.yellow;
      case TireCompound.hard:
        return Colors.white;
      case TireCompound.intermediate:
        return Colors.green;
      case TireCompound.wet:
        return Colors.blue;
    }
  }

  @override
  bool shouldRepaint(CleanTrackPainter oldDelegate) {
    return oldDelegate.currentLap != currentLap ||
        oldDelegate.drivers != drivers ||
        oldDelegate.trackAnimation != trackAnimation;
  }
}

// Helper class for car positioning on linear track
class CarTrackPosition {
  final Driver driver;
  final double x;
  final double y;
  final double progress;
  final double timeGap;

  CarTrackPosition({
    required this.driver,
    required this.x,
    required this.y,
    required this.progress,
    required this.timeGap,
  });
}
