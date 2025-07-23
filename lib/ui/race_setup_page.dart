// lib/ui/race_setup_page.dart - Updated for Career Mode integration
import 'package:flutter/material.dart';
import 'package:real_formula/services/career/career_manager.dart';
import '../models/driver.dart';
import '../models/career/career_driver.dart';
import '../models/track.dart';
import '../models/enums.dart';
import '../data/driver_data.dart';
import '../data/track_data.dart';

class RaceSetupPage extends StatefulWidget {
  @override
  _RaceSetupPageState createState() => _RaceSetupPageState();
}

class _RaceSetupPageState extends State<RaceSetupPage> with TickerProviderStateMixin {
  // Race configuration
  Track selectedTrack = TrackData.getDefaultTrack();
  WeatherCondition selectedWeather = WeatherCondition.clear;
  SimulationSpeed selectedSpeed = SimulationSpeed.normal;
  List<Driver> drivers = [];

  // NEW: Career mode detection
  bool isCareerMode = false;
  CareerDriver? careerDriver;

  // UI state
  int selectedTab = 0; // 0: Track, 1: Weather, 2: Drivers, 3: Settings

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeRaceSetup();

    // Setup animations
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if coming from career mode
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      isCareerMode = args['careerMode'] ?? false;
      careerDriver = args['careerDriver'];

      // Load other settings if provided
      selectedTrack = args['track'] ?? TrackData.getDefaultTrack();
      selectedWeather = args['weather'] ?? WeatherCondition.clear;
      selectedSpeed = args['speed'] ?? SimulationSpeed.normal;
    }

    _initializeDrivers();
  }

  void _initializeRaceSetup() {
    if (!isCareerMode) {
      // Standard race setup
      drivers = DriverData.createDefaultDrivers();
    }
  }

  void _initializeDrivers() {
    if (isCareerMode && careerDriver != null) {
      // Career mode: Create AI drivers + career driver
      drivers = _createCareerModeDrivers();
    } else if (drivers.isEmpty) {
      // Standard mode: Use default drivers
      drivers = DriverData.createDefaultDrivers();
    }
  }

  // Fixed _createCareerModeDrivers method for race_setup_page.dart
