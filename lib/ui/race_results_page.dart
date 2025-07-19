import 'package:flutter/material.dart';
import 'dart:math';
import '../models/driver.dart';
import '../models/track.dart';
import '../models/enums.dart';
import '../data/track_data.dart';

class RaceResultsPage extends StatefulWidget {
  @override
  _RaceResultsPageState createState() => _RaceResultsPageState();
}

class _RaceResultsPageState extends State<RaceResultsPage> {
  List<Driver> drivers = [];
  Track track = TrackData.getDefaultTrack();
  WeatherCondition weather = WeatherCondition.clear;
  int totalLaps = 50;

  int selectedTab = 0; // 0: Podium, 1: Full Results, 2: Statistics
  bool dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRaceData();
  }

  void _loadRaceData() {
    // Load data in initState to avoid repeated calls
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      print("=== RACE RESULTS DEBUG ===");
      print("Arguments received: $args");

      if (args != null && mounted) {
        setState(() {
          // DON'T create new instances - use the original drivers directly
          drivers = args['drivers'] ?? [];
          track = args['track'] ?? TrackData.getDefaultTrack();
          weather = args['weather'] ?? WeatherCondition.clear;
          totalLaps = args['totalLaps'] ?? 50;

          print("Drivers received: ${drivers.length}");
          if (drivers.isNotEmpty) {
            print("First driver: ${drivers[0].name}, Pits: ${drivers[0].pitStops}, Errors: ${drivers[0].errorCount}");
            print("Second driver: ${drivers[1].name}, Pits: ${drivers[1].pitStops}, Errors: ${drivers[1].errorCount}");
          }

          // Sort drivers by position
          if (drivers.isNotEmpty) {
            drivers.sort((a, b) {
              if (a.isDNF() && b.isDNF()) return 0;
              if (a.isDNF()) return 1;
              if (b.isDNF()) return -1;
              return a.position.compareTo(b.position);
            });
          }

          dataLoaded = true;
        });
      } else {
        print("No arguments received - creating mock data");
        _createMockData();
      }
    });
  }

  void _createMockData() {
    setState(() {
      // Create mock drivers with realistic race data
      drivers = [
        _createMockDriver("Hamilton", "Mercedes", 1, 2, 1, 0),
        _createMockDriver("Verstappen", "Red Bull", 2, 1, 0, 1),
        _createMockDriver("Leclerc", "Ferrari", 3, 3, 2, 0),
        _createMockDriver("Russell", "Mercedes", 4, 1, 0, 2),
        _createMockDriver("Sainz", "Ferrari", 5, 2, 1, 1),
        _createMockDriver("Norris", "McLaren", 6, 1, 3, 0),
        _createMockDriver("Piastri", "McLaren", 7, 2, 0, 1),
        _createMockDriver("Alonso", "Aston Martin", 8, 1, 1, 2),
      ];

      track = TrackData.getDefaultTrack();
      weather = WeatherCondition.clear;
      totalLaps = 50;
      dataLoaded = true;

      print("Mock data created with ${drivers.length} drivers");
    });
  }

  Driver _createMockDriver(String name, String team, int position, int pitStops, int errors, int mechanical) {
    Driver driver = Driver(
      name: name,
      team: team,
      speed: 80 + (position * 2),
      consistency: 75 + (position * 3),
      tyreManagementSkill: 70 + (position * 2),
      carPerformance: 85 + (position * 2),
      reliability: 80 + (position * 1),
      teamColor: _getTeamColor(team),
    );

    // Set additional properties after creation
    driver.position = position;
    driver.startingPosition = position + Random().nextInt(3) - 1; // Some position changes
    driver.pitStops = pitStops;
    driver.totalTime = 4500.0 + (position * 15.0); // Realistic lap times
    driver.errorCount = errors;
    driver.mechanicalIssuesCount = mechanical;
    driver.lapsCompleted = totalLaps;
    driver.positionChangeFromStart = driver.startingPosition - driver.position;

    return driver;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildRaceHeader(),
          _buildTabBar(),
          Expanded(
            child: _buildTabContent(),
          ),
          _buildBottomControls(),
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
            'RACE RESULTS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      automaticallyImplyLeading: false,
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              'FINISHED',
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
    String raceWinner = "Unknown";
    String winnerTeam = "Unknown";

    if (dataLoaded && drivers.isNotEmpty) {
      Driver winner = drivers.firstWhere((d) => !d.isDNF(), orElse: () => drivers.first);
      raceWinner = winner.name;
      winnerTeam = winner.team;
    }

    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'RACE WINNER',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 3,
            ),
          ),
          SizedBox(height: 8),
          Text(
            raceWinner.toUpperCase(),
            style: TextStyle(
              color: Colors.yellow,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          Text(
            winnerTeam.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRaceInfoItem('TRACK', track.name),
              _buildRaceInfoItem('LAPS', '$totalLaps'),
              _buildRaceInfoItem('WEATHER', weather.name),
              _buildRaceInfoItem('FINISHERS', '${_getFinisherCount()}/${drivers.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRaceInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  int _getFinisherCount() {
    return drivers.where((driver) => !driver.isDNF()).length;
  }

  Widget _buildTabBar() {
    List<String> tabs = ['PODIUM', 'FULL RESULTS', 'STATISTICS'];
    List<IconData> icons = [Icons.emoji_events, Icons.format_list_numbered, Icons.analytics];

    return Container(
      color: Colors.grey[800],
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          int index = entry.key;
          String tab = entry.value;
          bool isSelected = selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTab = index;
                });
              },
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
    if (!dataLoaded) {
      return Center(
        child: CircularProgressIndicator(color: Colors.red[600]),
      );
    }

    switch (selectedTab) {
      case 0:
        return _buildPodiumCeremony();
      case 1:
        return _buildFullResults();
      case 2:
        return _buildStatistics();
      default:
        return _buildPodiumCeremony();
    }
  }

  Widget _buildPodiumCeremony() {
    if (drivers.isEmpty) {
      return _buildNoDataMessage('No race data available');
    }

    List<Driver> finishedDrivers = drivers.where((d) => !d.isDNF()).toList();

    if (finishedDrivers.isEmpty) {
      return _buildNoDataMessage('No drivers finished the race');
    }

    List<Driver> podiumDrivers = finishedDrivers.take(3).toList();

    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
          _buildSectionHeader('PODIUM CEREMONY', Icons.emoji_events, Colors.yellow),
          Expanded(
            child: Center(
              child: _buildPodium(podiumDrivers),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < min(3, podiumDrivers.length); i++) _buildPodiumDetail(podiumDrivers[i], i + 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Driver> podiumDrivers) {
    return Container(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // P2 (left)
          if (podiumDrivers.length > 1) _buildPodiumStep(podiumDrivers[1], 2, 100, Colors.grey[300]!),

          SizedBox(width: 12),

          // P1 (center, tallest)
          if (podiumDrivers.isNotEmpty) _buildPodiumStep(podiumDrivers[0], 1, 140, Colors.yellow),

          SizedBox(width: 12),

          // P3 (right)
          if (podiumDrivers.length > 2) _buildPodiumStep(podiumDrivers[2], 3, 80, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildPodiumStep(Driver driver, int position, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTeamColor(driver.team),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Text(
                driver.name.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                driver.team.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$position',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (position == 1) ...[
                SizedBox(height: 8),
                Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumDetail(Driver driver, int position) {
    String positionSuffix = position == 1
        ? 'ST'
        : position == 2
            ? 'ND'
            : 'RD';

    String gapDisplay = "WINNER";
    if (position > 1 && drivers.isNotEmpty && drivers[0].totalTime > 0 && driver.totalTime > 0) {
      double gap = driver.totalTime - drivers[0].totalTime;
      gapDisplay = "+${gap.toStringAsFixed(1)}s";
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border.all(
          color: position == 1
              ? Colors.yellow
              : position == 2
                  ? Colors.grey[300]!
                  : Colors.orange,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: position == 1
                  ? Colors.yellow
                  : position == 2
                      ? Colors.grey[300]!
                      : Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$position$positionSuffix',
                style: TextStyle(
                  color: position == 2 ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  driver.team.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                gapDisplay,
                style: TextStyle(
                  color: position == 1 ? Colors.yellow : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${driver.pitStops} PIT${driver.pitStops != 1 ? 'S' : ''}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullResults() {
    if (drivers.isEmpty) {
      return _buildNoDataMessage('No race data available');
    }

    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
          _buildSectionHeader('FINAL CLASSIFICATION', Icons.format_list_numbered, Colors.blue),
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                return _buildResultRow(drivers[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(
          bottom: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
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
        color: Colors.grey[850],
        border: Border(
          bottom: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
              width: 40,
              child: Text('POS', style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500))),
          Expanded(
              flex: 3,
              child:
                  Text('DRIVER', style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500))),
          Container(
              width: 60,
              child: Text('PITS',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center)),
          Container(
              width: 60,
              child: Text('ISSUES',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center)),
          Container(
              width: 100,
              child: Text('TIME/GAP',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildResultRow(Driver driver, int index) {
    bool isWinner = index == 0 && !driver.isDNF();
    bool isPodium = index < 3 && !driver.isDNF();

    String gapDisplay = "DNF";
    if (!driver.isDNF()) {
      if (index == 0) {
        gapDisplay = "WINNER";
      } else if (drivers.isNotEmpty && drivers[0].totalTime > 0 && driver.totalTime > 0) {
        double gap = driver.totalTime - drivers[0].totalTime;
        gapDisplay = "+${gap.toStringAsFixed(1)}s";
      } else {
        gapDisplay = "+${(index * 2.5).toStringAsFixed(1)}s";
      }
    }

    return Container(
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
            width: 40,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: driver.isDNF() ? Colors.grey[600] : _getTeamColor(driver.team),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Text(
                      driver.isDNF() ? 'DNF' : '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: driver.isDNF() ? 8 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (isPodium) ...[
                  SizedBox(width: 4),
                  Icon(
                    Icons.emoji_events,
                    color: isWinner ? Colors.yellow : Colors.orange,
                    size: 12,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name.toUpperCase(),
                  style: TextStyle(
                    color: driver.isDNF() ? Colors.grey[500] : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  driver.team.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            child: Text(
              '${driver.pitStops}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (driver.errorCount > 0) ...[
                  Icon(Icons.error, color: Colors.red, size: 12),
                  Text('${driver.errorCount}', style: TextStyle(color: Colors.red, fontSize: 10)),
                ],
                if (driver.mechanicalIssuesCount > 0) ...[
                  if (driver.errorCount > 0) SizedBox(width: 4),
                  Icon(Icons.build, color: Colors.orange, size: 12),
                  Text('${driver.mechanicalIssuesCount}', style: TextStyle(color: Colors.orange, fontSize: 10)),
                ],
                if (driver.errorCount == 0 && driver.mechanicalIssuesCount == 0)
                  Text('-', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 100,
            child: Text(
              gapDisplay,
              style: TextStyle(
                color: driver.isDNF() ? Colors.grey[500] : (isWinner ? Colors.yellow : Colors.white),
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

  Widget _buildStatistics() {
    if (drivers.isEmpty) {
      return _buildNoDataMessage('No race data available');
    }

    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
          _buildSectionHeader('RACE STATISTICS', Icons.analytics, Colors.green),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatCard('RACE OVERVIEW', _buildRaceOverviewStats()),
                  SizedBox(height: 16),
                  _buildStatCard('DRIVER PERFORMANCE', _buildDriverPerformanceStats()),
                  SizedBox(height: 16),
                  _buildStatCard('TEAM PERFORMANCE', _buildTeamPerformanceStats()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, List<Widget> stats) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 12),
          ...stats,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRaceOverviewStats() {
    int totalPitStops = 0;
    int totalErrors = 0;
    int totalMechanical = 0;
    int finishers = 0;

    for (Driver driver in drivers) {
      totalPitStops += driver.pitStops;
      totalErrors += driver.errorCount;
      totalMechanical += driver.mechanicalIssuesCount;
      if (!driver.isDNF()) finishers++;
    }

    print("=== RACE OVERVIEW STATS ===");
    print("Total pit stops: $totalPitStops");
    print("Total errors: $totalErrors");
    print("Total mechanical: $totalMechanical");
    print("Finishers: $finishers");

    return [
      _buildStatRow('Total Laps', '$totalLaps'),
      _buildStatRow('Drivers', '${drivers.length}'),
      _buildStatRow('Finishers', '$finishers'),
      _buildStatRow('DNFs', '${drivers.length - finishers}'),
      _buildStatRow('Total Pit Stops', '$totalPitStops'),
      _buildStatRow('Total Errors', '$totalErrors'),
      _buildStatRow('Mechanical Issues', '$totalMechanical'),
      _buildStatRow('Weather', weather.name.toUpperCase()),
      _buildStatRow('Track', track.name.toUpperCase()),
    ];
  }

  List<Widget> _buildDriverPerformanceStats() {
    String mostPitStops = 'None';
    String fewestErrors = 'None';
    String mostReliable = 'None';
    String biggestClimber = 'None';

    int maxPits = 0;
    int minErrors = 999;
    int minMechanical = 999;
    int maxClimb = 0;

    List<Driver> finishers = drivers.where((d) => !d.isDNF()).toList();

    print("=== STATISTICS CALCULATION DEBUG ===");
    print("Total drivers: ${drivers.length}");
    print("Finishers: ${finishers.length}");

    // Most pit stops
    for (Driver driver in drivers) {
      print(
          "Driver ${driver.name}: Pits=${driver.pitStops}, Errors=${driver.errorCount}, Mechanical=${driver.mechanicalIssuesCount}");
      if (driver.pitStops > maxPits) {
        maxPits = driver.pitStops;
        mostPitStops = '${driver.name} ($maxPits)';
      }
    }

    // Fewest errors (finishers only)
    for (Driver driver in finishers) {
      if (driver.errorCount < minErrors) {
        minErrors = driver.errorCount;
        fewestErrors = '${driver.name} ($minErrors)';
      }
    }

    // Most reliable (finishers only)
    for (Driver driver in finishers) {
      if (driver.mechanicalIssuesCount < minMechanical) {
        minMechanical = driver.mechanicalIssuesCount;
        mostReliable = '${driver.name} ($minMechanical issues)';
      }
    }

    // Biggest climber (finishers only)
    for (Driver driver in finishers) {
      int positionChange = driver.startingPosition - driver.position; // Positive = gained positions
      print(
          "Driver ${driver.name}: Started P${driver.startingPosition}, Finished P${driver.position}, Change: $positionChange");
      if (positionChange > maxClimb) {
        maxClimb = positionChange;
        biggestClimber = '${driver.name} (+$maxClimb)';
      }
    }

    print(
        "Results: MostPits=$mostPitStops, FewestErrors=$fewestErrors, MostReliable=$mostReliable, BiggestClimber=$biggestClimber");

    return [
      _buildStatRow('Most Pit Stops', maxPits > 0 ? mostPitStops : 'None'),
      _buildStatRow('Fewest Errors', finishers.isNotEmpty ? fewestErrors : 'All DNF'),
      _buildStatRow('Most Reliable', finishers.isNotEmpty ? mostReliable : 'All DNF'),
      _buildStatRow('Biggest Climber', maxClimb > 0 ? biggestClimber : 'None'),
    ];
  }

  List<Widget> _buildTeamPerformanceStats() {
    Map<String, String> teamResults = {};

    for (Driver driver in drivers) {
      if (!driver.isDNF()) {
        String current = teamResults[driver.team] ?? '';
        if (current.isEmpty || driver.position < _extractPosition(current)) {
          teamResults[driver.team] = 'P${driver.position} (${driver.name})';
        }
      } else {
        if (!teamResults.containsKey(driver.team)) {
          teamResults[driver.team] = 'All DNF';
        }
      }
    }

    return teamResults.entries.map((entry) => _buildStatRow(entry.key, entry.value)).toList();
  }

  int _extractPosition(String result) {
    if (result.startsWith('P')) {
      String posStr = result.substring(1, result.indexOf(' '));
      return int.tryParse(posStr) ?? 999;
    }
    return 999;
  }

  Widget _buildNoDataMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.grey[400], size: 48),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
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

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(
          top: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[600]!, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home, size: 18),
                    SizedBox(width: 8),
                    Text('MAIN MENU', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/setup', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.red.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('NEW RACE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
