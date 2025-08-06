// lib/ui/race_simulator_page.dart - Updated ONLY visual changes, keeping original functions intact

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
  const F1RaceSimulator({Key? key}) : super(key: key);

  @override
  _F1RaceSimulatorState createState() => _F1RaceSimulatorState();
}

class _F1RaceSimulatorState extends State<F1RaceSimulator>
    with TickerProviderStateMixin {
  // ALL EXISTING STATE VARIABLES PRESERVED
  List<Driver> drivers = [];
  int currentLap = 0;
  int totalLaps = F1Constants.defaultTotalLaps;
  bool isRacing = false;
  bool raceFinished = false;
  Timer? raceTimer;
  SimulationSpeed currentSpeed = SimulationSpeed.normal;
  WeatherCondition currentWeather = WeatherCondition.clear;
  Track currentTrack = TrackData.getDefaultTrack();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int selectedTab = 0; // 0: Standings, 1: Incidents
  bool isControlsExpanded = true; // NEW: Control expansion state

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    bool hasQualifyingResults = false;

    if (args != null) {
      currentTrack = args['track'] ?? TrackData.getDefaultTrack();
      currentWeather = args['weather'] ?? WeatherCondition.clear;
      currentSpeed = args['speed'] ?? SimulationSpeed.normal;
      List<Driver>? configDrivers = args['drivers'];
      if (configDrivers != null) {
        drivers = List.from(configDrivers);
      }

      hasQualifyingResults = args['hasQualifyingResults'] ?? false;
      if (!hasQualifyingResults) {
        hasQualifyingResults = args['qualifyingResults'] != null;
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

  @override
  void dispose() {
    _fadeController.dispose();
    raceTimer?.cancel();
    super.dispose();
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

  // ALL EXISTING BUSINESS LOGIC METHODS PRESERVED EXACTLY
  void _resetRaceWithQualifyingGrid() {
    totalLaps = currentTrack.totalLaps;
    currentLap = 0;
    isRacing = false;
    raceFinished = false;
    raceTimer?.cancel();

    print(
        '🔧 DEBUG: Preserving qualifying grid with weather ${currentWeather.name}');

    for (Driver driver in drivers) {
      print(
          '🔧 DEBUG: ${driver.name} had ${driver.currentCompound.name} tires from qualifying');

      int savedStartingPosition = driver.startingPosition;
      int savedGridPosition = driver.position;
      TireCompound savedCompound = driver.currentCompound;
      bool savedFreeTireChoice = driver.hasFreeTireChoice;

      driver.resetForNewRace();

      driver.startingPosition = savedStartingPosition;
      driver.position = savedGridPosition;
      driver.currentCompound = savedCompound;
      driver.hasFreeTireChoice = savedFreeTireChoice;
      driver.positionChangeFromStart = 0;

      print(
          '🔧 DEBUG: ${driver.name} restored to ${driver.currentCompound.name} tires');
    }

    drivers.sort((a, b) => a.position.compareTo(b.position));

    _planRaceStrategies();
  }

  // 🆕 NEW: Plan race strategies for all drivers
  void _planRaceStrategies() {
    print('📋 Planning race strategies for all drivers...');

    for (Driver driver in drivers) {
      driver.raceStrategy = StrategyEngine.planOptimalStrategy(
          driver,
          currentTrack,
          driver.startingPosition,
          currentWeather, // YOUR EXISTING WEATHER VARIABLE
          null // PASS NULL FOR NOW (no rain intensity)
          );

      // Optional: Log the planned strategy
      print(
          '   ${driver.name} (P${driver.startingPosition}): ${driver.raceStrategy!.reasoning}');
    }

    print('✅ All race strategies planned!');
  }

  void _simulateLap() {
    if (currentLap >= totalLaps) {
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

        double gapBehind =
            (i == 0) ? 999.0 : driver.totalTime - drivers[i - 1].totalTime;

        if (StrategyEngine.shouldPitStop(driver, currentLap, totalLaps,
            gapBehind, gapBehind, currentTrack)) {
          // Store previous incident count to detect pit stop incidents
          int previousIncidentCount = driver.raceIncidents.length;

          StrategyEngine.executePitStop(driver, currentWeather, currentLap,
              totalLaps, gapBehind, gapBehind, currentTrack);

          // Add lap information to any new pit stop incidents
          if (driver.raceIncidents.length > previousIncidentCount) {
            for (int j = previousIncidentCount;
                j < driver.raceIncidents.length;
                j++) {
              String incident = driver.raceIncidents[j];
              // Only add lap prefix if it doesn't already exist
              if (!incident.toLowerCase().contains('lap ') &&
                  !incident.contains('LAP $currentLap')) {
                driver.raceIncidents[j] = 'LAP $currentLap: $incident';
              }
            }
          }
        }
      }

      // STEP 2: Calculate lap times and process incidents
      for (Driver driver in drivers) {
        if (driver.isDNF()) continue;

        // Store previous incident count to detect new incidents
        int previousIncidentCount = driver.raceIncidents.length;

        IncidentSimulator.processLapIncidents(
            driver, currentLap, totalLaps, currentWeather, currentTrack);
        if (driver.isDNF()) continue;

        // Add lap information to any new incidents
        if (driver.raceIncidents.length > previousIncidentCount) {
          for (int i = previousIncidentCount;
              i < driver.raceIncidents.length;
              i++) {
            String incident = driver.raceIncidents[i];
            // Only add lap prefix if it doesn't already exist
            if (!incident.toLowerCase().contains('lap ') &&
                !incident.contains('LAP $currentLap')) {
              driver.raceIncidents[i] = 'LAP $currentLap: $incident';
            }
          }
        }

        double lapTime = PerformanceCalculator.calculateCurrentLapTime(
            driver, currentWeather, currentTrack);
        driver.totalTime += lapTime;
        driver.lapsCompleted++;
        driver.lapsOnCurrentTires++;
      }

      // STEP 4: Sort drivers by total time
      drivers.sort((a, b) {
        if (a.isDNF() && b.isDNF()) return 0;
        if (a.isDNF()) return 1;
        if (b.isDNF()) return -1;
        return a.totalTime.compareTo(b.totalTime);
      });

      // STEP 5: Update positions
      for (int i = 0; i < drivers.length; i++) {
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
      raceTimer = Timer.periodic(
          Duration(milliseconds: currentSpeed.intervalMs), (timer) {
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

    raceTimer = Timer.periodic(Duration(milliseconds: currentSpeed.intervalMs),
        (timer) {
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

  void _initializeRace() {
    drivers = DriverData.createDefaultDrivers();
    DriverData.initializeStartingGrid(drivers);
    totalLaps = currentTrack.totalLaps;

    for (Driver driver in drivers) {
      driver.currentCompound =
          driver.getWeatherAppropriateStartingCompound(currentWeather);
    }

    _planRaceStrategies();
  }

  void _resetRaceWithCurrentConfig() {
    DriverData.initializeStartingGrid(drivers);
    totalLaps = currentTrack.totalLaps;
    currentLap = 0;
    isRacing = false;
    raceFinished = false;
    raceTimer?.cancel();

    print('🔧 DEBUG: Race weather is ${currentWeather.name}');

    for (Driver driver in drivers) {
      print(
          '🔧 DEBUG: ${driver.name} had ${driver.currentCompound.name} tires before reset');
      driver.resetForNewRace();
      driver.currentCompound =
          driver.getWeatherAppropriateStartingCompound(currentWeather);
      print(
          '🔧 DEBUG: ${driver.name} now has ${driver.currentCompound.name} tires');
    }

    _planRaceStrategies();
  }

  void _navigateToResults() {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // CRITICAL: Create a deep copy of drivers to preserve data
    List<Driver> resultDrivers = [];

    for (Driver originalDriver in drivers) {
      // Create a new driver with preserved race data
      Driver resultDriver = Driver(
        name: originalDriver.name,
        abbreviation: originalDriver.abbreviation,
        team: originalDriver.team,
        speed: originalDriver.speed,
        consistency: originalDriver.consistency,
        tyreManagementSkill: originalDriver.tyreManagementSkill,
        racecraft: originalDriver.racecraft,
        experience: originalDriver.experience,
        lapsCompleted: originalDriver.lapsCompleted,
        pitStops: originalDriver.pitStops,
        totalTime: originalDriver.totalTime, // PRESERVE TOTAL TIME
        position: originalDriver.position,
        startingPosition: originalDriver.startingPosition,
        errorCount: originalDriver.errorCount,
        currentCompound: originalDriver.currentCompound,
      );

      // Copy other important race data
      resultDriver.positionChangeFromStart =
          originalDriver.positionChangeFromStart;
      resultDriver.mechanicalIssuesCount = originalDriver.mechanicalIssuesCount;
      resultDriver.hasActiveMechanicalIssue =
          originalDriver.hasActiveMechanicalIssue;
      resultDriver.currentIssueDescription =
          originalDriver.currentIssueDescription;
      resultDriver.raceIncidents = List.from(originalDriver.raceIncidents);

      resultDrivers.add(resultDriver);
    }

    // Final sort by position to ensure correct order
    resultDrivers.sort((a, b) {
      if (a.isDNF() && b.isDNF()) return 0;
      if (a.isDNF()) return 1;
      if (b.isDNF()) return -1;
      return a.position.compareTo(b.position);
    });

    // Debug: Print driver times before navigation
    print('🏁 NAVIGATING TO RESULTS:');
    for (Driver d in resultDrivers) {
      print('   P${d.position}: ${d.name} - Time: ${d.totalTime}s');
    }

    Navigator.pushNamed(
      context,
      '/results',
      arguments: {
        'drivers': resultDrivers, // Use the preserved copy
        'track': currentTrack,
        'weather': currentWeather,
        'totalLaps': totalLaps,
        'careerMode': args?['careerMode'] ?? false,
        'careerDriver': args?['careerDriver'],
        'raceWeekend': args?['raceWeekend'],
        'isCalendarRace': args?['isCalendarRace'] ?? false,
        'hasCareerDriver': args?['hasCareerDriver'] ?? false,
        'careerDriverName': args?['careerDriverName'],
      },
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          title: Text(
            'Exit Race?',
            style: TextStyle(color: Colors.white, fontFamily: 'Formula1'),
          ),
          content: Text(
            'Are you sure you want to exit the race? Your progress will be lost.',
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('Exit', style: TextStyle(color: Colors.red[400])),
            ),
          ],
        );
      },
    );
  }

  // CAREER HOME & QUALIFYING MATCHING UI - COMPLETELY REDESIGNED
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
                _buildRaceProgress(), // Bigger race progress
                Expanded(child: _buildContent()),
                _buildActionButton(), // Always show action button
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Match career home page background exactly
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

  // UPDATED: Remove reset button from header
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
          // Back button - match career home style exactly
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _showExitDialog,
            ),
          ),

          SizedBox(width: 16),

          // Racing stripe - match career home style exactly
          Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[400]!, Colors.red[600]!],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          SizedBox(width: 16),

          // Title section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTrack.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${currentTrack.name} • ${totalLaps} LAPS',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Formula1',
                  ),
                ),
              ],
            ),
          ),

          // REMOVED: Reset button
        ],
      ),
    );
  }

  // UPDATED: Bigger race progress
  Widget _buildRaceProgress() {
    double progress = totalLaps > 0 ? currentLap / totalLaps : 0.0;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 20, vertical: 16), // Increased padding
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LAP $currentLap OF $totalLaps',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16, // Bigger text
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 16, // Bigger text
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                ),
              ),
            ],
          ),
          SizedBox(height: 12), // More space
          Container(
            height: 8, // Bigger progress bar
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                raceFinished ? Colors.green[400]! : Colors.red[400]!,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildControlSection(),
          SizedBox(
              height:
                  isControlsExpanded ? 20 : 12), // Less space when collapsed
          _buildTabSelector(),
          SizedBox(height: 16),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildControlSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: isControlsExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            isControlsExpanded = expanded;
          });
        },
        leading: Icon(
          Icons.settings,
          color: Colors.white,
          size: 20,
        ),
        title: Text(
          'SPEED SETTINGS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Formula1',
            letterSpacing: 1,
          ),
        ),
        trailing: Icon(
          isControlsExpanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.white,
        ),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        childrenPadding: EdgeInsets.all(16),
        children: [
          // Speed controls only (start/pause moved to floating button)
          Row(
            children: [
              Text(
                'SPEED:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                ),
              ),
              SizedBox(width: 12),
              ...SimulationSpeed.values
                  .map(
                    (speed) => Expanded(
                      child: GestureDetector(
                        onTap: () => _changeSpeed(speed),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: currentSpeed == speed
                                ? Colors.red[600]
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              speed.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Formula1',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 0),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      selectedTab == 0 ? Colors.red[600] : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'STANDINGS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Formula1',
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 1),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      selectedTab == 1 ? Colors.red[600] : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'INCIDENTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Formula1',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return selectedTab == 0 ? _buildStandingsCard() : _buildIncidentsCard();
  }

  // UPDATED: Enhanced standings card with live badge and improved display
  Widget _buildStandingsCard() {
    return Container(
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
          // UPDATED: Header with live badge
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
                  'LIVE STANDINGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 1,
                  ),
                ),
                Spacer(),
                // UPDATED: Live status badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Formula1',
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Driver list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                return _buildDriverItem(drivers[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Get status color based on race state
  Color _getStatusColor() {
    if (raceFinished) return Colors.green[400]!;
    if (isRacing) return Colors.red[400]!;
    return Colors.orange[400]!;
  }

  // NEW: Get status text based on race state
  String _getStatusText() {
    if (raceFinished) return 'COMPLETE';
    if (isRacing) return 'LIVE';
    return 'PAUSED';
  }

  // UPDATED: Enhanced driver item display but keeping ALL original functions intact
  Widget _buildDriverItem(Driver driver, int index) {
    bool isPole = index == 0;
    bool isDNF = driver.isDNF();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // UPDATED: Position with special colors for 1,2,3
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getPositionColor(driver.position),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                driver.isDNF() ? 'DNF' : '${driver.position}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                ),
              ),
            ),
          ),

          SizedBox(width: 12),

          // UPDATED: Driver info with abbreviation and team color (no position change here)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.abbreviation, // UPDATED: Use abbreviation
                  style: TextStyle(
                    color: driver.team.primaryColor, // UPDATED: Use team color
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
                /*SizedBox(height: 2),
                Text(
                  driver.team.name,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
                    fontFamily: 'Formula1',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),*/
              ],
            ),
          ),

          // UPDATED: Better tire display but using ORIGINAL functions
          Container(
            width: 48,
            child: Column(
              children: [
                // KEEP original tire display structure but enhance visually
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black, // Black tire background
                    shape: BoxShape.circle, // Make it round like a tire
                    border: Border.all(
                      color: _getTireCompoundColor(
                          driver.currentCompound), // Compound color border
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getTireCompoundLetter(
                          driver.currentCompound), // ORIGINAL function
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 4),
                // UPDATED: Show tire condition percentage instead of laps
                Text(
                  '${_getTireConditionPercentage(driver)}%',
                  style: TextStyle(
                    color: _getTireWearColor(driver.calculateTyreDegradation()),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 12),

          // Gap text - fixed width to prevent overflow
          SizedBox(
            width: 60,
            child: Text(
              _getGapText(driver, isPole),
              style: TextStyle(
                color: isDNF
                    ? Colors.grey[500]
                    : (isPole ? Colors.white : Colors.grey[300]),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Formula1',
              ),
              textAlign: TextAlign.right,
            ),
          ),

          SizedBox(width: 8),

          // NEW: Position change column
          Container(
            width: 40,
            child: driver.positionChangeFromStart != 0
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        driver.positionChangeFromStart > 0
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: driver.positionChangeFromStart > 0
                            ? Colors.green[400]
                            : Colors.red[400],
                        size: 20,
                      ),
                      Text(
                        '${driver.positionChangeFromStart.abs()}', // Remove +/- since icon shows direction
                        style: TextStyle(
                          color: driver.positionChangeFromStart > 0
                              ? Colors.green[400]
                              : Colors.red[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Formula1',
                        ),
                      ),
                    ],
                  )
                : SizedBox(), // Empty space if no position change
          ),
        ],
      ),
    );
  }

  // UPDATED: Position colors - special for 1,2,3, same for others
  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber[600]!; // Gold for 1st
      case 2:
        return Colors.grey[400]!; // Silver for 2nd
      case 3:
        return Colors.orange[700]!; // Bronze for 3rd
      default:
        return Colors.grey[600]!; // Same blue for all others
    }
  }

  Widget _buildIncidentsCard() {
    List<Map<String, dynamic>> allIncidents = [];
    for (Driver driver in drivers) {
      for (String incident in driver.raceIncidents) {
        // Try to extract lap information from incident string
        int incidentLap = _extractLapFromIncident(incident);
        allIncidents.add({
          'driver': driver.name,
          'incident': incident,
          'lap': incidentLap,
        });
      }
    }

    // Sort incidents by lap number (oldest first)
    allIncidents.sort((a, b) => a['lap'].compareTo(b['lap']));

    return Container(
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
                    color: Colors.orange[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'RACE INCIDENTS',
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
                    '${allIncidents.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Formula1',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: allIncidents.isEmpty
                ? Center(
                    child: Text(
                      'No incidents yet',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontFamily: 'Formula1',
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: allIncidents.length,
                    itemBuilder: (context, index) {
                      // Show latest incidents first (reverse chronological)
                      Map<String, dynamic> incidentData =
                          allIncidents[allIncidents.length - 1 - index];
                      String driverName = incidentData['driver'];
                      String incidentText = incidentData['incident'];
                      int incidentLap = incidentData['lap'];

                      // Clean up incident text by removing lap prefix if present
                      String cleanIncidentText = incidentText;
                      RegExp lapPrefixPattern =
                          RegExp(r'^LAP \d+:\s*', caseSensitive: false);
                      cleanIncidentText =
                          cleanIncidentText.replaceFirst(lapPrefixPattern, '');

                      // Also remove alternative "Lap X:" format
                      RegExp lapPrefixPattern2 =
                          RegExp(r'^Lap \d+:\s*', caseSensitive: false);
                      cleanIncidentText =
                          cleanIncidentText.replaceFirst(lapPrefixPattern2, '');

                      IconData icon;
                      Color iconColor;

                      if (cleanIncidentText.toLowerCase().contains('pit') ||
                          cleanIncidentText.toLowerCase().contains('stop')) {
                        icon = Icons.local_gas_station;
                        iconColor = Colors.blue[400]!;
                      } else if (cleanIncidentText
                              .toLowerCase()
                              .contains('engine') ||
                          cleanIncidentText
                              .toLowerCase()
                              .contains('mechanical')) {
                        icon = Icons.build;
                        iconColor = Colors.orange[400]!;
                      } else if (cleanIncidentText
                              .toLowerCase()
                              .contains('crash') ||
                          cleanIncidentText.toLowerCase().contains('spin')) {
                        icon = Icons.warning;
                        iconColor = Colors.red[400]!;
                      } else {
                        icon = Icons.info;
                        iconColor = Colors.grey[400]!;
                      }

                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(6),
                          border: Border(
                            left: BorderSide(
                              width: 3,
                              color: iconColor,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Lap indicator - now shows correct lap for each incident
                            Container(
                              width: 40,
                              child: Column(
                                children: [
                                  Text(
                                    'LAP',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Formula1',
                                    ),
                                  ),
                                  Text(
                                    '${incidentLap}', // Show actual incident lap
                                    style: TextStyle(
                                      color: iconColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Formula1',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Icon(icon, color: iconColor, size: 16),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driverName.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Formula1',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    cleanIncidentText,
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 12,
                                      fontFamily: 'Formula1',
                                      height: 1.3,
                                    ),
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
          ),
        ],
      ),
    );
  }

  // Multi-purpose action button: START/PAUSE/VIEW RESULTS
  Widget _buildActionButton() {
    String buttonText;
    IconData buttonIcon;
    Color buttonColor;
    VoidCallback? onPressed;

    if (raceFinished) {
      // Race finished - show VIEW RESULTS
      buttonText = 'VIEW RESULTS';
      buttonIcon = Icons.flag;
      buttonColor = Colors.red[600]!;
      onPressed = _navigateToResults;
    } else if (isRacing) {
      // Race is ongoing - show PAUSE
      buttonText = 'PAUSE';
      buttonIcon = Icons.pause;
      buttonColor = Colors.orange[600]!;
      onPressed = _stopRace;
    } else {
      // Race not started or paused - show START
      buttonText = 'START';
      buttonIcon = Icons.play_arrow;
      buttonColor = Colors.green[600]!;
      onPressed = _startRace;
    }

    return Container(
      padding: EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(
            buttonIcon,
            color: Colors.white,
            size: 20,
          ),
          label: Text(
            buttonText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Formula1',
              letterSpacing: 1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  // ALL ORIGINAL HELPER METHODS KEPT EXACTLY AS THEY WERE
  double _getTireWearPercentage(Driver driver) {
    double degradation = driver.calculateTyreDegradation();
    double percentage = (degradation / 3.0) * 100.0;
    return percentage.clamp(0.0, 100.0);
  }

  // NEW: Get tire condition percentage (100% = good, 0% = bad)
  int _getTireConditionPercentage(Driver driver) {
    double wearPercentage = _getTireWearPercentage(driver);
    double conditionPercentage = 100.0 - wearPercentage;
    return conditionPercentage.clamp(0.0, 100.0).round();
  }

  // NEW: Extract lap number from incident string
  int _extractLapFromIncident(String incident) {
    // Try to find "LAP X:" pattern at the beginning of incident string
    RegExp lapPattern = RegExp(r'^LAP (\d+):', caseSensitive: false);
    Match? match = lapPattern.firstMatch(incident);
    if (match != null) {
      return int.parse(match.group(1)!);
    }

    // Try to find "Lap X:" pattern anywhere in the string (fallback)
    RegExp lapPatternFallback = RegExp(r'Lap (\d+):', caseSensitive: false);
    Match? matchFallback = lapPatternFallback.firstMatch(incident);
    if (matchFallback != null) {
      return int.parse(matchFallback.group(1)!);
    }

    // Fallback: use current lap if no lap info found
    return currentLap;
  }

  Color _getTireWearColor(double degradation) {
    double percentage = (degradation / 3.0) * 100.0;
    if (percentage <= 25) return Colors.green;
    if (percentage <= 50) return Colors.yellow[700]!;
    if (percentage <= 75) return Colors.orange;
    if (percentage <= 90) return Colors.red[600]!;
    return Colors.red[800]!;
  }

  Color _getTireCompoundColor(TireCompound compound) {
    return compound.color;
  }

  String _getTireCompoundLetter(TireCompound compound) {
    switch (compound) {
      case TireCompound.soft:
        return 'S';
      case TireCompound.medium:
        return 'M';
      case TireCompound.hard:
        return 'H';
      case TireCompound.intermediate:
        return 'I';
      case TireCompound.wet:
        return 'W';
    }
  }

  String _getGapText(Driver driver, bool isPole) {
    if (driver.isDNF()) return 'DNF';
    if (isPole) return 'LEADER';

    // Calculate interval to car ahead (not gap to leader)
    int currentIndex = drivers.indexOf(driver);
    if (currentIndex > 0) {
      double intervalToAhead =
          driver.totalTime - drivers[currentIndex - 1].totalTime;
      return '+${_formatTimeDifference(intervalToAhead)}';
    }

    return 'LEADER';
  }

  String _formatTimeDifference(double seconds) {
    if (seconds < 60.0) {
      return '${seconds.toStringAsFixed(3)}s';
    } else {
      int minutes = (seconds / 60).floor();
      double remainingSeconds = seconds % 60;
      return '${minutes}:${remainingSeconds.toStringAsFixed(3)}';
    }
  }
}
