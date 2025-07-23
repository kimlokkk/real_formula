// lib/ui/race_setup_page.dart - Complete Fixed Version with Calendar Integration
import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../models/career/career_driver.dart';
import '../models/career/race_weekend.dart';
import '../models/track.dart';
import '../models/enums.dart';
import '../data/driver_data.dart';
import '../data/track_data.dart';
import '../services/career/career_manager.dart';

class RaceSetupPage extends StatefulWidget {
  const RaceSetupPage({Key? key}) : super(key: key); // ✅ FIXED: Added key parameter

  @override
  _RaceSetupPageState createState() => _RaceSetupPageState();
}

class _RaceSetupPageState extends State<RaceSetupPage> with TickerProviderStateMixin {
  // Race configuration
  Track selectedTrack = TrackData.getDefaultTrack();
  WeatherCondition selectedWeather = WeatherCondition.clear;
  SimulationSpeed selectedSpeed = SimulationSpeed.normal;
  List<Driver> drivers = [];

  // Career mode detection
  bool isCareerMode = false;
  CareerDriver? careerDriver;

  // 🆕 NEW: Calendar integration
  RaceWeekend? currentRaceWeekend;
  bool isCalendarRaceWeekend = false;

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

      // 🆕 NEW: Check for race weekend from calendar
      currentRaceWeekend = args['raceWeekend'];
      if (currentRaceWeekend != null) {
        isCalendarRaceWeekend = true;
        selectedTrack = currentRaceWeekend!.track;

        // Show race weekend info
        _showRaceWeekendInfo();
      } else {
        // Load other settings if provided
        selectedTrack = args['track'] ?? TrackData.getDefaultTrack();
      }

