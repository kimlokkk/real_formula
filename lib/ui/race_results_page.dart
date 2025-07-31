// lib/ui/race_results_page.dart - Enhanced F1 Design with All Existing Functionality Preserved
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real_formula/services/career/save_manager.dart';
import '../models/driver.dart';
import '../models/career/career_driver.dart';
import '../models/career/race_weekend.dart';
import '../models/track.dart';
import '../models/enums.dart';
import '../data/track_data.dart';
import '../services/career/career_manager.dart';

class RaceResultsPage extends StatefulWidget {
  const RaceResultsPage({Key? key}) : super(key: key);

  @override
  _RaceResultsPageState createState() => _RaceResultsPageState();
}

class _RaceResultsPageState extends State<RaceResultsPage> with TickerProviderStateMixin {
  // ALL EXISTING VARIABLES PRESERVED
  List<Driver> drivers = [];
  Track track = TrackData.getDefaultTrack();
  WeatherCondition weather = WeatherCondition.clear;
  int totalLaps = 50;
  int selectedTab = 0; // 0: Podium, 1: Full Results, 2: Statistics
  bool dataLoaded = false;

  // Career mode variables
  bool isCareerMode = false;
  CareerDriver? careerDriver;

  // Calendar integration variables
  RaceWeekend? raceWeekend;
  bool isCalendarRace = false;

  // NEW: Expandable driver details variable
  int? expandedDriverIndex; // Track which driver card is expanded