// Replace the existing method with this corrected version

  List<Driver> _createCareerModeDrivers() {
    List<Driver> careerDrivers = [];

    // Add the career driver first
    careerDrivers.add(careerDriver!);

    // Create AI drivers for all teams
    List<Driver> aiDrivers = DriverData.createDefaultDrivers();

    // Remove only ONE driver from the same team as career driver
    // This preserves the teammate
    bool removedTeammate = false;
    aiDrivers.removeWhere((driver) {
      if (driver.team.name == careerDriver!.team.name && !removedTeammate) {
        removedTeammate = true;
        return true; // Remove this driver (first teammate found)
      }
      return false; // Keep all other drivers
    });

    // Add all remaining AI drivers (including the preserved teammate)
    careerDrivers.addAll(aiDrivers);

    // Ensure we have exactly 20 drivers
    print('Career mode drivers: ${careerDrivers.length}');
    print('Career driver team: ${careerDriver!.team.name}');

    // Count drivers per team for debugging
    Map<String, int> driversPerTeam = {};
    for (var driver in careerDrivers) {
      driversPerTeam[driver.team.name] = (driversPerTeam[driver.team.name] ?? 0) + 1;
    }
    print('Drivers per team: $driversPerTeam');

    return careerDrivers;
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (isCareerMode) _buildCareerHeader(),
          _buildTabBar(),
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildTabContent(),
            ),
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Text(
            isCareerMode ? 'CAREER RACE SETUP' : 'RACE SETUP',
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
          if (isCareerMode) {
            // Return to career home
            Navigator.pop(context);
          } else {
            // Return to main menu
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  // NEW: Career mode header showing driver info
  Widget _buildCareerHeader() {
    if (careerDriver == null) return Container();

    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          // Career driver avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: careerDriver!.team.primaryColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: Center(
              child: Text(
                careerDriver!.abbreviation,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),

          // Career driver info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  careerDriver!.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${careerDriver!.team.name} • Season ${CareerManager.currentSeason}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Career stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rating: ${careerDriver!.careerRating.toStringAsFixed(1)}',
                style: TextStyle(
                  color: Colors.orange[300],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'XP: ${careerDriver!.experiencePoints}',
                style: TextStyle(
                  color: Colors.green[300],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    List<String> tabs = isCareerMode
        ? ['TRACK', 'WEATHER', 'GRID', 'SETTINGS'] // Different for career mode
        : ['TRACK', 'WEATHER', 'DRIVERS', 'SETTINGS'];

    return Container(
      color: Colors.grey[900],
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
                _slideController.reset();
                _slideController.forward();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red[600] : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Colors.red[600]! : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
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
        return _buildTrackSelection();
      case 1:
        return _buildWeatherSelection();
      case 2:
        return isCareerMode ? _buildCareerGrid() : _buildDriverLineup();
      case 3:
        return _buildRaceSettings();
      default:
        return Container();
    }
  }

  // Existing track selection (unchanged)
  Widget _buildTrackSelection() {
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
                Icon(Icons.track_changes, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  'SELECT CIRCUIT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Track list
          Expanded(
            child: ListView.builder(
              itemCount: TrackData.tracks.length,
              itemBuilder: (context, index) {
                Track track = TrackData.tracks[index];
                bool isSelected = selectedTrack.name == track.name;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTrack = track;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red[600]!.withOpacity(0.2) : Colors.grey[850],
                      border: Border.all(
                        color: isSelected ? Colors.red[600]! : Colors.grey[700]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                                  track.name.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${track.country.toUpperCase()} • ${track.typeDescription.toUpperCase()}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${track.totalLaps} LAPS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '~${track.baseLapTime.toStringAsFixed(1)}s',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          track.characteristicsInfo.toUpperCase(),
                          style: TextStyle(
                            color: Colors.orange[300],
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isSelected) ...[
                          SizedBox(height: 8),
                          Icon(
                            Icons.check_circle,
                            color: Colors.red[600],
                            size: 24,
                          ),
                        ],
                      ],
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

  // Existing weather selection (unchanged)
  Widget _buildWeatherSelection() {
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
                Icon(Icons.wb_sunny, color: Colors.yellow, size: 20),
                SizedBox(width: 8),
                Text(
                  'WEATHER CONDITIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Weather options
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: WeatherCondition.values.map((weather) {
                  bool isSelected = selectedWeather == weather;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedWeather = weather;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? weather.color.withOpacity(0.2) : Colors.grey[850],
                        border: Border.all(
                          color: isSelected ? weather.color : Colors.grey[700]!,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            weather.icon,
                            style: TextStyle(fontSize: 40),
                          ),
                          SizedBox(height: 8),
                          Text(
                            weather.name.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _getWeatherDescription(weather),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isSelected) ...[
                            SizedBox(height: 12),
                            Icon(
                              Icons.check_circle,
                              color: weather.color,
                              size: 24,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Career mode grid view (shows career driver + AI)
  Widget _buildCareerGrid() {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_list_numbered, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'STARTING GRID',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${drivers.length} DRIVERS',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Career driver highlight
          if (careerDriver != null) ...[
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[600]!.withOpacity(0.2),
                border: Border.all(color: Colors.orange[600]!, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.orange[400], size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR DRIVER',
                          style: TextStyle(
                            color: Colors.orange[300],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          careerDriver!.name.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${careerDriver!.team.name} • Rating: ${careerDriver!.careerRating.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // AI drivers list
          Expanded(
            child: ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                Driver driver = drivers[index];
                bool isCareerDriver = driver == careerDriver;

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCareerDriver ? Colors.orange[600]!.withOpacity(0.1) : Colors.grey[850],
                    border: Border.all(
                      color: isCareerDriver ? Colors.orange[600]! : Colors.grey[700]!,
                      width: isCareerDriver ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      // Grid position
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isCareerDriver ? Colors.orange[600] : driver.team.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
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
                                  driver.name.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isCareerDriver) ...[
                                  SizedBox(width: 8),
                                  Icon(Icons.star, color: Colors.orange[400], size: 16),
                                ],
                              ],
                            ),
                            Text(
                              driver.team.name.toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Stats
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'SPD ${driver.speed} • CON ${driver.consistency}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'CAR ${driver.team.carPerformance} • REL ${driver.team.reliability}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 9,
                            ),
                          ),
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

  // Existing driver lineup (for non-career mode)
  Widget _buildDriverLineup() {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'DRIVER LINEUP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${drivers.length} DRIVERS',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Driver list
          Expanded(
            child: ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                Driver driver = drivers[index];

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    border: Border.all(color: Colors.grey[700]!, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      // Position
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: driver.team.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
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
                            Text(
                              driver.name.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              driver.team.name.toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Stats
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'SPD ${driver.speed} • CON ${driver.consistency} • RAC ${driver.racecraft}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'CAR ${driver.team.carPerformance} • REL ${driver.team.reliability}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 9,
                            ),
                          ),
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

  // Existing race settings (unchanged)
  Widget _buildRaceSettings() {
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
                Icon(Icons.settings, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'RACE SETTINGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Settings content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Simulation speed
                  _buildSettingSection(
                    title: 'SIMULATION SPEED',
                    child: Row(
                      children: SimulationSpeed.values.map((speed) {
                        bool isSelected = selectedSpeed == speed;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: speed != SimulationSpeed.values.last ? 8 : 0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedSpeed = speed;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.red[600] : Colors.grey[700],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? Colors.red[400]! : Colors.grey[600]!,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    speed.label,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
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
                  ),

                  SizedBox(height: 24),

                  // Race summary
                  _buildSettingSection(
                    title: isCareerMode ? 'CAREER RACE SUMMARY' : 'RACE SUMMARY',
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[700]!, width: 1),
                      ),
                      child: Column(
                        children: [
                          if (isCareerMode) ...[
                            _buildSummaryRow('Driver', careerDriver?.name ?? 'Unknown'),
                            _buildSummaryRow('Team', careerDriver?.team.name ?? 'Unknown'),
                            _buildSummaryRow('Season', '${CareerManager.currentSeason}'),
                          ],
                          _buildSummaryRow('Track', selectedTrack.name),
                          _buildSummaryRow('Country', selectedTrack.country),
                          _buildSummaryRow('Laps', '${selectedTrack.totalLaps}'),
                          _buildSummaryRow('Weather', selectedWeather.name),
                          _buildSummaryRow('Speed', selectedSpeed.label),
                          _buildSummaryRow('Drivers', '${drivers.length}'),
                        ],
                      ),
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

  Widget _buildSettingSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
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
        color: Colors.grey[800],
        border: Border(
          top: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Start race button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                _startRace();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                elevation: 5,
                shadowColor: Colors.red.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flag,
                    size: 20,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    isCareerMode ? 'START CAREER RACE' : 'START RACE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
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

  String _getWeatherDescription(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.clear:
        return 'Perfect racing conditions with optimal grip and visibility. Drivers can push to the limit.';
      case WeatherCondition.rain:
        return 'Challenging wet conditions. Increased error probability and strategic complexity with wet tires.';
    }
  }

  void _startRace() {
    // Navigate to qualifying with configuration
    Navigator.pushNamed(
      context,
      '/qualifying',
      arguments: {
        'track': selectedTrack,
        'weather': selectedWeather,
        'speed': selectedSpeed,
        'drivers': drivers,
        'careerMode': isCareerMode,
        'careerDriver': careerDriver,
      },
    );
  }
}