      selectedWeather = args['weather'] ?? WeatherCondition.clear;
      selectedSpeed = args['speed'] ?? SimulationSpeed.normal;
    }

    _initializeDrivers();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _initializeRaceSetup() {
    if (!isCareerMode) {
      drivers = DriverData.createDefaultDrivers();
    }
  }

  void _initializeDrivers() {
    if (isCareerMode && careerDriver != null) {
      drivers = _createCareerModeDrivers();
    } else if (drivers.isEmpty) {
      drivers = DriverData.createDefaultDrivers();
    }
  }

  List<Driver> _createCareerModeDrivers() {
    List<Driver> careerDrivers = [];

    // Create AI drivers (19 drivers)
    List<Driver> aiDrivers = DriverData.createDefaultDrivers().take(19).toList();

    // Add career driver (✅ FIXED: Removed isPlayer parameter)
    Driver careerDriverForRace = Driver(
      name: careerDriver!.name,
      abbreviation: careerDriver!.abbreviation,
      team: careerDriver!.team,
      speed: careerDriver!.speed,
      consistency: careerDriver!.consistency,
      racecraft: careerDriver!.racecraft,
      tyreManagementSkill: careerDriver!.tyreManagementSkill,
      experience: careerDriver!.experience,
    );

    careerDrivers.add(careerDriverForRace);
    careerDrivers.addAll(aiDrivers);

    return careerDrivers;
  }

  // 🆕 NEW: Show race weekend information dialog
  void _showRaceWeekendInfo() {
    if (currentRaceWeekend != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Row(
                children: [
                  Icon(Icons.sports_motorsports, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Race Weekend', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentRaceWeekend!.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Track: ${currentRaceWeekend!.track.name}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Text(
                    'Date: ${currentRaceWeekend!.dateRange}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Text(
                    'Round: ${currentRaceWeekend!.round} of 24',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'You are participating in the official F1 calendar race weekend. Track selection is locked to the scheduled circuit.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'UNDERSTOOD',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          isCareerMode ? 'CAREER RACE SETUP' : 'RACE SETUP',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: _startRace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'START',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            _buildTabNavigation(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    List<String> tabs = ['TRACK', 'WEATHER', 'DRIVERS', 'SETTINGS'];
    List<IconData> icons = [
      Icons.track_changes,
      Icons.cloud,
      Icons.groups,
      Icons.settings,
    ];
    List<Color> colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.green,
    ];

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(
          bottom: BorderSide(color: Colors.grey[700]!, width: 1),
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
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? colors[index].withValues(alpha: 0.2) : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? colors[index] : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      color: isSelected ? colors[index] : Colors.grey[400],
                      size: 20,
                    ),
                    SizedBox(height: 4),
                    Text(
                      tabs[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
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

  // 🆕 UPDATED: Track selection with calendar integration
  Widget _buildTrackSelection() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Track selection header
          Row(
            children: [
              Icon(Icons.map, color: Colors.red[400], size: 24),
              SizedBox(width: 12),
              Text(
                'SELECT TRACK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              // 🆕 NEW: Calendar race indicator
              if (isCalendarRaceWeekend) ...[
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'CALENDAR RACE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: 20),

          // Track card
          GestureDetector(
            // 🆕 UPDATED: Disable tap for calendar races
            onTap: isCalendarRaceWeekend ? null : _showTrackSelector,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[800]!, Colors.grey[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  // 🆕 UPDATED: Orange border for calendar races
                  color: isCalendarRaceWeekend ? Colors.orange[600]! : Colors.red[600]!,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedTrack.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // 🆕 UPDATED: Only show arrow for non-calendar races
                      if (!isCalendarRaceWeekend) Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 24),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    selectedTrack.country,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      // ✅ FIXED: Use correct property names
                      _buildTrackStat('Laps', '${selectedTrack.totalLaps}'),
                      SizedBox(width: 20),
                      _buildTrackStat('Type', selectedTrack.typeDescription),
                      SizedBox(width: 20),
                      _buildTrackStat('Base Time', '${selectedTrack.baseLapTime.toStringAsFixed(1)}s'),
                    ],
                  ),

                  // 🆕 NEW: Calendar race info
                  if (isCalendarRaceWeekend && currentRaceWeekend != null) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[600]!.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange[600]!.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.orange[300], size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Round ${currentRaceWeekend!.round} • ${currentRaceWeekend!.dateRange}',
                            style: TextStyle(
                              color: Colors.orange[300],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 🆕 UPDATED: Description section
          if (!isCalendarRaceWeekend) ...[
            SizedBox(height: 16),
            Text(
              selectedTrack.characteristicsInfo, // ✅ FIXED: Use correct property
              style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5),
            ),
          ] else ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[900]!.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue[600]!.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[300], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is an official F1 calendar race weekend. Track and weather settings may be preset for realism.',
                      style: TextStyle(color: Colors.blue[300], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          style: TextStyle(color: Colors.grey[400], fontSize: 10),
        ),
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

  void _showTrackSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[700]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'SELECT CIRCUIT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: TrackData.tracks.length,
                itemBuilder: (context, index) {
                  Track track = TrackData.tracks[index];
                  bool isSelected = selectedTrack.name == track.name;

                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red[600] : Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.track_changes,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      track.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${track.country} • ${track.totalLaps} laps',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: isSelected ? Icon(Icons.check, color: Colors.red[600]) : null,
                    onTap: () {
                      setState(() {
                        selectedTrack = track;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherSelection() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, color: Colors.blue[400], size: 24),
              SizedBox(width: 12),
              Text(
                'WEATHER CONDITIONS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: WeatherCondition.values.map((weather) {
                bool isSelected = selectedWeather == weather;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedWeather = weather;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [Colors.blue[600]!, Colors.blue[800]!]
                            : [Colors.grey[800]!, Colors.grey[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue[400]! : Colors.grey[600]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getWeatherIcon(weather),
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          weather.name.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _getWeatherDescription(weather),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.clear:
        return Icons.wb_sunny;
      case WeatherCondition.rain: // ✅ FIXED: Only use existing enum values
        return Icons.water_drop;
    }
  }

  String _getWeatherDescription(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.clear:
        return 'Perfect racing conditions. Drivers can push to the limit.';
      case WeatherCondition.rain: // ✅ FIXED: Only use existing enum values
        return 'Challenging wet conditions. Increased error probability and strategic complexity with wet tires.';
    }
  }

  Widget _buildDriverLineup() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.groups, color: Colors.purple[400], size: 24),
              SizedBox(width: 12),
              Text(
                'DRIVER LINEUP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                Driver driver = drivers[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[700]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: driver.team.primaryColor,
                          borderRadius: BorderRadius.circular(15),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
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
                      Text(
                        '${driver.speed}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
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

  Widget _buildCareerGrid() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.purple[400], size: 24),
              SizedBox(width: 12),
              Text(
                'CAREER DRIVER GRID',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (careerDriver != null) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[800]!, Colors.green[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[400]!, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: careerDriver!.team.primaryColor,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${careerDriver!.name} (YOU)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          careerDriver!.team.name,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Rating: ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${careerDriver!.careerRating.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
          Text(
            'AI COMPETITORS',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: drivers.length - 1, // Exclude career driver
              itemBuilder: (context, index) {
                Driver driver = drivers[index + 1]; // Skip career driver
                return Container(
                  margin: EdgeInsets.only(bottom: 6),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: driver.team.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 2}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          driver.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        driver.team.name,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 9,
                        ),
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

  Widget _buildRaceSettings() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.green[400], size: 24),
              SizedBox(width: 12),
              Text(
                'RACE SETTINGS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
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
                            _buildSummaryRow('Season', CareerManager.currentSeason.toString()),
                          ],
                          _buildSummaryRow('Track', selectedTrack.name),
                          _buildSummaryRow('Country', selectedTrack.country),
                          _buildSummaryRow('Laps', '${selectedTrack.totalLaps}'),
                          _buildSummaryRow('Weather', selectedWeather.name),
                          _buildSummaryRow('Speed', selectedSpeed.label),
                          _buildSummaryRow('Drivers', '${drivers.length}'),
                          // 🆕 NEW: Calendar race info
                          if (isCalendarRaceWeekend && currentRaceWeekend != null) ...[
                            _buildSummaryRow('Round', '${currentRaceWeekend!.round} of 24'),
                            _buildSummaryRow('Date', currentRaceWeekend!.dateRange),
                          ],
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: 12),
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
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 UPDATED: Start race method with calendar integration
  void _startRace() {
    Map<String, dynamic> raceArguments = {
      'track': selectedTrack,
      'weather': selectedWeather,
      'speed': selectedSpeed,
      'drivers': drivers,
      'careerMode': isCareerMode,
      'careerDriver': careerDriver,
    };

    // 🆕 NEW: Add race weekend info for calendar races
    if (isCalendarRaceWeekend && currentRaceWeekend != null) {
      raceArguments['raceWeekend'] = currentRaceWeekend;
      raceArguments['isCalendarRace'] = true;
    }

    Navigator.pushNamed(context, '/qualifying', arguments: raceArguments);
  }
}
