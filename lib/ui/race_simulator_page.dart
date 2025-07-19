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
  Timer? raceTimer;
  SimulationSpeed currentSpeed = SimulationSpeed.normal;
  WeatherCondition currentWeather = WeatherCondition.clear;
  Track currentTrack = TrackData.getDefaultTrack();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int selectedTab = 0; // 0: Standings, 1: Incidents

  @override
  void initState() {
    super.initState();
    _initializeRace();
    _initializePulseAnimation();
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

  void _initializeRace() {
    drivers = DriverData.createDefaultDrivers();
    DriverData.initializeStartingGrid(drivers);
    totalLaps = currentTrack.totalLaps;

    for (Driver driver in drivers) {
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
      _stopRace();
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

      // If race is not active, reset everything for new track
      if (!isRacing) {
        _resetRace();
      }
    });
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
          _buildRaceHeader(),
          _buildTrackInfo(),
          _buildTabBar(),
          Expanded(
            child: selectedTab == 0 ? _buildStandingsTable() : _buildIncidentsPanel(),
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

  Widget _buildRaceHeader() {
    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Race Info Row
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
          // Control Buttons
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
          // Speed, Weather and Track Controls
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
          // Track characteristics
          Text(
            currentTrack.characteristicsInfo.toUpperCase(),
            style: TextStyle(
              color: Colors.orange[300],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          // Track stats row
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
    return Container(
      color: Colors.grey[800],
      child: Row(
        children: [
          _buildTab('STANDINGS', 0),
          _buildTab('INCIDENTS', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
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
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
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
          // Position
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
          // Driver Info
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
                // Status badges row - only pit stops
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
          // Tire Info
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
          // Gap/Time
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

    // F1 podium colors
    if (index == 0) return Colors.yellow.withOpacity(0.1);
    if (index == 1) return Colors.grey[300]!.withOpacity(0.1);
    if (index == 2) return Colors.orange.withOpacity(0.1);

    // Points positions
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
