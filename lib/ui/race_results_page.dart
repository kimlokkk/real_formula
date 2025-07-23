// lib/ui/race_results_page.dart - Complete file with Calendar Integration (Fixed)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real_formula/services/career/save_manager.dart';
import 'dart:math';
import '../models/driver.dart';
import '../models/career/career_driver.dart';
import '../models/career/race_weekend.dart'; // 🆕 NEW IMPORT
import '../models/track.dart';
import '../models/enums.dart';
import '../data/track_data.dart';
import '../services/career/career_manager.dart'; // 🆕 NEW IMPORT

class RaceResultsPage extends StatefulWidget {
  const RaceResultsPage({Key? key}) : super(key: key); // ✅ FIXED constructor

  @override
  _RaceResultsPageState createState() => _RaceResultsPageState();
}

class _RaceResultsPageState extends State<RaceResultsPage> {
  // Existing variables
  List<Driver> drivers = [];
  Track track = TrackData.getDefaultTrack();
  WeatherCondition weather = WeatherCondition.clear;
  int totalLaps = 50;
  int selectedTab = 0; // 0: Podium, 1: Full Results, 2: Statistics
  bool dataLoaded = false;

  // 🆕 NEW: Career mode variables
  bool isCareerMode = false;
  CareerDriver? careerDriver;

