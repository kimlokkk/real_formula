import 'package:flutter/material.dart';
import 'dart:async';
import '../models/driver.dart';
import '../models/enums.dart';
import '../models/track.dart';
import '../services/performance_calculator.dart';
import '../services/incident_simulator.dart';
import '../services/strategy_engine.dart';
import '../services/overtaking_engine.dart'; // Still needed for overtaking processing
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
  bool raceFinished = false;
  Timer? raceTimer;
  SimulationSpeed currentSpeed = SimulationSpeed.normal;
  WeatherCondition currentWeather = WeatherCondition.clear;
  Track currentTrack = TrackData.getDefaultTrack();

  late AnimationController _pulseController;

  int selectedTab = 0; // 0: Standings, 1: Incidents (removed overtaking)

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

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

      List<dynamic>? qualifyingResults = args['qualifyingResults'];
      if (qualifyingResults != null) {
        hasQualifyingResults = true;
        _processQualifyingResults(qualifyingResults);
      }
    }

    if (drivers.isEmpty) {
      _initializeRace();
    } else {
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
    raceFinished = false;
    raceTimer?.cancel();

    for (Driver driver in drivers) {
      driver.resetForNewRace();
      driver.currentCompound = driver.getWeatherAppropriateStartingCompound(currentWeather);
    }
  }

  void _resetRaceWithQualifyingGrid() {
    _debugPrintGrid("BEFORE reset with qualifying grid");

    totalLaps = currentTrack.totalLaps;
    currentLap = 0;
    isRacing = false;
    raceFinished = false;
    raceTimer?.cancel();

    for (Driver driver in drivers) {
      int savedStartingPosition = driver.startingPosition;
      int savedPosition = driver.position;
      TireCompound savedCompound = driver.currentCompound;
      bool savedFreeTireChoice = driver.hasFreeTireChoice;

      driver.resetForNewRace();

      driver.startingPosition = savedStartingPosition;
      driver.position = savedPosition;
      driver.currentCompound = savedCompound;
      driver.hasFreeTireChoice = savedFreeTireChoice;
      driver.positionChangeFromStart = 0;
    }

    drivers.sort((a, b) => a.position.compareTo(b.position));
    _debugPrintGrid("AFTER reset with qualifying grid");
  }

  void _processQualifyingResults(List<dynamic> qualifyingResults) {
    if (qualifyingResults.isNotEmpty && drivers.isNotEmpty) {
      _debugPrintGrid("BEFORE processing qualifying results");

      Driver polePosition = drivers.firstWhere((d) => d.position == 1, orElse: () => drivers.first);

      print("=== QUALIFYING INTEGRATION ===");
      print("Processed qualifying results for ${drivers.length} drivers");
      print("Pole position: ${polePosition.name} (P${polePosition.position})");
      print("Starting grid preserved from qualifying");

      drivers.sort((a, b) => a.position.compareTo(b.position));
      _debugPrintGrid("AFTER processing qualifying results");
    }
  }

  void _debugPrintGrid(String context) {
    print("=== GRID DEBUG: $context ===");
    for (int i = 0; i < drivers.length; i++) {
      Driver driver = drivers[i];
      print(
          "Index $i: ${driver.name} - Position: ${driver.position}, StartPos: ${driver.startingPosition}, Tire: ${driver.currentCompound.name}");
    }
    print("=== END GRID DEBUG ===");
  }

  // UPDATED _simulateLap() method with overtaking integration
  void _simulateLap() {
    if (currentLap >= totalLaps) {
      print("=== RACE FINISHED ===");
      print("Final lap: $currentLap, Total laps: $totalLaps");
      _stopRace();
      setState(() {
        raceFinished = true;
      });
      return;
    }

    setState(() {
      currentLap++;

      // STEP 1: Process pit stops first
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

      // STEP 2: Calculate lap times and process incidents
      for (Driver driver in drivers) {
        if (driver.isDNF()) continue;

        IncidentSimulator.processLapIncidents(driver, currentLap, totalLaps, currentWeather, currentTrack);
        if (driver.isDNF()) continue;

        double lapTime = PerformanceCalculator.calculateCurrentLapTime(driver, currentWeather, currentTrack);
        driver.totalTime += lapTime;
        driver.lapsCompleted++;
        driver.lapsOnCurrentTires++;
      }

      // STEP 3: Process overtaking opportunities BEFORE sorting by time
      List<String> overtakingIncidents =
          OvertakingEngine.processOvertakingOpportunities(drivers, currentLap, currentTrack, currentWeather);

      // Add overtaking incidents to the race log (but don't show in UI)
      for (String incident in overtakingIncidents) {
        print("OVERTAKING: $incident");
      }

      // STEP 4: Sort drivers by total time (but positions may have been updated by overtaking)
      drivers.sort((a, b) {
        if (a.isDNF() && b.isDNF()) return 0;
        if (a.isDNF()) return 1;
        if (b.isDNF()) return -1;
        return a.totalTime.compareTo(b.totalTime);
      });

      // STEP 5: Update positions based on final order (some may have changed due to overtaking)
      for (int i = 0; i < drivers.length; i++) {
        // Only update position if it's different (overtaking may have already updated it)
        if (drivers[i].position != i + 1) {
          drivers[i].updatePosition(i + 1);
        }
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
      raceFinished = false;
      totalLaps = currentTrack.totalLaps;
      DriverData.resetAllDriversForNewRace(drivers, currentWeather);
    });
    raceTimer?.cancel();
  }

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
                  if (drivers.isNotEmpty && drivers.any((d) => d.position == 1)) ...[
                    SizedBox(height: 4),
                    Text(
                      'LEADER: ${drivers.firstWhere((d) => d.position == 1).name.toUpperCase()}',
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

  // UPDATED _buildTabBar() method - removed overtaking tab
  Widget _buildTabBar() {
    List<String> tabs = ['STANDINGS', 'INCIDENTS']; // Removed overtaking tab
    List<IconData> icons = [Icons.format_list_numbered, Icons.warning]; // Removed overtaking icon

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

  // UPDATED _buildTabContent() method - removed overtaking case
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
      child: Column(
        children: [
          Row(
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
          // NEW: Battle legend
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info, color: Colors.grey[500], size: 12),
              SizedBox(width: 4),
              Text(
                'Colored left border indicates battles (gap < 2s): ',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 9,
                ),
              ),
              _buildBattleLegendItem(Colors.red[400]!, 'Intense'),
              SizedBox(width: 4),
              _buildBattleLegendItem(Colors.orange[400]!, 'Close'),
              SizedBox(width: 4),
              _buildBattleLegendItem(Colors.yellow[600]!, 'Nearby'),
              SizedBox(width: 4),
              _buildBattleLegendItem(Colors.green[400]!, 'Battle'),
            ],
          ),
        ],
      ),
    );
  }

  // UPDATED _buildDriverRow() method - removed overtaking indicators
  Widget _buildDriverRow(Driver driver, int index) {
    String intervalDisplay;
    double gapToCarAhead = 0.0;
    bool inBattle = false;

    if (driver.isDNF()) {
      intervalDisplay = 'DNF';
    } else if (index == 0) {
      intervalDisplay = 'LEADER';
    } else {
      Driver carAhead = drivers[index - 1];
      if (carAhead.isDNF()) {
        intervalDisplay = 'LEADER';
      } else {
        gapToCarAhead = driver.totalTime - carAhead.totalTime;
        intervalDisplay = '+${gapToCarAhead.toStringAsFixed(1)}s';

        // Check if in battle (less than 2 seconds gap to car ahead)
        // Only show battles after race has started and drivers have actual lap times
        inBattle = currentLap > 0 && gapToCarAhead < 2.0 && gapToCarAhead > 0.0;
      }
    }

// ALWAYS check if being chased (car behind within 2 seconds) - including for P1
    if (index < drivers.length - 1 && currentLap > 0) {
      Driver carBehind = drivers[index + 1];
      if (!carBehind.isDNF()) {
        double gapToCarBehind = carBehind.totalTime - driver.totalTime;
        if (gapToCarBehind < 2.0 && gapToCarBehind > 0.0) {
          inBattle = true; // Set battle for both chaser and being chased
        }
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
          // NEW: Battle indicator - colored left border for close gaps
          left: inBattle
              ? BorderSide(
                  color: _getBattleColor(gapToCarAhead),
                  width: 4,
                )
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            child: Row(
              children: [
                Stack(
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: driver.isDNF() ? Colors.grey[600] : _getTeamColor(driver.team),
                        borderRadius: BorderRadius.circular(2),
                        // NEW: Glow effect for drivers in battle
                        boxShadow: inBattle
                            ? [
                                BoxShadow(
                                  color: _getBattleColor(gapToCarAhead).withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
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
                  ],
                ),
                SizedBox(width: 4),
                Column(
                  children: [
                    if (driver.positionChangeFromStart != 0)
                      Icon(
                        driver.positionChangeFromStart > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: driver.positionChangeFromStart > 0 ? Colors.green : Colors.red,
                        size: 12,
                      ),
                  ],
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
                        color: driver.isDNF() ? Colors.grey[500] : (inBattle ? Colors.orange[200] : Colors.white),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // NEW: Battle indicator next to name for very close battles
                    if (inBattle && gapToCarAhead < 1.0) ...[
                      SizedBox(width: 4),
                      Icon(Icons.flash_on, color: Colors.orange, size: 12),
                    ],
                    if (driver.hasActiveMechanicalIssue) ...[
                      SizedBox(width: 4),
                      Icon(Icons.warning, color: Colors.orange, size: 14),
                    ],
                    if (driver.errorCount > 0) ...[
                      SizedBox(width: 4),
                      Icon(Icons.error, color: Colors.red, size: 14),
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
                  height: 6,
                  width: 60,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  intervalDisplay,
                  style: TextStyle(
                    color: driver.isDNF()
                        ? Colors.grey[500]
                        : (isLeader ? Colors.yellow : (inBattle ? Colors.orange[200] : Colors.white)),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
                // NEW: Battle intensity indicator
                if (inBattle) ...[
                  SizedBox(height: 2),
                  Text(
                    _getBattleDescription(gapToCarAhead),
                    style: TextStyle(
                      color: _getBattleColor(gapToCarAhead),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // COMPLETELY REWRITTEN _buildIncidentsPanel() - lap by lap format
  Widget _buildIncidentsPanel() {
    Map<int, List<String>> incidentsByLap = _getIncidentsByLap();

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
                Icon(Icons.info, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Text(
                  'PIT STOPS & INCIDENTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  'LAP $currentLap / $totalLaps',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Legend
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('PIT STOP', Icons.local_gas_station, Colors.blue),
                _buildLegendItem('MECHANICAL', Icons.build, Colors.orange),
                _buildLegendItem('ERROR', Icons.error, Colors.red),
                _buildLegendItem('QUALIFYING', Icons.flag, Colors.green),
              ],
            ),
          ),
          Expanded(
            child: incidentsByLap.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[600], size: 48),
                        SizedBox(height: 16),
                        Text(
                          'No incidents yet',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Pit stops and incidents will appear here',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true, // Show latest laps first
                    itemCount: incidentsByLap.keys.length,
                    itemBuilder: (context, index) {
                      List<int> sortedLaps = incidentsByLap.keys.toList()..sort();
                      int lap = sortedLaps.reversed.toList()[index];
                      List<String> lapIncidents = incidentsByLap[lap]!;

                      return _buildLapSection(lap, lapIncidents);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLapSection(int lap, List<String> incidents) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lap header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: lap == currentLap ? Colors.red[600]!.withOpacity(0.3) : Colors.grey[800],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: lap == currentLap ? Border.all(color: Colors.red[600]!, width: 2) : null,
            ),
            child: Row(
              children: [
                Icon(
                  lap == 0 ? Icons.flag : Icons.timer,
                  color: lap == currentLap ? Colors.red[300] : Colors.grey[400],
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  lap == 0 ? 'QUALIFYING' : 'LAP $lap',
                  style: TextStyle(
                    color: lap == currentLap ? Colors.red[300] : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (lap == currentLap) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CURRENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                Spacer(),
                Text(
                  '${incidents.length} incident${incidents.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Incidents for this lap
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: incidents.map((incident) => _buildIncidentRow(incident)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentRow(String incident) {
    IconData icon;
    Color iconColor;
    Color textColor = Colors.grey[300]!;

    // Extract driver name and incident text
    List<String> parts = incident.split(': ');
    String driverName = parts.isNotEmpty ? parts[0] : 'Unknown';
    String incidentText = parts.length > 1 ? parts.sublist(1).join(': ') : incident;

    // Determine incident type and styling
    if (incidentText.contains('Pit stop') || incidentText.contains('PIT STOP')) {
      icon = Icons.local_gas_station;
      iconColor = Colors.blue;
    } else if (incidentText.contains('Engine') ||
        incidentText.contains('Gearbox') ||
        incidentText.contains('Brake') ||
        incidentText.contains('Suspension') ||
        incidentText.contains('Hydraulic') ||
        incidentText.contains('mechanical') ||
        incidentText.contains('failure')) {
      icon = Icons.build;
      iconColor = Colors.orange;
    } else if (incidentText.contains('error') ||
        incidentText.contains('mistake') ||
        incidentText.contains('SPIN') ||
        incidentText.contains('lockup') ||
        incidentText.contains('CRASH')) {
      icon = Icons.error;
      iconColor = Colors.red;
      textColor = Colors.red[200]!;
    } else if (incidentText.contains('QUALIFYING') || incidentText.contains('Qualified')) {
      icon = Icons.flag;
      iconColor = Colors.green;
      textColor = Colors.green[200]!;
    } else {
      icon = Icons.info;
      iconColor = Colors.grey[400]!;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 14),
          SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  // Driver name - PROMINENT and colored
                  TextSpan(
                    text: driverName.toUpperCase(),
                    style: TextStyle(
                      color: _getDriverNameColor(driverName),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ': ',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                  // Incident text
                  TextSpan(
                    text: incidentText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      height: 1.3,
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

  // NEW: Get incidents organized by lap, filtered for relevant types only
  Map<int, List<String>> _getIncidentsByLap() {
    Map<int, List<String>> incidentsByLap = {};

    for (Driver driver in drivers) {
      for (String incident in driver.raceIncidents) {
        // Filter for relevant incident types only
        if (_isRelevantIncident(incident)) {
          int lap = _extractLapFromIncident(incident);
          if (lap >= 0) {
            // Include qualifying (lap 0)
            if (!incidentsByLap.containsKey(lap)) {
              incidentsByLap[lap] = [];
            }
            incidentsByLap[lap]!.add('${driver.name}: $incident');
          }
        }
      }
    }

    return incidentsByLap;
  }

  // NEW: Check if incident is relevant for display
  bool _isRelevantIncident(String incident) {
    // Include pit stops, mechanical issues, errors, and qualifying
    return incident.contains('Pit stop') ||
        incident.contains('PIT STOP') ||
        incident.contains('Engine') ||
        incident.contains('Gearbox') ||
        incident.contains('Brake') ||
        incident.contains('Suspension') ||
        incident.contains('Hydraulic') ||
        incident.contains('mechanical') ||
        incident.contains('failure') ||
        incident.contains('error') ||
        incident.contains('mistake') ||
        incident.contains('SPIN') ||
        incident.contains('lockup') ||
        incident.contains('CRASH') ||
        incident.contains('QUALIFYING') ||
        incident.contains('Qualified');
  }

  // NEW: Extract lap number from incident string
  int _extractLapFromIncident(String incident) {
    // Look for "Lap X:" pattern
    RegExp lapRegex = RegExp(r'Lap (\d+):');
    Match? match = lapRegex.firstMatch(incident);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }

    // Look for "QUALIFYING:" (treat as lap 0)
    if (incident.contains('QUALIFYING:')) {
      return 0; // Special case for qualifying
    }

    return -1; // Default if no lap found (will be filtered out)
  }

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
                    'VIEW RESULTS',
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

  // HELPER METHODS STILL NEEDED FOR STANDINGS TABLE
  double _getTireWearPercentage(Driver driver) {
    double degradation = driver.calculateTyreDegradation();
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

  Color _getDriverNameColor(String driverName) {
    // Match driver names to team colors for consistency
    switch (driverName.toLowerCase()) {
      case 'hamilton':
      case 'russell':
        return Colors.teal;
      case 'verstappen':
      case 'perez':
        return Colors.blue[400]!;
      case 'leclerc':
      case 'sainz':
        return Colors.red[400]!;
      case 'norris':
      case 'piastri':
        return Colors.orange[400]!;
      case 'alonso':
        return Colors.green[400]!;
      case 'rookie':
        return Colors.grey[400]!;
      default:
        return Colors.white;
    }
  }

// NEW: Get battle color based on gap intensity
  Color _getBattleColor(double gap) {
    if (gap < 0.5) return Colors.red[400]!; // Intense battle (red)
    if (gap < 1.0) return Colors.orange[400]!; // Close battle (orange)
    if (gap < 2.0) return Colors.yellow[600]!; // Moderate battle (yellow)
    return Colors.red[300]!; // Light battle (green)
  }

// NEW: Get battle description
  String _getBattleDescription(double gap) {
    if (gap < 0.5) return 'INTENSE';
    if (gap < 1.0) return 'CLOSE';
    if (gap < 2.0) return 'NEARBY';
    return 'PURSUED';
  }

// NEW: Battle legend item
  Widget _buildBattleLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}
