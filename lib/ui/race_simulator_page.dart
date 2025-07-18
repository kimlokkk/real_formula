import 'package:flutter/material.dart';
import 'dart:async';
import '../models/driver.dart';
import '../models/enums.dart';
import '../services/performance_calculator.dart';
import '../services/incident_simulator.dart';
import '../services/strategy_engine.dart';
import '../services/weather_service.dart';
import '../data/driver_data.dart';
import '../utils/constants.dart';

class F1RaceSimulator extends StatefulWidget {
  @override
  _F1RaceSimulatorState createState() => _F1RaceSimulatorState();
}

class _F1RaceSimulatorState extends State<F1RaceSimulator> {
  List<Driver> drivers = [];
  int currentLap = 0;
  int totalLaps = F1Constants.defaultTotalLaps;
  bool isRacing = false;
  Timer? raceTimer;
  SimulationSpeed currentSpeed = SimulationSpeed.normal;
  WeatherCondition currentWeather = WeatherCondition.clear;

  @override
  void initState() {
    super.initState();
    _initializeRace();
  }

  void _initializeRace() {
    drivers = DriverData.createDefaultDrivers();
    DriverData.initializeStartingGrid(drivers);

    // Initialize tire compounds for current weather
    for (Driver driver in drivers) {
      driver.currentCompound = driver.getWeatherAppropriateStartingCompound(currentWeather);
    }
  }

  /// Get all race incidents for display
  List<String> _getAllIncidents() {
    List<String> allIncidents = [];
    for (Driver driver in drivers) {
      for (String incident in driver.raceIncidents) {
        allIncidents.add("${driver.name}: $incident");
      }
    }
    return allIncidents.reversed.take(F1Constants.incidentLogLimit).toList();
  }

  void _simulateLap() {
    if (currentLap >= totalLaps) {
      _stopRace();
      return;
    }

    setState(() {
      currentLap++;

      // Check for pit stops before calculating lap times
      for (int i = 0; i < drivers.length; i++) {
        Driver driver = drivers[i];

        // Skip DNF drivers
        if (driver.isDNF()) continue;

        // Calculate gaps for strategic decisions
        double gapBehind = (i >= drivers.length - 1) ? 999.0 : drivers[i + 1].totalTime - driver.totalTime;
        double gapAhead = (i <= 0) ? 999.0 : driver.totalTime - drivers[i - 1].totalTime;

        if (StrategyEngine.shouldPitStop(driver, currentLap, totalLaps, gapBehind, gapAhead)) {
          StrategyEngine.executePitStop(driver, currentWeather, currentLap, totalLaps, gapAhead, gapBehind);
        }
      }

      // Process incidents and calculate lap times
      for (Driver driver in drivers) {
        // Skip DNF drivers
        if (driver.isDNF()) continue;

        // Process incidents with weather
        IncidentSimulator.processLapIncidents(driver, currentLap, totalLaps, currentWeather);

        // Skip lap time calculation if driver DNF'd this lap
        if (driver.isDNF()) continue;

        // Calculate lap time with weather
        double lapTime = PerformanceCalculator.calculateCurrentLapTime(driver, currentWeather);
        driver.totalTime += lapTime;
        driver.lapsCompleted++;
        driver.lapsOnCurrentTires++; // Age the tires
      }

      // Sort drivers by total time (DNF drivers go to back)
      drivers.sort((a, b) {
        if (a.isDNF() && b.isDNF()) return 0;
        if (a.isDNF()) return 1;
        if (b.isDNF()) return -1;
        return a.totalTime.compareTo(b.totalTime);
      });

      // Update positions and calculate changes from starting grid
      for (int i = 0; i < drivers.length; i++) {
        drivers[i].updatePosition(i + 1);
      }
    });
  }