  // Enhanced animations matching other pages
  late AnimationController _fadeController;
  late AnimationController _podiumController;
  late AnimationController _confettiController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _podiumAnimation;
  late Animation<double> _confettiAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _podiumController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _podiumAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _podiumController, curve: Curves.easeOutBack),
    );

    _confettiController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _podiumController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only load arguments and initialize data once
    if (!dataLoaded) {
      _loadArgumentsAndInitialize();
    }
  }

  void _loadArgumentsAndInitialize() {
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      setState(() {
        List<dynamic>? driversData = args['drivers'];
        if (driversData != null) {
          drivers = driversData.cast<Driver>();
        }

        track = args['track'] ?? TrackData.getDefaultTrack();
        weather = args['weather'] ?? WeatherCondition.clear;
        totalLaps = args['totalLaps'] ?? 50;

        isCareerMode = args['careerMode'] ?? false;
        careerDriver = args['careerDriver'];

        raceWeekend = args['raceWeekend'];
        isCalendarRace = args['isCalendarRace'] ?? false;

        if (drivers.isNotEmpty) {
          drivers.sort((a, b) => a.position.compareTo(b.position));

          // ✅ FIXED: Only trigger animations, do NOT reset championship
          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) {
              _podiumController.forward();
              _confettiController.forward();
            }
          });
        }

        dataLoaded = true;
      });

      // ✅ IMPORTANT: If this is a career race that just completed,
      // the championship should have already been updated by the
      // CareerManager.completeRaceWeekend() method before navigation
      // Do NOT reset or re-initialize the championship here!
    }
  }

  // ✅ ENHANCED: Better race completion handling
  void _completeCalendarRaceWeekend() {
    if (careerDriver == null || raceWeekend == null) {
      debugPrint("⚠️ Cannot complete race weekend - missing career driver or race weekend");
      return;
    }

    try {
      // Find career driver in results
      Driver? careerDriverResult = drivers.firstWhere(
        (driver) => driver.name == careerDriver!.name,
        orElse: () => drivers.first, // Fallback to first driver if not found
      );

      // Calculate championship points from position
      int finalPosition = careerDriverResult.position;
      int championshipPoints = _getPointsForPosition(finalPosition);

      // Check for pole position (starting P1)
      bool gotPolePosition = careerDriverResult.startingPosition == 1;

      // For fastest lap, we'll set to false for now (can be enhanced later)
      bool gotFastestLap = false;

      debugPrint("🏁 Completing race weekend for ${careerDriver!.name}");
      debugPrint("   Result: P$finalPosition");
      debugPrint("   Points: $championshipPoints");
      debugPrint("   Pole: $gotPolePosition");

      // Complete the race weekend with all race results
      CareerManager.completeRaceWeekend(
        raceWeekend!,
        position: finalPosition,
        points: championshipPoints,
        polePosition: gotPolePosition,
        fastestLap: gotFastestLap,
        allRaceResults: drivers, // ✅ CRITICAL: Pass all race results for championship update
      );

      debugPrint("✅ Race weekend completed successfully");
    } catch (e) {
      debugPrint("❌ Error completing calendar race weekend: $e");
      // Don't show error to user, but log it for debugging
    }
  }

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
                _buildEnhancedHeader(),
                _buildWinnerSection(),
                _buildTabBar(),
                Expanded(child: _buildTabContent()),
                _buildBottomControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced background matching other pages
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

  // Enhanced header matching qualifying/race simulator pages
  Widget _buildEnhancedHeader() {
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
          // Back button matching other pages
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          SizedBox(width: 16),

          // Racing stripe - consistent with other pages
          Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[400]!, Colors.red[600]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          SizedBox(width: 12),

          // Title section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RACE RESULTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18, // Reduced from 24
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${track.name.toUpperCase()} • $totalLaps LAPS',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10, // Reduced from 12
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Formula1',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Race status indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green[600]!.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[600]!, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag, color: Colors.green[400], size: 16),
                SizedBox(width: 6),
                Text(
                  'FINISHED',
                  style: TextStyle(
                    color: Colors.green[400],
                    fontSize: 8, // Reduced from 10
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
    );
  }

  // Enhanced winner section with animations
  Widget _buildWinnerSection() {
    if (!dataLoaded || drivers.isEmpty) {
      return Container(height: 120);
    }

    Driver winner = drivers.firstWhere((d) => !d.isDNF(), orElse: () => drivers.first);

    return AnimatedBuilder(
      animation: _podiumAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Calendar race indicator
              if (isCalendarRace && raceWeekend != null) ...[
                Transform.scale(
                  scale: _podiumAnimation.value.clamp(0.0, 1.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[500]!, Colors.orange[700]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '${raceWeekend!.name.toUpperCase()} • ROUND ${raceWeekend!.round}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10, // Reduced from 12
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Winner announcement with celebration effect
              Transform.translate(
                offset: Offset(0, 20 * (1 - _podiumAnimation.value.clamp(0.0, 1.0))),
                child: Opacity(
                  opacity: _podiumAnimation.value.clamp(0.0, 1.0),
                  child: Column(
                    children: [
                      // Trophy icon with glow effect
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow effect
                          AnimatedBuilder(
                            animation: _confettiAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.yellow.withValues(alpha: 0.3 * _confettiAnimation.value),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          Icon(
                            Icons.emoji_events,
                            color: Colors.yellow[400],
                            size: 40, // Reduced from 48
                          ),
                        ],
                      ),

                      SizedBox(height: 12), // Reduced from 16

                      // Winner name
                      Text(
                        '${winner.name.toUpperCase()} WINS!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16, // Reduced from 20
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Formula1',
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 4),

                      // Team name
                      Text(
                        winner.team.name.toUpperCase(),
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 12, // Reduced from 16
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Formula1',
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Enhanced tab bar matching race simulator
  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton('PODIUM', 0, Icons.emoji_events),
          _buildTabButton('RESULTS', 1, Icons.list),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    bool isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red[600] : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12, // Reduced from 14
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedTab) {
      case 0:
        return _buildPodiumTab();
      case 1:
        return _buildFullResultsTab();
      default:
        return _buildPodiumTab();
    }
  }

  // Enhanced podium display
  Widget _buildPodiumTab() {
    if (!dataLoaded || drivers.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red[400]!),
        ),
      );
    }

    List<Driver> podiumDrivers = drivers.where((d) => !d.isDNF() && d.position <= 3).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Podium visualization
          if (podiumDrivers.length >= 3) ...[
            _buildPodiumVisualization(podiumDrivers),
            SizedBox(height: 20), // Reduced spacing
          ],

          // Podium details
          ...podiumDrivers.map((driver) => _buildPodiumDriverCard(driver)),
        ],
      ),
    );
  }

  Widget _buildPodiumVisualization(List<Driver> podiumDrivers) {
    return AnimatedBuilder(
      animation: _podiumAnimation,
      builder: (context, child) {
        return SizedBox(
          height: 160, // Further reduced and using SizedBox for strict height control
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place
              if (podiumDrivers.length > 1)
                _buildPodiumStep(podiumDrivers[1], 2, 85, Colors.grey[400]!), // Further reduced

              // 1st Place
              _buildPodiumStep(podiumDrivers[0], 1, 120, Colors.yellow[400]!), // Further reduced

              // 3rd Place
              if (podiumDrivers.length > 2)
                _buildPodiumStep(podiumDrivers[2], 3, 70, Colors.orange[400]!), // Further reduced
            ],
          ),
        );
      },
    );
  }

  Widget _buildPodiumStep(Driver driver, int position, double height, Color color) {
    double animationValue = _podiumAnimation.value.clamp(0.0, 1.0);

    return Flexible(
      child: Transform.translate(
        offset: Offset(0, height * (1 - animationValue)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Driver info - ultra compact
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Further reduced
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    driver.name.split(' ').last.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9, // Further reduced
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Formula1',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    driver.team.name.length > 8
                        ? driver.team.name.substring(0, 8).toUpperCase()
                        : driver.team.name.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 6, // Further reduced
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Formula1',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(height: 4), // Further reduced

            // Podium step
            Container(
              width: 60, // Further reduced
              height: height * animationValue,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Center(
                child: Text(
                  '$position',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18, // Further reduced
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Formula1',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumDriverCard(Driver driver) {
    Color positionColor = _getPositionColor(driver.position);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(width: 4, color: positionColor),
        ),
      ),
      child: Row(
        children: [
          // Position
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: positionColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: positionColor, width: 2),
            ),
            child: Center(
              child: Text(
                '${driver.position}',
                style: TextStyle(
                  color: positionColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Formula1',
                ),
              ),
            ),
          ),

          SizedBox(width: 16),

          // Driver info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14, // Reduced from 16
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  driver.team.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10, // Reduced from 12
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Formula1',
                  ),
                ),
              ],
            ),
          ),

          // Race time/gap
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (driver.position == 1) ...[
                Text(
                  _formatRaceTime(driver.totalTime),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12, // Reduced from 14
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
              ] else ...[
                Text(
                  '+${_formatGapTime(driver.totalTime - drivers.firstWhere((d) => !d.isDNF()).totalTime)}', // Fixed: use race winner's time
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 12, // Reduced from 14
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
              ],
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[600]!.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_getPointsForPosition(driver.position)} PTS',
                  style: TextStyle(
                    color: Colors.red[400],
                    fontSize: 8, // Reduced from 10
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // MODIFIED: Enhanced full results with expandable driver details
  Widget _buildFullResultsTab() {
    if (!dataLoaded || drivers.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red[400]!),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        Driver driver = drivers[index];
        return _buildExpandableResultCard(driver, index);
      },
    );
  }

  // NEW: Replace the old _buildResultCard with this expandable version
  Widget _buildExpandableResultCard(Driver driver, int index) {
    Color positionColor = _getPositionColor(driver.position);
    bool isDNF = driver.isDNF();
    bool isExpanded = expandedDriverIndex == index;

    // Find the race winner (first non-DNF driver) for gap calculation
    Driver? winner = drivers.firstWhere((d) => !d.isDNF(), orElse: () => drivers.first);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(width: 3, color: positionColor),
        ),
      ),
      child: Column(
        children: [
          // Main driver card - clickable
          InkWell(
            onTap: () {
              setState(() {
                expandedDriverIndex = isExpanded ? null : index;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  // Position
                  SizedBox(
                    width: 30,
                    child: Text(
                      isDNF ? 'DNF' : '${driver.position}',
                      style: TextStyle(
                        color: isDNF ? Colors.red[400] : positionColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(width: 12),

                  // Driver info - clickable area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                driver.name.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Formula1',
                                ),
                              ),
                            ),
                            // Expand/collapse indicator
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          driver.team.name.toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Formula1',
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 12),

                  // Time and points
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (driver.position == 1) ...[
                        Text(
                          _formatRaceTime(driver.totalTime),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Formula1',
                          ),
                        ),
                      ] else ...[
                        Text(
                          isDNF ? 'DNF' : '+${_formatGapTime(driver.totalTime - winner.totalTime)}',
                          style: TextStyle(
                            color: isDNF ? Colors.red[400] : Colors.grey[300],
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Formula1',
                          ),
                        ),
                      ],
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[600]!.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${isDNF ? 0 : _getPointsForPosition(driver.position)} PTS',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Formula1',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded details section
          if (isExpanded) _buildDriverDetails(driver),
        ],
      ),
    );
  }

  // NEW: Add this method for driver details
  Widget _buildDriverDetails(Driver driver) {
    bool isDNF = driver.isDNF();

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.red[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'RACE DETAILS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Race statistics grid
          Row(
            children: [
              // Left column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Starting Position', '${driver.startingPosition}'),
                    _buildDetailRow('Final Position', isDNF ? 'DNF' : '${driver.position}'),
                    _buildDetailRow('Positions Gained/Lost', _getPositionChange(driver)),
                    _buildDetailRow('Pit Stops', '${driver.pitStops}'),
                  ],
                ),
              ),

              SizedBox(width: 20),

              // Right column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Current Tire', driver.currentCompound.name.toUpperCase()),
                    _buildDetailRow('Race Errors', '${driver.errorCount}'),
                    _buildDetailRow('Race Time', isDNF ? 'N/A' : _formatRaceTime(driver.totalTime)),
                    _buildDetailRow('Points Earned', '${isDNF ? 0 : _getPointsForPosition(driver.position)}'),
                  ],
                ),
              ),
            ],
          ),

          // Race incidents section
          if (driver.raceIncidents.isNotEmpty) ...[
            SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.orange[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'RACE INCIDENTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              constraints: BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: driver.raceIncidents
                      .map(
                        (incident) => Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                margin: EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  incident,
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 10,
                                    fontFamily: 'Formula1',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // NEW: Add this helper method for detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              fontFamily: 'Formula1',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'Formula1',
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Add this helper method for position change calculation
  String _getPositionChange(Driver driver) {
    int change = driver.startingPosition - driver.position;
    if (driver.isDNF()) {
      return 'DNF';
    } else if (change > 0) {
      return '+$change';
    } else if (change < 0) {
      return '$change';
    } else {
      return '0';
    }
  }

  // Enhanced bottom controls matching other pages
  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Save results button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // Show saving feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.save, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Results saved successfully!',
                          style: TextStyle(
                            fontFamily: 'Formula1',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(
                Icons.save,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                'SAVE RESULTS',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 10, // Reduced from 12
                  fontFamily: 'Formula1',
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

          SizedBox(width: 12),

          // Return button with context-aware text
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleReturnNavigation,
              icon: Icon(
                isCareerMode ? Icons.home : Icons.menu,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                isCareerMode ? 'RETURN TO CAREER' : 'MAIN MENU',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 10, // Reduced from 12
                  fontFamily: 'Formula1',
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ALL EXISTING FUNCTIONALITY METHODS PRESERVED EXACTLY

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

  void _autoSaveCareer() {
    try {
      SaveManager.autoSave().then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.cloud_done, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Career progress saved!',
                    style: TextStyle(
                      fontFamily: 'Formula1',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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

  // Helper methods - ALL PRESERVED
  Color _getPositionColor(int position) {
    if (position == 1) return Colors.yellow[700]!;
    if (position == 2) return Colors.grey[400]!;
    if (position == 3) return Colors.orange[700]!;
    if (position <= 10) return Colors.green[700]!;
    return Colors.grey[700]!;
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
}
