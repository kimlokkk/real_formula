// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:real_formula/services/career/save_manager.dart';
import 'package:real_formula/ui/career/save_load_menu.dart';

import '../../models/team.dart'; // lib/ui/career/career_home_page.dart - Navigation-Based Career Hub with Real Data
import 'package:flutter/material.dart';
import 'package:real_formula/services/career/career_calendar.dart';
import 'package:real_formula/services/career/career_manager.dart';
import 'package:real_formula/services/career/championship_manager.dart';
import 'package:real_formula/ui/career/career_calendar_widget.dart';
import '../../models/career/career_driver.dart';
import '../../models/career/contract.dart';
import '../../models/driver.dart';
import '../../data/team_data.dart';
import '../../data/driver_data.dart';

class CareerHomePage extends StatefulWidget {
  @override
  _CareerHomePageState createState() => _CareerHomePageState();
}

class _CareerHomePageState extends State<CareerHomePage>
    with TickerProviderStateMixin {
  CareerDriver? careerDriver;
  int selectedNavIndex = 0; // Navigation index
  bool showRaceWeekendAlert = false;
  int? selectedDriverIndex; // For driver details expansion

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    careerDriver = CareerManager.currentCareerDriver;

    _initializeAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCalendarSafely();
      _fadeController.forward();
      _refreshCareerData();

      // 🆕 NEW: Auto-save when entering career home (safety save)
      _autoSaveCareer();
    });
  }

