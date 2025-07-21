import 'package:flutter/material.dart';
import 'dart:async';
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
  bool raceFinished = false; // Track if race has finished
  Timer? raceTimer;
  SimulationSpeed currentSpeed = SimulationSpeed.normal;
  WeatherCondition currentWeather = WeatherCondition.clear;
  Track currentTrack = TrackData.getDefaultTrack();

  late AnimationController _pulseController;

  int selectedTab = 0; // 0: Standings, 1: Incidents

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get configuration from setup page if available
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    bool hasQualifyingResults = false;

    if (args != null) {
      currentTrack = args['track'] ?? TrackData.getDefaultTrack();
      currentWeather = args['weather'] ?? WeatherCondition.clear;
      currentSpeed = args['speed'] ?? SimulationSpeed.normal;
      List<Driver>? configDrivers = args['drivers'];
      if (configDrivers != null) {
        drivers = List.from(configDrivers);
      }

      // NEW: Check if qualifying results exist
      List<dynamic>? qualifyingResults = args['qualifyingResults'];
      if (qualifyingResults != null) {
        hasQualifyingResults = true;
        _processQualifyingResults(qualifyingResults);
      }
    }

    // Initialize race if not already done
    if (drivers.isEmpty) {
      _initializeRace();
    } else {
      // Only reset if NO qualifying results (preserve qualifying grid)
      if (!hasQualifyingResults) {
        _resetRaceWithCurrentConfig();
      } else {
        _resetRaceWithQualifyingGrid();
      }
    }
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController.repeat(reverse: true);
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
    raceFinished = false; // Reset race finished state
    raceTimer?.cancel();

    for (Driver driver in drivers) {
      driver.resetForNewRace();
      driver.currentCompound = driver.getWeatherAppropriateStartingCompound(currentWeather);
    }
  }

  // NEW: Reset race but preserve qualifying grid positions
  void _resetRaceWithQualifyingGrid() {
    _debugPrintGrid("BEFORE reset with qualifying grid");

    // DON'T call DriverData.initializeStartingGrid - preserve qualifying positions!
    totalLaps = currentTrack.totalLaps;
    currentLap = 0;
    isRacing = false;
    raceFinished = false;
    raceTimer?.cancel();

    for (Driver driver in drivers) {
      // Preserve starting position and current tire choice from qualifying
      int savedStartingPosition = driver.startingPosition;
      int savedPosition = driver.position;
      TireCompound savedCompound = driver.currentCompound;
      bool savedFreeTireChoice = driver.hasFreeTireChoice;

      // Reset race data
      driver.resetForNewRace();

      // Restore qualifying results
      driver.startingPosition = savedStartingPosition;
      driver.position = savedPosition;
      driver.currentCompound = savedCompound;
      driver.hasFreeTireChoice = savedFreeTireChoice;
      driver.positionChangeFromStart = 0;
    }

    // Sort drivers by their qualifying positions to ensure correct order
    drivers.sort((a, b) => a.position.compareTo(b.position));

    _debugPrintGrid("AFTER reset with qualifying grid");
  }

  // NEW: Process qualifying results
  void _processQualifyingResults(List<dynamic> qualifyingResults) {
    // Add qualifying info to race incidents
    if (qualifyingResults.isNotEmpty && drivers.isNotEmpty) {
      _debugPrintGrid("BEFORE processing qualifying results");

      // Find pole sitter (should be P1)
      Driver polePosition = drivers.firstWhere((d) => d.position == 1, orElse: () => drivers.first);

      print("=== QUALIFYING INTEGRATION ===");
      print("Processed qualifying results for ${drivers.length} drivers");
      print("Pole position: ${polePosition.name} (P${polePosition.position})");
      print("Starting grid preserved from qualifying");

      // Drivers already have their starting positions and tire choices set by qualifying engine
      // Just ensure the list is sorted by position
      drivers.sort((a, b) => a.position.compareTo(b.position));

      _debugPrintGrid("AFTER processing qualifying results");
    }
  }

  // NEW: Debug method to verify grid positions
  void _debugPrintGrid(String context) {
    print("=== GRID DEBUG: $context ===");
    for (int i = 0; i < drivers.length; i++) {
      Driver driver = drivers[i];
      print(
          "Index $i: ${driver.name} - Position: ${driver.position}, StartPos: ${driver.startingPosition}, Tire: ${driver.currentCompound.name}");
    }
    print("=== END GRID DEBUG ===");
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
      // Set race finished instead of auto-navigating
      setState(() {
        raceFinished = true;
      });
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
    if (raceFinished) {
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
      raceFinished = false; // Reset race finished state
      totalLaps = currentTrack.totalLaps;
      DriverData.resetAllDriversForNewRace(drivers, currentWeather);
    });
    raceTimer?.cancel();
  }

  // Navigate to results immediately without delay
  void _navigateToResults() {
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

  @override
  void dispose() {
    raceTimer?.cancel();
    _pulseController.dispose();
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
          // Big results button when race is finished
          if (raceFinished) _buildResultsPrompt(),
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
              raceFinished ? 'FINISHED' : (isRacing ? 'LIVE' : 'PAUSED'),
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

  Widget _buildSimpleRaceHeader() {
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
                  // NEW: Show pole position info
                  if (drivers.isNotEmpty && drivers.any((d) => d.position == 1)) ...[
                    SizedBox(height: 4),
                    Text(
                      'POLE: ${drivers.firstWhere((d) => d.position == 1).name.toUpperCase()}',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: raceFinished ? Colors.green[600] : (isRacing ? Colors.red[600] : Colors.grey[600]),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  raceFinished ? 'FINISHED' : (isRacing ? 'RACING' : 'STOPPED'),
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
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    if (!raceFinished) ...[
                      _buildControlButton(
                        label: 'START',
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
                    ] else ...[
                      // Only show new race button when finished (results button moved to bottom)
                      _buildControlButton(
                        label: 'NEW RACE',
                        onPressed: _resetRace,
                        isPrimary: true,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 16),
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
    List<String> tabs = ['STANDINGS', 'INCIDENTS'];
    List<IconData> icons = [Icons.format_list_numbered, Icons.warning];

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
        return _buildIncidentsPanel();
      default:
        return _buildStandingsTable();
    }
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
            width: 80,
            child: Text(
              'TIRE WEAR',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 100,
            child: Text(
              'INTERVAL',
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
    // Calculate interval gap (to car directly ahead)
    String intervalDisplay;
    if (driver.isDNF()) {
      intervalDisplay = 'DNF';
    } else if (index == 0) {
      intervalDisplay = 'LEADER';
    } else {
      // Gap to car directly ahead
      Driver carAhead = drivers[index - 1];
      if (carAhead.isDNF()) {
        intervalDisplay = 'LEADER';
      } else {
        double intervalGap = driver.totalTime - carAhead.totalTime;
        intervalDisplay = '+${intervalGap.toStringAsFixed(1)}s';
      }
    }

    bool isLeader = index == 0 && !driver.isDNF();

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
                    SizedBox(width: 8),
                    Text(
                      driver.currentCompound.icon,
                      style: TextStyle(fontSize: 12),
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
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${_getTireWearPercentage(driver).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _getTireWearColor(driver.calculateTyreDegradation()),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  height: 6, // Bigger tire wear bar
                  width: 60, // Wider tire wear bar
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (_getTireWearPercentage(driver) / 100.0).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getTireWearColor(driver.calculateTyreDegradation()),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 100,
            child: Text(
              intervalDisplay,
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

  double _getTireWearPercentage(Driver driver) {
    // Convert tire degradation to percentage (0-100%)
    double degradation = driver.calculateTyreDegradation();
    // Scale degradation to percentage - assuming max degradation around 3.0 = 100%
    double percentage = (degradation / 3.0) * 100.0;
    return percentage.clamp(0.0, 100.0);
  }

  Color _getTireWearColor(double degradation) {
    double percentage = (degradation / 3.0) * 100.0;
    if (percentage <= 25) return Colors.green;
    if (percentage <= 50) return Colors.yellow[700]!;
    if (percentage <= 75) return Colors.orange;
    if (percentage <= 90) return Colors.red[600]!;
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

  // Big prominent results button that appears when race finishes
  Widget _buildResultsPrompt() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          top: BorderSide(color: Colors.yellow, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: Colors.yellow, size: 24),
              SizedBox(width: 12),
              Text(
                'RACE COMPLETED!',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.emoji_events, color: Colors.yellow, size: 24),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _navigateToResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[600],
                foregroundColor: Colors.black,
                elevation: 8,
                shadowColor: Colors.yellow.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assessment,
                    size: 28,
                    color: Colors.black,
                  ),
                  SizedBox(width: 16),
                  Text(
                    'PROCEED VIEW RESULTS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(
                    Icons.arrow_forward,
                    size: 28,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