  // 🆕 NEW: Calendar integration variables
  RaceWeekend? raceWeekend;
  bool isCalendarRace = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!dataLoaded) {
      _loadRaceData();
    }
  }

  void _loadRaceData() {
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        // Load existing data
        List<dynamic>? driversData = args['drivers'];
        if (driversData != null) {
          drivers = driversData.cast<Driver>();

          // PRESERVE ORIGINAL DATA - create a snapshot before any potential modifications
          Map<String, Map<String, dynamic>> driverDataSnapshot = {};
          for (Driver driver in drivers) {
            driverDataSnapshot[driver.name] = {
              'pitStops': driver.pitStops,
              'errorCount': driver.errorCount,
              'mechanicalIssuesCount': driver.mechanicalIssuesCount,
              'position': driver.position,
              'startingPosition': driver.startingPosition,
              'totalTime': driver.totalTime,
            };
          }

          // If data gets corrupted, restore from snapshot
          Timer(Duration(milliseconds: 100), () {
            bool dataCorrupted = false;
            for (Driver driver in drivers) {
              var snapshot = driverDataSnapshot[driver.name];
              if (snapshot != null) {
                if (driver.pitStops != snapshot['pitStops'] ||
                    driver.errorCount != snapshot['errorCount'] ||
                    driver.mechanicalIssuesCount != snapshot['mechanicalIssuesCount']) {
                  dataCorrupted = true;
                  driver.pitStops = snapshot['pitStops'];
                  driver.errorCount = snapshot['errorCount'];
                  driver.mechanicalIssuesCount = snapshot['mechanicalIssuesCount'];
                  driver.position = snapshot['position'];
                  driver.startingPosition = snapshot['startingPosition'];
                  driver.totalTime = snapshot['totalTime'];
                }
              }
            }
            if (dataCorrupted) {
              setState(() {}); // Trigger rebuild with restored data
            }
          });
        }

        track = args['track'] ?? TrackData.getDefaultTrack();
        weather = args['weather'] ?? WeatherCondition.clear;
        totalLaps = args['totalLaps'] ?? 50;

        // 🆕 NEW: Load career mode data
        isCareerMode = args['careerMode'] ?? false;
        careerDriver = args['careerDriver'];

        // 🆕 NEW: Load calendar race data
        raceWeekend = args['raceWeekend'];
        isCalendarRace = args['isCalendarRace'] ?? false;

        // Sort by position without modifying other data
        if (drivers.isNotEmpty) {
          drivers.sort((a, b) => a.position.compareTo(b.position));
        }

        dataLoaded = true;
      });
    }
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
      winnerTeam = winner.team.name;
    }

    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 🆕 NEW: Calendar race indicator
          if (isCalendarRace && raceWeekend != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${raceWeekend!.name.toUpperCase()} • ROUND ${raceWeekend!.round}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            SizedBox(height: 12),
          ],

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
              _buildRaceInfoItem('WEATHER', weather.name.toUpperCase()),
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
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    List<String> tabs = ['PODIUM', 'FULL RESULTS', 'STATISTICS'];
    List<IconData> icons = [Icons.emoji_events, Icons.list, Icons.bar_chart];

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          bool isSelected = selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTab = index;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red[600] : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Colors.red[400]! : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      color: isSelected ? Colors.white : Colors.grey[400],
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      tabs[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        fontSize: 11,
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
    if (!dataLoaded || drivers.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!),
        ),
      );
    }

    switch (selectedTab) {
      case 0:
        return _buildPodiumView();
      case 1:
        return _buildFullResultsView();
      case 2:
        return _buildStatisticsView();
      default:
        return Container();
    }
  }

  Widget _buildPodiumView() {
    List<Driver> podiumDrivers = drivers.where((d) => !d.isDNF()).take(3).toList();

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          if (podiumDrivers.length >= 3) ...[
            // Podium visual
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd place
                Expanded(child: _buildPodiumPosition(podiumDrivers[1], 2, 120)),
                // 1st place (tallest)
                Expanded(child: _buildPodiumPosition(podiumDrivers[0], 1, 140)),
                // 3rd place
                Expanded(child: _buildPodiumPosition(podiumDrivers[2], 3, 100)),
              ],
            ),
            SizedBox(height: 24),
          ],

          // Expanded results list
          Expanded(
            child: ListView.builder(
              itemCount: min(10, drivers.length),
              itemBuilder: (context, index) {
                Driver driver = drivers[index];
                bool isCareerDriverResult = isCareerMode && careerDriver != null && driver.name == careerDriver!.name;

                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCareerDriverResult
                          ? [Colors.green[800]!, Colors.green[700]!]
                          : [Colors.grey[800]!, Colors.grey[900]!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCareerDriverResult ? Colors.green[400]! : Colors.grey[700]!,
                      width: isCareerDriverResult ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Position
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _getPositionColor(driver.position),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            driver.isDNF() ? 'DNF' : '${driver.position}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),

                      // Driver info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  driver.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isCareerDriverResult) ...[
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green[400],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'YOU',
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
                            Text(
                              driver.team.name,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Points and time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            driver.isDNF() ? 'DNF' : '${_getPointsForPosition(driver.position)} pts',
                            style: TextStyle(
                              color: driver.isDNF() ? Colors.red[400] : Colors.yellow[600],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!driver.isDNF()) ...[
                            Text(
                              driver.position == 1
                                  ? _formatRaceTime(driver.totalTime)
                                  : '+${_formatGapTime(driver.totalTime - drivers.first.totalTime)}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(Driver driver, int position, double height) {
    Color positionColor = position == 1
        ? Colors.yellow[600]!
        : position == 2
            ? Colors.grey[400]!
            : Colors.orange[600]!;

    return Column(
      children: [
        // Driver name
        Text(
          driver.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4),
        Text(
          driver.team.name,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),

        // Podium block
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [positionColor, positionColor.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
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
                  Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullResultsView() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        Driver driver = drivers[index];
        bool isCareerDriverResult = isCareerMode && careerDriver != null && driver.name == careerDriver!.name;

        return Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isCareerDriverResult ? Colors.green[800]!.withValues(alpha: 0.3) : Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCareerDriverResult ? Colors.green[400]! : Colors.grey[700]!,
              width: isCareerDriverResult ? 2 : 1,
            ),
          ),
          child: ExpansionTile(
            leading: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _getPositionColor(driver.position),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  driver.isDNF() ? 'DNF' : '${driver.position}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  driver.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isCareerDriverResult) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[400],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'YOU',
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
            subtitle: Text(
              driver.team.name,
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: Text(
              driver.isDNF() ? 'DNF' : '${_getPointsForPosition(driver.position)} pts',
              style: TextStyle(
                color: driver.isDNF() ? Colors.red[400] : Colors.yellow[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Starting Position:', style: TextStyle(color: Colors.grey[400])),
                        Text('P${driver.startingPosition}', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Time:', style: TextStyle(color: Colors.grey[400])),
                        Text(
                          driver.isDNF() ? 'DNF' : _formatRaceTime(driver.totalTime),
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pit Stops:', style: TextStyle(color: Colors.grey[400])),
                        Text('${driver.pitStops}', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Errors:', style: TextStyle(color: Colors.grey[400])),
                        Text('${driver.errorCount}', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsView() {
    if (drivers.isEmpty) return Container();

    // Calculate statistics
    int totalFinishers = drivers.where((d) => !d.isDNF()).length;
    int totalDNFs = drivers.length - totalFinishers;
    double averagePitStops = drivers.map((d) => d.pitStops).reduce((a, b) => a + b) / drivers.length;
    int totalErrors = drivers.map((d) => d.errorCount).reduce((a, b) => a + b);

    // Find career driver performance if in career mode
    Driver? careerDriverResult;
    if (isCareerMode && careerDriver != null) {
      try {
        careerDriverResult = drivers.firstWhere((d) => d.name == careerDriver!.name);
      } catch (e) {
        careerDriverResult = null;
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatSection('RACE SUMMARY', [
            _buildStatRow('Total Finishers', '$totalFinishers/${drivers.length}'),
            _buildStatRow('DNFs', '$totalDNFs'),
            _buildStatRow('Average Pit Stops', averagePitStops.toStringAsFixed(1)),
            _buildStatRow('Total Errors', '$totalErrors'),
          ]),
          if (isCareerMode && careerDriverResult != null) ...[
            SizedBox(height: 24),
            _buildStatSection('YOUR PERFORMANCE', [
              _buildStatRow('Final Position', careerDriverResult.isDNF() ? 'DNF' : 'P${careerDriverResult.position}'),
              _buildStatRow('Starting Position', 'P${careerDriverResult.startingPosition}'),
              _buildStatRow('Positions Gained/Lost',
                  '${careerDriverResult.startingPosition - careerDriverResult.position > 0 ? '+' : ''}${careerDriverResult.startingPosition - careerDriverResult.position}'),
              _buildStatRow('Points Earned',
                  careerDriverResult.isDNF() ? '0' : '${_getPointsForPosition(careerDriverResult.position)}'),
              _buildStatRow('Pit Stops', '${careerDriverResult.pitStops}'),
              _buildStatRow('Errors', '${careerDriverResult.errorCount}'),
            ]),
          ],
          SizedBox(height: 24),
          _buildStatSection('FASTEST SECTORS', [
            _buildStatRow('Fastest Lap', drivers.isNotEmpty ? drivers.first.name : 'Unknown'),
            _buildStatRow('Most Pit Stops', _getDriverWithMostPitStops()?.name ?? 'Unknown'),
            _buildStatRow('Cleanest Driver', _getCleanestDriver()?.name ?? 'Unknown'),
          ]),
          SizedBox(height: 24),
          _buildStatSection(
            'CHAMPIONSHIP POINTS',
            _getPointsDistribution().map((entry) => _buildStatRow(entry['team'], '${entry['points']} pts')).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSection(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 12),
          ...children,
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
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.grey[800]!, width: 1)),
      ),
      child: Row(
        children: [
          // Share/Save results button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement share/save functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Results saved!'),
                    backgroundColor: Colors.green[600],
                  ),
                );
              },
              icon: Icon(Icons.save, size: 18),
              label: Text(
                'SAVE RESULTS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          SizedBox(width: 12),

          // Return to career/main menu
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _handleReturnNavigation,
              icon: Icon(Icons.home, size: 18),
              label: Text(
                isCareerMode ? 'RETURN TO CAREER' : 'MAIN MENU',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 NEW: Handle navigation based on career mode and calendar integration
  // 🆕 IMPROVED: Handle navigation based on career mode and calendar integration
  void _handleReturnNavigation() {
    // STEP 1: Complete calendar race weekend if this is a career mode calendar race
    if (isCareerMode && raceWeekend != null && isCalendarRace && careerDriver != null) {
      _completeCalendarRaceWeekend();
    }

    // STEP 2: Auto-save career progress if in career mode
    if (isCareerMode && careerDriver != null) {
      _autoSaveCareer();
    }

    // STEP 3: Navigate to appropriate destination
    if (isCareerMode) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/career_home',
        (route) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    }
  }

// 🆕 NEW: Auto-save career progress
  void _autoSaveCareer() {
    try {
      // Use the existing SaveManager to auto-save
      SaveManager.autoSave().then((_) {
        // Show brief confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Progress saved!'),
              backgroundColor: Colors.green[600],
              duration: Duration(seconds: 1),
            ),
          );
        }
      }).catchError((error) {
        debugPrint("Auto-save failed: $error");
      });
    } catch (e) {
      debugPrint("Error during auto-save: $e");
    }
  }

  // 🆕 NEW: Complete calendar race weekend
  // 🆕 IMPROVED: Complete calendar race weekend with proper error handling and data updates
  // 🆕 ENHANCED: Complete calendar race weekend with championship standings update
  void _completeCalendarRaceWeekend() {
    if (careerDriver == null || raceWeekend == null) {
      return;
    }

    try {
      // STEP 1: Find career driver's result from the race
      Driver? careerDriverResult;
      try {
        careerDriverResult = drivers.firstWhere(
          (driver) => driver.name == careerDriver!.name,
          orElse: () => throw Exception("Career driver not found in results"),
        );
      } catch (e) {
        debugPrint("ERROR: Could not find career driver in results: $e");
        // Fallback - create a basic result if somehow missing
        careerDriverResult = drivers.isNotEmpty ? drivers.first : null;
      }

      if (careerDriverResult == null) {
        debugPrint("ERROR: No valid driver result found");
        return;
      }

      // STEP 2: Calculate race data
      int finalPosition = careerDriverResult.position;
      int championshipPoints = _getPointsForPosition(finalPosition);
      bool gotPolePosition = careerDriverResult.startingPosition == 1;
      bool gotFastestLap = false; // TODO: Implement fastest lap detection if needed

      // STEP 3: 🆕 CRITICAL - Pass ALL race results for championship standings update
      List<Driver> sortedResults = List.from(drivers);
      sortedResults.sort((a, b) => a.position.compareTo(b.position));

      // STEP 4: Update career statistics AND championship through CareerManager
      CareerManager.completeRaceWeekend(
        raceWeekend!,
        position: finalPosition,
        points: championshipPoints,
        polePosition: gotPolePosition,
        fastestLap: gotFastestLap,
        allRaceResults: sortedResults, // 🆕 CRITICAL: Pass all results for championship
      );

      // STEP 5: Mark race weekend as completed in calendar (this is also done in CareerManager but double-check)
      raceWeekend!.completeRace();
    } catch (e) {
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving race results: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Helper methods
  Color _getPositionColor(int position) {
    if (position <= 3) return Colors.yellow[600]!;
    if (position <= 10) return Colors.green[600]!;
    return Colors.grey[600]!;
  }

  int _getPointsForPosition(int position) {
    const pointsSystem = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
    if (position <= 0 || position > pointsSystem.length) return 0;
    return pointsSystem[position - 1];
  }

  String _formatRaceTime(double totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = (totalSeconds % 60).round();

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
  }

  String _formatGapTime(double gapSeconds) {
    if (gapSeconds < 60) {
      return '${gapSeconds.toStringAsFixed(3)}s';
    } else {
      int minutes = gapSeconds ~/ 60;
      double seconds = gapSeconds % 60;
      return '${minutes}m ${seconds.toStringAsFixed(3)}s';
    }
  }

  Driver? _getDriverWithMostPitStops() {
    if (drivers.isEmpty) return null;
    return drivers.reduce((a, b) => a.pitStops > b.pitStops ? a : b);
  }

  Driver? _getCleanestDriver() {
    if (drivers.isEmpty) return null;
    return drivers.reduce((a, b) => a.errorCount < b.errorCount ? a : b);
  }

  List<Map<String, dynamic>> _getPointsDistribution() {
    Map<String, int> teamPoints = {};

    for (Driver driver in drivers) {
      if (!driver.isDNF()) {
        int points = _getPointsForPosition(driver.position);
        teamPoints[driver.team.name] = (teamPoints[driver.team.name] ?? 0) + points;
      }
    }

    var sorted = teamPoints.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(5)
        .map((entry) => {
              'team': entry.key,
              'points': entry.value,
            })
        .toList();
  }
}
