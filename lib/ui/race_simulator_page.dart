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
  late Animation<double> _pulseAnimation;

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
    _pulseAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
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
      print("=== SIMULATING LAP $currentLap ===");

      for (int i = 0; i < drivers.length; i++) {
        Driver driver = drivers[i];
        if (driver.isDNF()) continue;

        double gapBehind = (i >= drivers.length - 1) ? 999.0 : drivers[i + 1].totalTime - driver.totalTime;
        double gapAhead = (i <= 0) ? 999.0 : driver.totalTime - drivers[i - 1].totalTime;

        if (StrategyEngine.shouldPitStop(driver, currentLap, totalLaps, gapBehind, gapAhead, currentTrack)) {
          print("${driver.name} is pitting on lap $currentLap");
          StrategyEngine.executePitStop(
              driver, currentWeather, currentLap, totalLaps, gapAhead, gapBehind, currentTrack);
          print("${driver.name} now has ${driver.pitStops} pit stops");
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

      // Debug output every 10 laps
      if (currentLap % 10 == 0) {
        print("=== LAP $currentLap SUMMARY ===");
        for (int i = 0; i < min(3, drivers.length); i++) {
          Driver d = drivers[i];
          print(
              "P${d.position}: ${d.name} - Pits: ${d.pitStops}, Errors: ${d.errorCount}, Time: ${d.totalTime.toStringAsFixed(1)}");
        }
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

  void _changeWeather(WeatherCondition newWeather) {
    setState(() {
      WeatherCondition oldWeather = currentWeather;
      currentWeather = newWeather;

      if (oldWeather != newWeather) {
        print("Weather changed: ${oldWeather.name} → ${newWeather.name}");
      }
    });
  }

  void _changeTrack(Track newTrack) {
    setState(() {
      currentTrack = newTrack;
      totalLaps = newTrack.totalLaps;

      if (!isRacing) {
        _resetRace();
      }
    });
  }

  void _navigateToResults() {
    // Add debugging to see what data we're passing
    print("=== NAVIGATING TO RESULTS ===");
    print("Current lap: $currentLap");
    print("Total laps: $totalLaps");
    print("Number of drivers: ${drivers.length}");

    // Debug driver data before passing
    for (int i = 0; i < drivers.length; i++) {
      Driver d = drivers[i];
      print(
          "Driver ${d.name}: Position=${d.position}, Pits=${d.pitStops}, Errors=${d.errorCount}, Mechanical=${d.mechanicalIssuesCount}, TotalTime=${d.totalTime}");
    }

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/results',
          arguments: {
            'drivers': drivers, // Make sure we're passing the CURRENT drivers, not reset ones
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
          _buildRaceHeader(),
          _buildTrackInfo(),
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

  Widget _buildRaceHeader() {
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: currentWeather.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentWeather.icon,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(width: 4),
                    Text(
                      currentWeather.name.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                label: currentLap >= totalLaps ? 'NEW RACE' : 'START',
                onPressed: isRacing ? null : _startRace,
                isPrimary: true,
              ),
              _buildControlButton(
                label: 'STOP',
                onPressed: isRacing ? _stopRace : null,
                isPrimary: false,
              ),
              _buildControlButton(
                label: 'RESET',
                onPressed: isRacing ? null : _resetRace,
                isPrimary: false,
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSpeedControl()),
              SizedBox(width: 8),
              Expanded(child: _buildWeatherControl()),
              SizedBox(width: 8),
              Expanded(child: _buildTrackControl()),
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
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
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

  Widget _buildWeatherControl() {
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
            'WEATHER',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: WeatherCondition.values.map((weather) {
              bool isSelected = currentWeather == weather;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: weather != WeatherCondition.values.last ? 2 : 0),
                  child: GestureDetector(
                    onTap: isRacing ? null : () => _changeWeather(weather),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? weather.color : Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          weather.icon,
                          style: TextStyle(fontSize: 12),
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

  Widget _buildTrackControl() {
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
            'TRACK',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Container(
            width: double.infinity,
            child: DropdownButton<Track>(
              value: currentTrack,
              onChanged: isRacing
                  ? null
                  : (Track? newTrack) {
                      if (newTrack != null) _changeTrack(newTrack);
                    },
              dropdownColor: Colors.grey[700],
              style: TextStyle(color: Colors.white, fontSize: 10),
              underline: Container(),
              isExpanded: true,
              items: TrackData.tracks.map<DropdownMenuItem<Track>>((Track track) {
                return DropdownMenuItem<Track>(
                  value: track,
                  child: Text(
                    track.name,
                    style: TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Container(
      color: Colors.grey[850],
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentTrack.name.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${currentTrack.country.toUpperCase()} • ${currentTrack.typeDescription.toUpperCase()}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${currentTrack.totalLaps} LAPS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '~${currentTrack.baseLapTime.toStringAsFixed(1)}s LAP TIME',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            currentTrack.characteristicsInfo.toUpperCase(),
            style: TextStyle(
              color: Colors.orange[300],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildTrackStat("OVERTAKING", _formatDifficulty(currentTrack.overtakingDifficulty)),
              SizedBox(width: 16),
              _buildTrackStat("TIRE WEAR", _formatMultiplier(currentTrack.tireDegradationMultiplier)),
              SizedBox(width: 16),
              _buildTrackStat("ERROR RATE", _formatMultiplier(currentTrack.errorProbabilityMultiplier)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDifficulty(double difficulty) {
    if (difficulty < 0.3) return "VERY HARD";
    if (difficulty < 0.5) return "HARD";
    if (difficulty < 0.7) return "MODERATE";
    return "EASY";
  }

  String _formatMultiplier(double multiplier) {
    if (multiplier < 0.8) return "LOW";
    if (multiplier < 1.1) return "NORMAL";
    if (multiplier < 1.3) return "HIGH";
    return "VERY HIGH";
  }

  Widget _buildTabBar() {
    List<String> tabs = ['STANDINGS', 'TRACK VIEW', 'INCIDENTS'];
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
        return _buildTrackVisualization();
      case 2:
        return _buildIncidentsPanel();
      default:
        return _buildStandingsTable();
    }
  }

  Widget _buildTrackVisualization() {
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
                Icon(Icons.track_changes, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text(
                  'LIVE TRACK VIEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  currentTrack.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: TrackPainter(
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
    double intervalGap = index == 0 ? 0.0 : (driver.isDNF() ? 0.0 : driver.totalTime - drivers[index - 1].totalTime);
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
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      child: Text(
                        driver.isDNF() ? 'DNF' : '${driver.position}',
                        key: ValueKey(driver.isDNF() ? 'DNF' : driver.position),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: driver.isDNF() ? 8 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                if (driver.positionChangeFromStart != 0)
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: Icon(
                      driver.positionChangeFromStart > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      key: ValueKey(driver.positionChangeFromStart > 0 ? 'up' : 'down'),
                      color: driver.positionChangeFromStart > 0 ? Colors.green : Colors.red,
                      size: 12,
                    ),
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
                Text(
                  driver.team.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                if (driver.pitStops > 0)
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(driver.pitStops),
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
                  ),
              ],
            ),
          ),
          Container(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 400),
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          bool isCritical =
                              driver.calculateTyreDegradation() * currentTrack.tireDegradationMultiplier > 2.0;
                          return Container(
                            key: ValueKey(driver.currentCompound),
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isCritical ? Colors.red.withOpacity(_pulseAnimation.value) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              driver.currentCompound.icon,
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: Duration(milliseconds: 200),
                            child: Text(
                              '${driver.lapsOnCurrentTires}',
                              key: ValueKey(driver.lapsOnCurrentTires),
                              style: TextStyle(
                                color: _getTireWearColor(
                                    driver.calculateTyreDegradation() * currentTrack.tireDegradationMultiplier),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 2),
                          Container(
                            height: 2,
                            width: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey[700],
                              borderRadius: BorderRadius.circular(1),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor:
                                  ((driver.calculateTyreDegradation() * currentTrack.tireDegradationMultiplier) / 3.0)
                                      .clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getTireWearColor(
                                      driver.calculateTyreDegradation() * currentTrack.tireDegradationMultiplier),
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
              ],
            ),
          ),
          Container(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: Text(
                    driver.isDNF() ? 'DNF' : (isLeader ? 'LEADER' : '+${gapToLeader.toStringAsFixed(1)}'),
                    key: ValueKey(driver.isDNF() ? 'DNF' : (isLeader ? 'LEADER' : gapToLeader.toStringAsFixed(1))),
                    style: TextStyle(
                      color: driver.isDNF() ? Colors.grey[500] : (isLeader ? Colors.yellow : Colors.white),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                if (index > 0 && !driver.isDNF())
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: Text(
                      'Δ${intervalGap.toStringAsFixed(1)}',
                      key: ValueKey(intervalGap.toStringAsFixed(1)),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
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

class TrackPainter extends CustomPainter {
  final List<Driver> drivers;
  final int currentLap;
  final int totalLaps;
  final Animation<double> trackAnimation;

  TrackPainter({
    required this.drivers,
    required this.currentLap,
    required this.totalLaps,
    required this.trackAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final trackRadius = min(size.width, size.height) * 0.35;
    final pitLaneRadius = trackRadius + 30;

    // Draw track
    _drawTrack(canvas, center, trackRadius);

    // Draw pit lane
    _drawPitLane(canvas, center, pitLaneRadius, trackRadius);

    // Draw start/finish line
    _drawStartFinishLine(canvas, center, trackRadius);

    // Draw cars
    _drawCars(canvas, center, trackRadius);

    // Draw track info
    _drawTrackInfo(canvas, size);
  }

  void _drawTrack(Canvas canvas, Offset center, double radius) {
    final trackPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40;

    final trackOutlinePaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 44;

    // Outer outline
    canvas.drawCircle(center, radius, trackOutlinePaint);
    // Track surface
    canvas.drawCircle(center, radius, trackPaint);

    // Track markings (dashed line in middle)
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const dashLength = 10.0;
    const dashSpace = 5.0;
    final circumference = 2 * pi * radius;
    final totalDashes = circumference / (dashLength + dashSpace);

    for (int i = 0; i < totalDashes; i++) {
      final angle = (i / totalDashes) * 2 * pi;
      final startAngle = angle;
      final endAngle = angle + (dashLength / circumference) * 2 * pi;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle - pi / 2,
        endAngle - startAngle,
        false,
        dashPaint,
      );
    }
  }

  void _drawPitLane(Canvas canvas, Offset center, double pitRadius, double trackRadius) {
    final pitPaint = Paint()
      ..color = Colors.blue[800]!.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    // Draw pit lane (partial arc on the right side)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: pitRadius),
      -pi / 3, // Start angle
      2 * pi / 3, // Sweep angle
      false,
      pitPaint,
    );

    // Pit lane entrance/exit lines
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Entrance line
    final entranceAngle = -pi / 3;
    final entranceStart = Offset(
      center.dx + (trackRadius - 20) * cos(entranceAngle),
      center.dy + (trackRadius - 20) * sin(entranceAngle),
    );
    final entranceEnd = Offset(
      center.dx + (pitRadius + 10) * cos(entranceAngle),
      center.dy + (pitRadius + 10) * sin(entranceAngle),
    );
    canvas.drawLine(entranceStart, entranceEnd, linePaint);

    // Exit line
    final exitAngle = pi / 3;
    final exitStart = Offset(
      center.dx + (trackRadius - 20) * cos(exitAngle),
      center.dy + (trackRadius - 20) * sin(exitAngle),
    );
    final exitEnd = Offset(
      center.dx + (pitRadius + 10) * cos(exitAngle),
      center.dy + (pitRadius + 10) * sin(exitAngle),
    );
    canvas.drawLine(exitStart, exitEnd, linePaint);
  }

  void _drawStartFinishLine(Canvas canvas, Offset center, double radius) {
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final checkeredPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Start/finish line at top of track
    final lineStart = Offset(center.dx, center.dy - radius - 20);
    final lineEnd = Offset(center.dx, center.dy - radius + 20);

    canvas.drawLine(lineStart, lineEnd, linePaint);

    // Checkered pattern
    for (int i = 0; i < 8; i++) {
      if (i % 2 == 0) {
        final rect = Rect.fromLTWH(
          center.dx - 3 + (i % 2) * 3,
          center.dy - radius - 20 + i * 5,
          3,
          5,
        );
        canvas.drawRect(rect, checkeredPaint);
      }
    }

    // "START/FINISH" text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'START/FINISH',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - radius - 45),
    );
  }

  void _drawCars(Canvas canvas, Offset center, double radius) {
    if (drivers.isEmpty || totalLaps == 0) return;

    // Sort drivers by position for better visual
    List<Driver> sortedDrivers = List.from(drivers);
    sortedDrivers.sort((a, b) => a.position.compareTo(b.position));

    for (int i = 0; i < sortedDrivers.length; i++) {
      final driver = sortedDrivers[i];
      if (driver.isDNF()) continue;

      // Calculate car position on track
      double lapProgress = 0.0;
      if (currentLap > 0 && driver.lapsCompleted > 0) {
        // Estimate lap progress based on time gaps
        if (i == 0) {
          // Leader - estimate based on current lap progress
          lapProgress = (currentLap - 1) + 0.5; // Rough estimation
        } else {
          // Other drivers - position based on gap to leader
          double gapToLeader = driver.totalTime - drivers[0].totalTime;
          double estimatedLapTime = 90.0; // Rough average
          double lapsBehind = gapToLeader / estimatedLapTime;
          lapProgress = max(0, (currentLap - 1) + 0.5 - lapsBehind);
        }
      }

      // Convert to angle (0 = top of track, clockwise)
      double trackPosition = (lapProgress / totalLaps) * 2 * pi;
      double angle = trackPosition - pi / 2; // Adjust so 0 is at top

      // Add small offset so cars don't overlap
      double carRadius = radius + (i % 3 - 1) * 8; // Spread cars across track width

      // Calculate car position
      final carPos = Offset(
        center.dx + carRadius * cos(angle),
        center.dy + carRadius * sin(angle),
      );

      // Draw car
      _drawCar(canvas, carPos, driver, angle);
    }
  }

  void _drawCar(Canvas canvas, Offset position, Driver driver, double angle) {
    final carPaint = Paint()
      ..color = _getTeamColor(driver.team)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Car body (rounded rectangle)
    final carRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: position, width: 16, height: 8),
      Radius.circular(4),
    );

    canvas.drawRRect(carRect, carPaint);
    canvas.drawRRect(carRect, outlinePaint);

    // Position number
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${driver.position}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );

    // Tire compound indicator (small colored dot)
    final tireColor = _getTireCompoundColor(driver.currentCompound);
    final tirePaint = Paint()
      ..color = tireColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(position.dx + 10, position.dy - 6),
      3,
      tirePaint,
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

  void _drawTrackInfo(Canvas canvas, Size size) {
    // Draw legend
    final legendY = size.height - 100;

    // Tire compound legend
    final compounds = [
      {'name': 'SOFT', 'color': Colors.red, 'icon': '🔴'},
      {'name': 'MEDIUM', 'color': Colors.yellow, 'icon': '🟡'},
      {'name': 'HARD', 'color': Colors.white, 'icon': '⚪'},
      {'name': 'INTER', 'color': Colors.green, 'icon': '🟢'},
      {'name': 'WET', 'color': Colors.blue, 'icon': '🔵'},
    ];

    for (int i = 0; i < compounds.length; i++) {
      final compound = compounds[i];
      final x = 20.0 + i * 60;

      // Draw tire indicator
      final tirePaint = Paint()
        ..color = compound['color'] as Color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, legendY), 6, tirePaint);

      // Draw label
      final textPainter = TextPainter(
        text: TextSpan(
          text: compound['name'] as String,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, legendY + 10));
    }

    // Current lap info
    final lapTextPainter = TextPainter(
      text: TextSpan(
        text: 'LAP $currentLap / $totalLaps',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    lapTextPainter.layout();
    lapTextPainter.paint(
      canvas,
      Offset(size.width - lapTextPainter.width - 20, 20),
    );
  }

  @override
  bool shouldRepaint(TrackPainter oldDelegate) {
    return oldDelegate.currentLap != currentLap ||
        oldDelegate.drivers != drivers ||
        oldDelegate.trackAnimation != trackAnimation;
  }
}