// 🆕 NEW: Add this method to career_home_page.dart
  void _autoSaveCareer() async {
    if (CareerManager.currentCareerDriver != null) {
      try {
        bool success = await SaveManager.saveCurrentCareer();
        if (success) {
          debugPrint("✅ Career auto-saved on home page entry");
        } else {
          debugPrint("⚠️ Auto-save failed on home page entry");
        }
      } catch (e) {
        debugPrint("❌ Auto-save error: $e");
      }
    }
  }

  void _initializeCalendarSafely() {
    // 🔧 FIX: For new careers, always start fresh
    if (CareerManager.currentCareerDriver == null) {
      debugPrint("📅 No career driver - skipping calendar initialization");
      return;
    }

    // Check if we have existing races with completion state
    int existingRaces = CareerCalendar.instance.raceWeekends.length;
    int completedRaces = CareerCalendar.instance.getCompletedRaces().length;

    debugPrint("📅 Career home initializing calendar...");
    debugPrint("   Career driver: ${CareerManager.currentCareerDriver!.name}");
    debugPrint("   Existing races: $existingRaces");
    debugPrint("   Completed races: $completedRaces");

    // 🔧 FIX: Only initialize calendar for truly brand new careers
    // If we have ANY races, preserve the existing state (loaded from save)
    if (existingRaces == 0) {
      // No races at all - this should only happen for truly new careers
      debugPrint(
          "📅 No existing races found - initializing fresh calendar for new career");
      CareerCalendar.instance.initializeForNewCareer();
    } else {
      // 🔧 FIX: Don't touch the calendar if it already has races
      // The save/load system should have already loaded the correct state
      debugPrint("📅 Preserving existing calendar state (loaded from save)");
      debugPrint(
          "   Next race: ${CareerCalendar.instance.nextRaceWeekend?.name ?? 'Season Complete'}");

      // 🔧 FIX: Force refresh the calendar UI
      CareerCalendar.instance.notifyListeners();
    }
  }

  void _initializeAnimations() {
    // Pulse animation for XP indicator
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);

    // Fade animation
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshCareerData();
      }
    });
  }

  void _onRaceWeekendReached() {
    setState(() {
      showRaceWeekendAlert = true;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _refreshCareerData() {
    try {
      CareerDriver? updatedDriver = CareerManager.currentCareerDriver;
      if (updatedDriver != null) {
        setState(() {
          careerDriver = updatedDriver;
        });

        // 🔧 FIX: Force calendar widget to rebuild by explicitly calling notifyListeners
        CareerCalendar.instance.notifyListeners();

        // 🔧 FIX: Add small delay to ensure state updates propagate
        Future.delayed(Duration(milliseconds: 100), () {
          // 🔧 FIX: Force another rebuild to ensure UI is current
          if (mounted) {
            setState(() {});
          }

          debugPrint(
              "🔄 Career data refreshed - UI should now show updated calendar");
        });
      }
    } catch (e) {
      debugPrint("Error refreshing career data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (careerDriver == null) {
      return Scaffold(
        body: Container(
          decoration: _buildBackgroundGradient(),
          child: Center(
            child: CircularProgressIndicator(color: Colors.red[400]),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: _buildBackgroundGradient(),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              // PRESERVE: Race weekend alert (essential functionality)
              if (showRaceWeekendAlert) _buildRaceWeekendAlert(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCurrentPage(),
                ),
              ),
              //_buildBottomNavigation(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.red[600]!.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.home, color: Colors.white),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/', (route) => false),
            ),
          ),

          SizedBox(width: 16),

          // Racing stripe
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
                  'F1 CAREER MODE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '${careerDriver!.name} • ${careerDriver!.team.name}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Formula1',
                  ),
                ),
              ],
            ),
          ),

          // Save button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.save, color: Colors.white),
              onPressed: _saveCareer,
            ),
          ),
        ],
      ),
    );
  }

  // PRESERVE: Essential race weekend alert functionality
  Widget _buildRaceWeekendAlert() {
    final raceWeekend = CareerCalendar.instance.currentRaceWeekend;
    if (raceWeekend == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[600]!, Colors.orange[800]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange[600]!.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.sports_motorsports, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RACE WEEKEND ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${raceWeekend.name} • ${raceWeekend.track.name}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontFamily: 'Formula1',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/race_weekend_loading',
                      arguments: {
                        'raceWeekend': raceWeekend,
                        'careerDriver': careerDriver,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange[800],
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'START RACE WEEKEND',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Formula1',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  CareerCalendar.instance.resumeCalendar();
                  setState(() {
                    showRaceWeekendAlert = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'SKIP',
                  style: TextStyle(
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

  Widget _buildCurrentPage() {
    switch (selectedNavIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildStandingsPage();
      case 2:
        return _buildContractPage();
      case 3:
        return _buildSkillsPage();
      case 4:
        return _buildCarsPage();
      case 5:
        return _buildDriversPage();
      default:
        return _buildHomePage();
    }
  }

  // HOME PAGE - Overview + Calendar
  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDriverOverviewCard(),
          _buildQuickStatsRow(),
          _buildCalendarSection(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDriverOverviewCard() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            careerDriver!.team.primaryColor.withOpacity(0.15),
            careerDriver!.team.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: careerDriver!.team.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Driver helmet/avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: careerDriver!.team.primaryColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: careerDriver!.team.primaryColor.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                careerDriver!.abbreviation,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                ),
              ),
            ),
          ),

          SizedBox(width: 20),

          // Driver info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  careerDriver!.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${careerDriver!.team.name} • Season ${CareerManager.currentSeason}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontFamily: 'Formula1',
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.emoji_events,
                        color: Colors.orange[300], size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Rating: ${careerDriver!.careerRating.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: Colors.orange[300],
                        fontSize: 12,
                        fontFamily: 'Formula1',
                      ),
                    ),
                    SizedBox(width: 16),
                    // XP indicator with pulse animation
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: careerDriver!.experiencePoints > 0
                                  ? Colors.green[600]
                                  : Colors.grey[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${careerDriver!.experiencePoints} XP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Formula1',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'WINS',
              '${careerDriver!.careerWins}',
              Icons.emoji_events,
              Colors.amber,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'PODIUMS',
              '${careerDriver!.careerPodiums}',
              Icons.military_tech,
              Colors.orange[400]!,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'POINTS',
              '${careerDriver!.careerPoints}',
              Icons.stars,
              Colors.blue[400]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'Formula1',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontFamily: 'Formula1',
            ),
          ),
        ],
      ),
    );
  }

  // PRESERVE: Calendar section with all existing functionality
  Widget _buildCalendarSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
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
                  'SEASON CALENDAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          // PRESERVE: Existing calendar widget with all functionality
          CareerCalendarWidget(
            onRaceWeekendReached: _onRaceWeekendReached,
          ),
        ],
      ),
    );
  }

  // STANDINGS PAGE - Championship Standings (ALL DRIVERS + CONSTRUCTORS)
  Widget _buildStandingsPage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Driver Standings
          _buildDriverStandingsCard(),
          SizedBox(height: 20),
          // Constructor Standings
          _buildConstructorStandingsCard(),
        ],
      ),
    );
  }

  Widget _buildDriverStandingsCard() {
    // Get all drivers including career driver (with 0 points to start)
    List<ChampionshipStanding> allDrivers =
        ChampionshipManager.getCurrentStandings(
            careerDriverName: careerDriver!.name);

    // If championship is empty (season not started), initialize with all drivers at 0 points
    if (allDrivers.isEmpty) {
      allDrivers = _initializeEmptyStandings();
    }

    return Container(
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.yellow[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'DRIVER CHAMPIONSHIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Championship table header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    child: Text(
                      'POS',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'DRIVER',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'TEAM',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                      ),
                    ),
                  ),
                  Container(
                    width: 60,
                    child: Text(
                      'POINTS',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 8),

          // Driver standings (all drivers with 0 points initially)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: allDrivers
                  .asMap()
                  .entries
                  .map((entry) => _buildStandingRow(entry.value, entry.key + 1))
                  .toList(),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildConstructorStandingsCard() {
    Map<String, int> constructorPoints = _calculateConstructorStandings();
    List<MapEntry<String, int>> sortedConstructors = constructorPoints.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'CONSTRUCTOR CHAMPIONSHIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Constructor standings
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: sortedConstructors
                  .asMap()
                  .entries
                  .map((entry) => _buildConstructorRow(
                      entry.value.key, entry.value.value, entry.key + 1))
                  .toList(),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildConstructorRow(String teamName, int points, int position) {
    Team? team = TeamData.teams.firstWhere((t) => t.name == teamName,
        orElse: () => TeamData.teams.first);
    bool isCurrentTeam = teamName == careerDriver!.team.name;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentTeam
            ? team.primaryColor.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentTeam
            ? Border.all(color: team.primaryColor, width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Position
          Container(
            width: 40,
            child: Text(
              '$position',
              style: TextStyle(
                color: _getPositionColor(position),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Formula1',
              ),
            ),
          ),
          // Team color indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: team.primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.sports_motorsports,
              color: Colors.white,
              size: 14,
            ),
          ),
          SizedBox(width: 16),
          // Team name
          Expanded(
            child: Text(
              teamName,
              style: TextStyle(
                color: isCurrentTeam ? Colors.white : Colors.grey[300],
                fontSize: 14,
                fontWeight: isCurrentTeam ? FontWeight.w700 : FontWeight.w400,
                fontFamily: 'Formula1',
              ),
            ),
          ),
          // Points
          Container(
            width: 60,
            child: Text(
              '$points',
              style: TextStyle(
                color: isCurrentTeam ? team.primaryColor : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Formula1',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  List<ChampionshipStanding> _initializeEmptyStandings() {
    List<Driver> allDrivers = _getAllDriversIncludingCareer();

    return allDrivers
        .map((driver) => ChampionshipStanding(
              driverName: driver.name,
              teamName: driver.team.name,
              points: 0,
              wins: 0,
              podiums: 0,
              isCareerDriver: driver.name == careerDriver!.name,
            ))
        .toList();
  }

  Map<String, int> _calculateConstructorStandings() {
    Map<String, int> constructorPoints = {};

    // Initialize all teams with 0 points
    for (Team team in TeamData.teams) {
      constructorPoints[team.name] = 0;
    }

    // Add points from current championship standings
    List<ChampionshipStanding> driverStandings =
        ChampionshipManager.getCurrentStandings();
    for (ChampionshipStanding standing in driverStandings) {
      constructorPoints[standing.teamName] =
          (constructorPoints[standing.teamName] ?? 0) + standing.points;
    }

    return constructorPoints;
  }

  Widget _buildStandingRow(ChampionshipStanding standing, int position) {
    bool isCareerDriver = standing.isCareerDriver;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCareerDriver
            ? Colors.green[600]!.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCareerDriver
            ? Border.all(color: Colors.green[600]!, width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Position
          Container(
            width: 40,
            child: Text(
              '$position',
              style: TextStyle(
                color: _getPositionColor(position),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Formula1',
              ),
            ),
          ),
          // Driver name
          Expanded(
            flex: 3,
            child: Text(
              standing.driverName,
              style: TextStyle(
                color: isCareerDriver ? Colors.green[400] : Colors.white,
                fontSize: 14,
                fontWeight: isCareerDriver ? FontWeight.w700 : FontWeight.w400,
                fontFamily: 'Formula1',
              ),
            ),
          ),
          // Team
          Expanded(
            flex: 2,
            child: Text(
              standing.teamName,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontFamily: 'Formula1',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Points
          Container(
            width: 60,
            child: Text(
              '${standing.points}',
              style: TextStyle(
                color: isCareerDriver ? Colors.green[400] : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Formula1',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.yellow[600]!; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.orange[600]!; // Bronze
      default:
        return Colors.blue[600]!; // Regular
    }
  }

  // CONTRACT PAGE - Real Contract Data
  Widget _buildContractPage() {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCurrentContractCard(),
            SizedBox(height: 20),
            _buildTeamReputationCard(),
            SizedBox(height: 20),
            _buildContractOffersCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentContractCard() {
    Contract? contract = careerDriver!.currentContract;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: contract != null
              ? [
                  careerDriver!.team.primaryColor.withOpacity(0.15),
                  careerDriver!.team.primaryColor.withOpacity(0.05)
                ]
              : [
                  Colors.red[600]!.withOpacity(0.15),
                  Colors.red[800]!.withOpacity(0.05)
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: contract != null
              ? careerDriver!.team.primaryColor.withOpacity(0.3)
              : Colors.red[600]!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: contract != null ? Colors.green[400] : Colors.red[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'CURRENT CONTRACT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (contract != null) ...[
            _buildContractDetailRow('Team', contract.team.name),
            _buildContractDetailRow('Contract Length',
                '${contract.lengthInYears} year${contract.lengthInYears > 1 ? 's' : ''}'),
            _buildContractDetailRow('Annual Salary',
                '€${contract.salaryPerYear.toStringAsFixed(1)}M'),
            _buildContractDetailRow(
                'Total Value', '€${contract.totalValue.toStringAsFixed(1)}M'),
            _buildContractDetailRow('Status',
                contract.getContractDescription(CareerManager.currentSeason)),
            _buildContractDetailRow('Remaining Years',
                '${contract.getRemainingYears(CareerManager.currentSeason)}'),
          ] else ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[600]!.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[600]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[400], size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NO ACTIVE CONTRACT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Formula1',
                          ),
                        ),
                        Text(
                          'You need to negotiate a new contract',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
                            fontFamily: 'Formula1',
                          ),
                        ),
                      ],
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

  Widget _buildContractDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontFamily: 'Formula1',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Formula1',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamReputationCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'TEAM REPUTATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Team reputation list
          ...careerDriver!.teamReputation.entries
              .map((entry) => _buildReputationRow(entry.key, entry.value))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildReputationRow(String teamName, int reputation) {
    Color color;
    String status;

    if (reputation >= 80) {
      color = Colors.green[400]!;
      status = 'Excellent';
    } else if (reputation >= 60) {
      color = Colors.blue[400]!;
      status = 'Good';
    } else if (reputation >= 40) {
      color = Colors.orange[400]!;
      status = 'Average';
    } else {
      color = Colors.red[400]!;
      status = 'Poor';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              teamName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Formula1',
              ),
            ),
          ),
          Container(
            width: 60,
            child: Text(
              '$reputation',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Formula1',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 80,
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'Formula1',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractOffersCard() {
    // Get real contract offers (this would be implemented in CareerManager)
    List<ContractOffer> offers = []; // CareerManager.generateContractOffers();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.purple[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'CONTRACT OFFERS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (offers.isEmpty) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'No contract offers available at this time.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontFamily: 'Formula1',
                ),
              ),
            ),
          ] else ...[
            // Contract offers would be displayed here
            ...offers.map((offer) => _buildOfferCard(offer)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildOfferCard(ContractOffer offer) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: offer.team.primaryColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: offer.team.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  offer.team.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
              ),
              Text(
                '€${offer.totalValue.toStringAsFixed(1)}M Total',
                style: TextStyle(
                  color: Colors.green[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '${offer.lengthInYears} year${offer.lengthInYears > 1 ? 's' : ''} • €${offer.salaryPerYear.toStringAsFixed(1)}M/year',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontFamily: 'Formula1',
            ),
          ),
        ],
      ),
    );
  }

  // SKILLS PAGE - Real Skill Data with XP System
  Widget _buildSkillsPage() {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildXPCard(),
            SizedBox(height: 20),
            _buildSkillsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildXPCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[600]!.withOpacity(0.15),
            Colors.green[800]!.withOpacity(0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green[600]!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.green[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'EXPERIENCE POINTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available XP',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontFamily: 'Formula1',
                      ),
                    ),
                    Text(
                      '${careerDriver!.experiencePoints}',
                      style: TextStyle(
                        color: Colors.green[400],
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Career XP',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontFamily: 'Formula1',
                      ),
                    ),
                    Text(
                      '${careerDriver!.totalCareerXP}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'DRIVER SKILLS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildSkillRow('Speed', careerDriver!.speed, Icons.speed),
          _buildSkillRow(
              'Consistency', careerDriver!.consistency, Icons.track_changes),
          _buildSkillRow('Tire Management', careerDriver!.tyreManagementSkill,
              Icons.donut_small),
          _buildSkillRow(
              'Racecraft', careerDriver!.racecraft, Icons.sports_motorsports),
          _buildSkillRow('Experience', careerDriver!.experience, Icons.star),
        ],
      ),
    );
  }

  Widget _buildSkillRow(String label, int value, IconData icon) {
    int upgradeCost = careerDriver!.getUpgradeCost(value);
    bool canUpgrade = careerDriver!.canUpgradeSkill(value);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[500]!, Colors.blue[700]!],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '$value',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 80,
                height: 32,
                child: ElevatedButton(
                  onPressed: canUpgrade
                      ? () => _upgradeSkill(label.toLowerCase())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canUpgrade ? Colors.green[600] : Colors.grey[700],
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    canUpgrade ? '$upgradeCost XP' : 'MAX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Formula1',
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Skill bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _upgradeSkill(String skillName) {
    bool success = false;

    switch (skillName) {
      case 'speed':
        success = careerDriver!.upgradeSpeed();
        break;
      case 'consistency':
        success = careerDriver!.upgradeConsistency();
        break;
      case 'tire management':
        success = careerDriver!.upgradeTyreManagement();
        break;
      case 'racecraft':
        success = careerDriver!.upgradeRacecraft();
        break;
      case 'experience':
        success = careerDriver!.upgradeExperience();
        break;
    }

    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${skillName.toUpperCase()} upgraded!'),
          backgroundColor: Colors.green[600],
        ),
      );
    }
  }

  // CARS PAGE - Team Performance Data with Line Graph
  Widget _buildCarsPage() {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: [
            // Performance Chart
            _buildPerformanceChart(),
            SizedBox(height: 20),
            // Reliability List
            _buildReliabilityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    // Sort teams by performance for the chart
    List<Team> sortedTeams = List.from(TeamData.teams);
    sortedTeams.sort((a, b) => b.carPerformance.compareTo(a.carPerformance));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
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
                  'CAR PERFORMANCE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal bar chart
          Container(
            height: 350,
            padding: EdgeInsets.all(20),
            child: CustomPaint(
              size: Size.infinite,
              painter: HorizontalBarChartPainter(
                  sortedTeams, careerDriver!.team.name),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReliabilityList() {
    // Sort teams by reliability
    List<Team> sortedTeams = List.from(TeamData.teams);
    sortedTeams.sort((a, b) => b.reliability.compareTo(a.reliability));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'RELIABILITY RANKINGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Clean reliability list
          ...sortedTeams
              .asMap()
              .entries
              .map((entry) => _buildReliabilityRow(entry.value, entry.key + 1))
              .toList(),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReliabilityRow(Team team, int rank) {
    bool isCurrentTeam = team.name == careerDriver!.team.name;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentTeam
            ? team.primaryColor.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentTeam
            ? Border.all(color: team.primaryColor, width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 30,
            child: Text(
              '$rank',
              style: TextStyle(
                color: _getRankColor(rank),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Formula1',
              ),
            ),
          ),

          SizedBox(width: 16),

          // Team color indicator
          /*Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: team.primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.sports_motorsports,
              color: Colors.white,
              size: 14,
            ),
          ),

          SizedBox(width: 16),*/

          // Team name
          Expanded(
            child: Text(
              team.name,
              style: TextStyle(
                color: isCurrentTeam ? Colors.white : Colors.grey[300],
                fontSize: 14,
                fontWeight: isCurrentTeam ? FontWeight.w700 : FontWeight.w400,
                fontFamily: 'Formula1',
              ),
            ),
          ),

          // Reliability bar
          Container(
            width: 100,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: team.reliability / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: _getReliabilityColor(team.reliability),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          SizedBox(width: 12),

          // Reliability score
          Container(
            width: 40,
            child: Text(
              '${team.reliability}',
              style: TextStyle(
                color: _getReliabilityColor(team.reliability),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Formula1',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.yellow[600]!; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.orange[600]!; // Bronze
      default:
        return Colors.blue[600]!; // Regular
    }
  }

  Color _getReliabilityColor(int reliability) {
    if (reliability >= 90) return Colors.green[400]!;
    if (reliability >= 80) return Colors.blue[400]!;
    if (reliability >= 70) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  // DRIVERS PAGE - All Drivers List with Detailed Ratings (Career Driver Replaces Teammate)
  Widget _buildDriversPage() {
    List<Driver> allDrivers = _getAllDriversIncludingCareer();

    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.purple[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'ALL DRIVERS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Formula1',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Drivers list with expandable details
            ...allDrivers
                .asMap()
                .entries
                .map((entry) =>
                    _buildExpandableDriverRow(entry.value, entry.key))
                .toList(),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Get all drivers including career driver (replace one teammate)
  List<Driver> _getAllDriversIncludingCareer() {
    List<Driver> allDrivers = DriverData.createDefaultDrivers();

    // Find drivers from the same team as career driver
    List<Driver> teammateDrivers = allDrivers
        .where((driver) => driver.team.name == careerDriver!.team.name)
        .toList();

    if (teammateDrivers.isNotEmpty) {
      // Remove the first teammate to make room for career driver
      Driver driverToReplace = teammateDrivers.first;
      allDrivers.removeWhere((driver) => driver.name == driverToReplace.name);

      // Add career driver
      allDrivers.add(careerDriver!);
    }

    // Sort by car performance (highest to lowest)
    allDrivers
        .sort((a, b) => b.team.carPerformance.compareTo(a.team.carPerformance));

    return allDrivers;
  }

  Widget _buildExpandableDriverRow(Driver driver, int index) {
    bool isCareerDriver = driver.name == careerDriver!.name;
    bool isExpanded = selectedDriverIndex == index;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isCareerDriver
            ? Colors.green[600]!.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCareerDriver
            ? Border.all(color: Colors.green[600]!, width: 1)
            : null,
      ),
      child: Column(
        children: [
          // Main driver row (clickable)
          GestureDetector(
            onTap: () {
              setState(() {
                selectedDriverIndex = isExpanded ? null : index;
              });
            },
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Driver abbreviation
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: driver.team.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        driver.abbreviation,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
                          driver.name,
                          style: TextStyle(
                            color: isCareerDriver
                                ? Colors.green[400]
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: isCareerDriver
                                ? FontWeight.w700
                                : FontWeight.w400,
                            fontFamily: 'Formula1',
                          ),
                        ),
                        Text(
                          driver.team.name,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontFamily: 'Formula1',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Driver rating
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDriverRatingColor(driver).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _getDriverRatingColor(driver), width: 1),
                    ),
                    child: Text(
                      '${((driver.speed + driver.consistency + driver.tyreManagementSkill + driver.racecraft + driver.experience) / 5).round()}',
                      style: TextStyle(
                        color: _getDriverRatingColor(driver),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                      ),
                    ),
                  ),

                  SizedBox(width: 8),

                  // Expand/collapse icon
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          if (isExpanded) _buildDriverDetails(driver),
        ],
      ),
    );
  }

  Widget _buildDriverDetails(Driver driver) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DETAILED RATINGS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Formula1',
              letterSpacing: 1,
            ),
          ),

          SizedBox(height: 12),

          // All detailed ratings
          _buildDetailedRatingRow('Speed', driver.speed, Icons.speed),
          _buildDetailedRatingRow(
              'Consistency', driver.consistency, Icons.track_changes),
          _buildDetailedRatingRow(
              'Tire Management', driver.tyreManagementSkill, Icons.donut_small),
          _buildDetailedRatingRow(
              'Racecraft', driver.racecraft, Icons.sports_motorsports),
          _buildDetailedRatingRow('Experience', driver.experience, Icons.star),

          SizedBox(height: 8),

          // Overall rating
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getDriverRatingColor(driver).withOpacity(0.2),
                  _getDriverRatingColor(driver).withOpacity(0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _getDriverRatingColor(driver).withOpacity(0.3),
                  width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'OVERALL RATING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
                Text(
                  '${((driver.speed + driver.consistency + driver.tyreManagementSkill + driver.racecraft + driver.experience) / 5).toStringAsFixed(1)}',
                  style: TextStyle(
                    color: _getDriverRatingColor(driver),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedRatingRow(String label, int value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontFamily: 'Formula1',
              ),
            ),
          ),
          // Rating bar
          Container(
            width: 80,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: _getRatingColor(value),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            width: 30,
            child: Text(
              '$value',
              style: TextStyle(
                color: _getRatingColor(value),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Formula1',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 90) return Colors.green[400]!;
    if (rating >= 80) return Colors.blue[400]!;
    if (rating >= 70) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  Color _getDriverRatingColor(Driver driver) {
    double rating = (driver.speed +
            driver.consistency +
            driver.tyreManagementSkill +
            driver.racecraft +
            driver.experience) /
        5;
    if (rating >= 90) return Colors.green[400]!;
    if (rating >= 80) return Colors.blue[400]!;
    if (rating >= 70) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Container(
        height: 80,
        child: Row(
          children: [
            _buildNavItem(0, Icons.home, 'Home'),
            _buildNavItem(1, Icons.emoji_events, 'Standings'),
            _buildNavItem(2, Icons.description, 'Contract'),
            _buildNavItem(3, Icons.trending_up, 'Skills'),
            _buildNavItem(4, Icons.directions_car, 'Cars'),
            _buildNavItem(5, Icons.people, 'Drivers'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = selectedNavIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedNavIndex = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.red[600]!.withOpacity(0.2)
                : Colors.transparent,
            border: isSelected
                ? Border(
                    top: BorderSide(color: Colors.red[600]!, width: 2),
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.red[400] : Colors.grey[500],
                size: 24,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.red[400] : Colors.grey[500],
                  fontSize: 8,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  fontFamily: 'Formula1',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveCareer() async {
    // Show save options dialog instead of dropdown
    String? action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Save Career',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'How would you like to save your career?',
          style: TextStyle(
            color: Colors.grey[300],
            fontFamily: 'Formula1',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('quick_save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[600],
              foregroundColor: Colors.black,
            ),
            child: Text('Quick Save'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('save_to_slot'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Save to Slot'),
          ),
        ],
      ),
    );

    if (action != null) {
      switch (action) {
        case 'quick_save':
          _performQuickSave();
          break;
        case 'save_to_slot':
          _openSaveMenu();
          break;
      }
    }
  }

// ADD this new method for quick saving:
  void _performQuickSave() async {
    try {
      // Show saving indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Saving career...',
                style: TextStyle(
                  fontFamily: 'Formula1',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue[600],
          duration: Duration(seconds: 2),
        ),
      );

      bool success = await SaveManager.saveCurrentCareer();

      // Remove the saving indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Career saved successfully!',
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
      } else {
        _showSaveError('Failed to save career progress');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSaveError('Error saving career: $e');
    }
  }

// ADD this new method for opening save menu:
  void _openSaveMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaveLoadMenu(isLoadMode: false),
      ),
    );
  }

// ADD this new method for showing save errors:
  void _showSaveError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'Formula1',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

// Custom painter for horizontal bar chart
class HorizontalBarChartPainter extends CustomPainter {
  final List<Team> teams;
  final String currentTeamName;

  HorizontalBarChartPainter(this.teams, this.currentTeamName);

  @override
  void paint(Canvas canvas, Size size) {
    final double barHeight =
        10; // ADJUST INI UNTUK KECILKAN BAR (default was 25)
    final double spacing = 20; // BOLEH ADJUST SPACING JUGA (default was 10)
    final double totalHeight = (barHeight + spacing) * teams.length;
    final double startY = (size.height - totalHeight) / 2;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    // Find max performance for scaling
    final double maxPerformance = teams
        .map((t) => t.carPerformance)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final double chartWidth = size.width * 0.6; // Leave space for labels
    final double labelWidth = size.width * 0.3;

    for (int i = 0; i < teams.length; i++) {
      final team = teams[i];
      final double y = startY + i * (barHeight + spacing);
      final bool isCurrentTeam = team.name == currentTeamName;

      // Draw team name
      textPainter.text = TextSpan(
        text: team.name,
        style: TextStyle(
          color: isCurrentTeam ? Colors.white : Colors.grey[300],
          fontSize: 12,
          fontWeight: isCurrentTeam ? FontWeight.w700 : FontWeight.w400,
          fontFamily: 'Formula1',
        ),
      );
      textPainter.layout(maxWidth: labelWidth);
      textPainter.paint(
          canvas, Offset(10, y + (barHeight - textPainter.height) / 2));

      // Calculate bar width based on performance
      final double barWidth =
          (team.carPerformance / maxPerformance) * chartWidth;
      final double barStartX = labelWidth + 20;

      // Draw background bar
      final backgroundBarPaint = Paint()
        ..color = Colors.grey[800]!
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barStartX, y, chartWidth, barHeight),
          Radius.circular(barHeight / 2),
        ),
        backgroundBarPaint,
      );

      // Draw performance bar
      final barPaint = Paint()
        ..color = team.primaryColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barStartX, y, barWidth, barHeight),
          Radius.circular(barHeight / 2),
        ),
        barPaint,
      );

      // Draw performance value at the end of bar
      textPainter.text = TextSpan(
        text: '${team.carPerformance}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'Formula1',
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(barStartX + barWidth + 8,
              y + (barHeight - textPainter.height) / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