  void _changeSpeed(SimulationSpeed newSpeed) {
    setState(() {
      currentSpeed = newSpeed;
    });

    // If racing, restart the timer with new speed
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
      DriverData.resetAllDriversForNewRace(drivers, currentWeather);
    });
    raceTimer?.cancel();
  }

  void _changeWeather(WeatherCondition newWeather) {
    setState(() {
      WeatherCondition oldWeather = currentWeather;
      currentWeather = newWeather;

      // Process weather change effects
      List<String> weatherIncidents = WeatherService.processWeatherChange(drivers, oldWeather, newWeather);

      // Add race-wide weather change log
      if (oldWeather != newWeather) {
        print("Weather changed: ${oldWeather.name} → ${newWeather.name}");
      }
    });
  }

  void _resetCompoundsForWeather() {
    setState(() {
      WeatherService.resetCompoundsForWeather(drivers, currentWeather);
    });
  }

  @override
  void dispose() {
    raceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('F1 Race Simulator - Enhanced with Errors & Failures'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Race Info Header
          _buildRaceHeader(),

          // Race Incidents Log
          _buildIncidentLog(),

          SizedBox(height: 8),

          // Drivers List
          _buildDriversList(),
        ],
      ),
    );
  }

  Widget _buildRaceHeader() {
    return Container(
      padding: EdgeInsets.all(F1Constants.headerPadding),
      color: Colors.grey[100],
      child: Column(
        children: [
          // ROW 1: Lap Counter + Weather + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Lap Counter
              Text(
                'Lap: $currentLap / $totalLaps',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              // Weather Controls (Compact)
              _buildWeatherControls(),

              // Status
              Text(
                isRacing ? 'RACING' : (currentLap >= totalLaps ? 'FINISHED' : 'STOPPED'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isRacing ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // ROW 2: Control Buttons
          _buildControlButtons(),

          SizedBox(height: 8),

          // ROW 3: Speed Controls + Compound Info
          _buildSpeedAndCompoundInfo(),
        ],
      ),
    );
  }

  Widget _buildWeatherControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: currentWeather.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: currentWeather.color.withOpacity(0.3)),
          ),
          child: Text(
            "${currentWeather.icon} ${currentWeather.name}",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: 4),
        ElevatedButton(
          onPressed: isRacing ? null : () => _changeWeather(WeatherCondition.clear),
          style: ElevatedButton.styleFrom(
            backgroundColor: currentWeather == WeatherCondition.clear ? Colors.yellow : Colors.grey[300],
            foregroundColor: currentWeather == WeatherCondition.clear ? Colors.black : Colors.black54,
            minimumSize: Size(32, 28),
            padding: EdgeInsets.all(4),
          ),
          child: Text("☀️", style: TextStyle(fontSize: 10)),
        ),
        SizedBox(width: 2),
        ElevatedButton(
          onPressed: isRacing ? null : () => _changeWeather(WeatherCondition.rain),
          style: ElevatedButton.styleFrom(
            backgroundColor: currentWeather == WeatherCondition.rain ? Colors.blue : Colors.grey[300],
            foregroundColor: currentWeather == WeatherCondition.rain ? Colors.white : Colors.black54,
            minimumSize: Size(32, 28),
            padding: EdgeInsets.all(4),
          ),
          child: Text("🌧️", style: TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: isRacing ? null : _startRace,
          child: Text(currentLap >= totalLaps ? 'New Race' : 'Start Race'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        ElevatedButton(
          onPressed: isRacing ? _stopRace : null,
          child: Text('Stop'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        ElevatedButton(
          onPressed: isRacing ? null : _resetRace,
          child: Text('Reset'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedAndCompoundInfo() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Speed Controls
          _buildSpeedControls(),

          SizedBox(width: 12),

          // Compound Distribution
          _buildCompoundDistribution(),

          SizedBox(width: 8),

          // Reset Tires Button
          ElevatedButton(
            onPressed: isRacing ? null : _resetCompoundsForWeather,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[300],
              foregroundColor: Colors.black87,
              minimumSize: Size(60, 24),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text("Reset Tires", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedControls() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Speed: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ...SimulationSpeed.values
              .map((speed) => Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: ElevatedButton(
                      onPressed: () => _changeSpeed(speed),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentSpeed == speed ? Colors.blue : Colors.grey[300],
                        foregroundColor: currentSpeed == speed ? Colors.white : Colors.black87,
                        minimumSize: Size(35, 24),
                        padding: EdgeInsets.all(4),
                      ),
                      child: Text(speed.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildCompoundDistribution() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Tires: ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          Text(
            WeatherService.getCompoundDistributionString(drivers),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentLog() {
    return Container(
      height: F1Constants.containerHeight,
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Race Incidents',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _getAllIncidents().length,
              itemBuilder: (context, index) {
                String incident = _getAllIncidents()[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    incident,
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriversList() {
    return Expanded(
      child: ListView.builder(
        itemCount: drivers.length,
        itemBuilder: (context, index) {
          Driver driver = drivers[index];
          return _buildDriverCard(driver, index);
        },
      ),
    );
  }

  Widget _buildDriverCard(Driver driver, int index) {
    double gapToLeader = index == 0 ? 0.0 : (driver.isDNF() ? 0.0 : driver.totalTime - drivers[0].totalTime);
    double intervalGap = index == 0 ? 0.0 : (driver.isDNF() ? 0.0 : driver.totalTime - drivers[index - 1].totalTime);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      elevation: driver.positionChangeFromStart != 0 ? F1Constants.cardElevation : F1Constants.cardElevationNormal,
      color: _getCardColor(driver),
      child: ListTile(
        leading: _buildPositionIndicator(driver),
        title: _buildDriverTitle(driver),
        subtitle: _buildDriverSubtitle(driver),
        trailing: _buildDriverTrailing(driver, index, gapToLeader, intervalGap),
      ),
    );
  }

  Color? _getCardColor(Driver driver) {
    if (driver.isDNF()) return Colors.grey[100];
    if (driver.positionChangeFromStart > 0) return Colors.green[50];
    if (driver.positionChangeFromStart < 0) return Colors.red[50];
    return null;
  }

  Widget _buildPositionIndicator(Driver driver) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: driver.isDNF() ? Colors.grey : driver.teamColor,
          child: Text(
            driver.isDNF() ? 'DNF' : '${driver.position}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: driver.isDNF() ? 8 : 12,
            ),
          ),
        ),
        SizedBox(width: 8),
        Container(
          width: 30,
          child: currentLap > 0 && driver.positionChangeFromStart != 0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      driver.positionChangeFromStart > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      color: driver.positionChangeFromStart > 0 ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    Text(
                      '${driver.positionChangeFromStart.abs()}',
                      style: TextStyle(
                        color: driver.positionChangeFromStart > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : SizedBox(),
        ),
      ],
    );
  }

  Widget _buildDriverTitle(Driver driver) {
    return Row(
      children: [
        Text(
          driver.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: driver.isDNF() ? Colors.grey : Colors.black,
          ),
        ),
        SizedBox(width: 8),
        Text(
          '(${driver.team})',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        // Status indicators
        if (driver.hasActiveMechanicalIssue) ...[
          SizedBox(width: 8),
          Icon(Icons.warning, color: Colors.orange, size: 16),
        ],
        if (driver.errorCount > 0) ...[
          SizedBox(width: 4),
          Icon(Icons.error_outline, color: Colors.red, size: 16),
        ],
      ],
    );
  }

  Widget _buildDriverSubtitle(Driver driver) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Car: ${driver.carPerformance}/100 | REL: ${driver.reliability}/100 | ${driver.skillsInfo}'),
        Text(driver.degradationInfo),
        // Status information
        if (driver.statusInfo.isNotEmpty)
          Text(
            driver.statusInfo,
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        _buildDriverBadges(driver),
      ],
    );
  }

  Widget _buildDriverBadges(Driver driver) {
    return Row(
      children: [
        Text('Started P${driver.startingPosition}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        SizedBox(width: 10),
        if (driver.pitStops > 0) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${driver.pitStops} PIT${driver.pitStops > 1 ? 'S' : ''}',
              style: TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
          SizedBox(width: 4),
        ],
        if (driver.errorCount > 0) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${driver.errorCount} ERR',
              style: TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
          SizedBox(width: 4),
        ],
        if (driver.mechanicalIssuesCount > 0) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${driver.mechanicalIssuesCount} MECH',
              style: TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDriverTrailing(Driver driver, int index, double gapToLeader, double intervalGap) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Gap to Leader
        Text(
          driver.isDNF() ? 'DNF' : (index == 0 ? 'Leader' : '+${gapToLeader.toStringAsFixed(1)}s'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: driver.isDNF() ? Colors.grey : (index == 0 ? Colors.amber : Colors.black87),
            fontSize: 13,
          ),
        ),
        // Interval Gap
        if (index > 0 && !driver.isDNF())
          Text(
            'Δ${intervalGap.toStringAsFixed(1)}s',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        SizedBox(height: 2),
        if (driver.positionChangeFromStart != 0 && currentLap > 0)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: driver.positionChangeFromStart > 0 ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              driver.positionChangeFromStart > 0
                  ? '+${driver.positionChangeFromStart}'
                  : '${driver.positionChangeFromStart}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
