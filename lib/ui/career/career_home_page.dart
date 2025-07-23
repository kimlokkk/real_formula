// lib/ui/career/career_home_page.dart
import 'package:flutter/material.dart';
import 'package:real_formula/services/career/career_calendar.dart';
import 'package:real_formula/services/career/career_manager.dart';
import 'package:real_formula/services/career/championship_manager.dart';
import 'package:real_formula/ui/career/career_calendar_widget.dart';
import '../../models/career/career_driver.dart';
import '../../models/career/contract.dart';

class CareerHomePage extends StatefulWidget {
  @override
  _CareerHomePageState createState() => _CareerHomePageState();
}

class _CareerHomePageState extends State<CareerHomePage> with TickerProviderStateMixin {
  CareerDriver? careerDriver;
  int selectedTab = 0; // 0: Overview, 1: Skills, 2: Contract, 3: Statistics
  bool dataLoaded = false; // Add this flag to prevent multiple loads
  bool showRaceWeekendAlert = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    careerDriver = CareerManager.currentCareerDriver;
    //_loadCareerData();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      CareerCalendar.instance.initialize();
    });
  }

  // 🆕 NEW: Handle page resume - refresh data when returning to this screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we're returning from a navigation and refresh data
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (careerDriver == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.red[600]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCareerHeader(),
          CareerCalendarWidget(
            onRaceWeekendReached: _onRaceWeekendReached,
          ),
          _buildChampionshipStandings(),

          // 🆕 ADD this new alert widget:
          if (showRaceWeekendAlert) _buildRaceWeekendAlert(),
          _buildTabBar(),
          Expanded(
            child: _buildTabContent(),
          ),
          _buildBottomActions(),
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
            'CAREER MODE',
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
        icon: Icon(Icons.home, color: Colors.white),
        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.save, color: Colors.white),
          onPressed: _saveCareer,
        ),
      ],
    );
  }

  Widget _buildRaceWeekendAlert() {
    final raceWeekend = CareerCalendar.instance.currentRaceWeekend;
    if (raceWeekend == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[800]!, Colors.orange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
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
                      'RACE WEEKEND',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      raceWeekend.name,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    showRaceWeekendAlert = false;
                  });
                },
                icon: Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startRaceWeekend,
                  icon: Icon(Icons.play_arrow, size: 20),
                  label: Text(
                    'START ${raceWeekend.nextSession.toUpperCase()}',
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
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  CareerCalendar.instance.resumeCalendar();
                  setState(() {
                    showRaceWeekendAlert = false;
                  });
                },
                child: Text('SKIP', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCareerHeader() {
    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Driver avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: careerDriver!.team.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    careerDriver!.abbreviation,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                      careerDriver!.name.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${careerDriver!.team.name.toUpperCase()} • Season ${CareerManager.currentSeason}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Career Rating: ${careerDriver!.careerRating.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: Colors.orange[300],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // XP indicator
              Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: careerDriver!.experiencePoints > 0 ? Colors.green[600] : Colors.grey[600],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${careerDriver!.experiencePoints} XP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Experience',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 16),

          // Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickStat('Wins', '${careerDriver!.careerWins}', Colors.yellow),
              _buildQuickStat('Podiums', '${careerDriver!.careerPodiums}', Colors.grey[300]!),
              _buildQuickStat('Points', '${careerDriver!.careerPoints}', Colors.green),
              _buildQuickStat('Seasons', '${careerDriver!.seasonsCompleted}', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    List<String> tabs = ['OVERVIEW', 'SKILLS', 'CONTRACT', 'STATS'];
    List<IconData> icons = [Icons.home, Icons.trending_up, Icons.description, Icons.analytics];

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
        return _buildOverviewTab();
      case 1:
        return _buildSkillsTab();
      case 2:
        return _buildContractTab();
      case 3:
        return _buildStatsTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Season Progress
          _buildSectionCard(
            title: 'CURRENT SEASON',
            icon: Icons.calendar_today,
            child: Column(
              children: [
                _buildOverviewRow('Season', '${CareerManager.currentSeason}'),
                _buildOverviewRow('Team', careerDriver!.team.name),
                _buildOverviewRow('Wins', '${careerDriver!.currentSeasonWins}'),
                _buildOverviewRow('Podiums', '${careerDriver!.currentSeasonPodiums}'),
                _buildOverviewRow('Points', '${careerDriver!.currentSeasonPoints}'),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Next Actions
          _buildSectionCard(
            title: 'NEXT ACTIONS',
            icon: Icons.play_arrow,
            child: Column(
              children: [
                if (careerDriver!.experiencePoints > 0) ...[
                  ListTile(
                    leading: Icon(Icons.trending_up, color: Colors.green),
                    title: Text('Upgrade Skills', style: TextStyle(color: Colors.white)),
                    subtitle: Text('${careerDriver!.experiencePoints} XP available',
                        style: TextStyle(color: Colors.grey[400])),
                    trailing: Icon(Icons.arrow_forward, color: Colors.grey[400]),
                    onTap: () => setState(() => selectedTab = 1),
                  ),
                  Divider(color: Colors.grey[700]),
                ],
                if (CareerManager.needsNewContract()) ...[
                  ListTile(
                    leading: Icon(Icons.description, color: Colors.orange),
                    title: Text('Contract Needed', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Your contract has expired', style: TextStyle(color: Colors.grey[400])),
                    trailing: Icon(Icons.arrow_forward, color: Colors.grey[400]),
                    onTap: () => setState(() => selectedTab = 2),
                  ),
                  Divider(color: Colors.grey[700]),
                ],
                ListTile(
                  leading: Icon(Icons.sports_motorsports, color: Colors.red[600]),
                  title: Text('Start Race Weekend', style: TextStyle(color: Colors.white)),
                  subtitle: Text('Begin qualifying and race', style: TextStyle(color: Colors.grey[400])),
                  trailing: Icon(Icons.arrow_forward, color: Colors.grey[400]),
                  onTap: _startRaceWeekend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // XP status
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AVAILABLE EXPERIENCE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${careerDriver!.experiencePoints} XP',
                  style: TextStyle(
                    color: Colors.green[400],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Skill upgrade cards
          _buildSkillUpgradeCard('Speed', careerDriver!.speed, Icons.speed),
          _buildSkillUpgradeCard('Consistency', careerDriver!.consistency, Icons.trending_flat),
          _buildSkillUpgradeCard('Tire Management', careerDriver!.tyreManagementSkill, Icons.settings),
          _buildSkillUpgradeCard('Racecraft', careerDriver!.racecraft, Icons.directions_car),
          _buildSkillUpgradeCard('Experience', careerDriver!.experience, Icons.school),
        ],
      ),
    );
  }

  Widget _buildSkillUpgradeCard(String skillName, int currentValue, IconData icon) {
    int upgradeCost = careerDriver!.getUpgradeCost(currentValue);
    bool canUpgrade = careerDriver!.canUpgradeSkill(currentValue);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canUpgrade ? Colors.green[600]! : Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skillName.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Current: $currentValue${currentValue >= 99 ? ' (MAX)' : ''}',
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
                currentValue >= 99 ? 'MAX' : '$upgradeCost XP',
                style: TextStyle(
                  color: currentValue >= 99 ? Colors.yellow[600] : Colors.orange[300],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              ElevatedButton(
                onPressed: canUpgrade ? () => _upgradeSkill(skillName) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canUpgrade ? Colors.green[600] : Colors.grey[700],
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size(60, 30),
                ),
                child: Text(
                  currentValue >= 99 ? 'MAX' : 'UP',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContractTab() {
    Contract? contract = careerDriver!.currentContract;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          if (contract != null) ...[
            _buildSectionCard(
              title: 'CURRENT CONTRACT',
              icon: Icons.description,
              child: Column(
                children: [
                  _buildOverviewRow('Team', contract.team.name),
                  _buildOverviewRow('Length', '${contract.lengthInYears} year${contract.lengthInYears > 1 ? 's' : ''}'),
                  _buildOverviewRow('Salary', '€${contract.salaryPerYear.toStringAsFixed(1)}M/year'),
                  _buildOverviewRow('Status', contract.getContractDescription(CareerManager.currentSeason)),
                  _buildOverviewRow('Total Value', '€${contract.totalValue.toStringAsFixed(1)}M'),
                ],
              ),
            ),
          ] else ...[
            _buildSectionCard(
              title: 'NO ACTIVE CONTRACT',
              icon: Icons.warning,
              child: Column(
                children: [
                  Text(
                    'You need a contract to continue your career!',
                    style: TextStyle(color: Colors.orange[300], fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _viewContractOffers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                    ),
                    child: Text('VIEW OFFERS'),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 16),

          // Team reputation
          _buildSectionCard(
            title: 'TEAM REPUTATION',
            icon: Icons.star,
            child: Column(
              children: careerDriver!.teamReputation.entries.map((entry) {
                return _buildReputationRow(entry.key, entry.value);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReputationRow(String teamName, int reputation) {
    Color color = Colors.grey;
    String status = 'Neutral';

    if (reputation >= 80) {
      color = Colors.green;
      status = 'Excellent';
    } else if (reputation >= 60) {
      color = Colors.blue;
      status = 'Good';
    } else if (reputation >= 40) {
      color = Colors.orange;
      status = 'Fair';
    } else if (reputation >= 20) {
      color = Colors.red;
      status = 'Poor';
    } else {
      color = Colors.red[800]!;
      status = 'Hostile';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            teamName,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          Row(
            children: [
              Text(
                '$reputation',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(color: color, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionCard(
            title: 'CAREER STATISTICS',
            icon: Icons.analytics,
            child: Column(
              children: [
                _buildOverviewRow('Total Races', '${careerDriver!.careerRaces}'),
                _buildOverviewRow('Wins', '${careerDriver!.careerWins}'),
                _buildOverviewRow('Podiums', '${careerDriver!.careerPodiums}'),
                _buildOverviewRow('Poles', '${careerDriver!.careerPoles}'),
                _buildOverviewRow('Points', '${careerDriver!.careerPoints}'),
                _buildOverviewRow('Win Rate', '${careerDriver!.winPercentage.toStringAsFixed(1)}%'),
                _buildOverviewRow('Podium Rate', '${careerDriver!.podiumPercentage.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
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
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildOverviewRow(String label, String value) {
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

  Widget _buildBottomActions() {
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
            child: ElevatedButton(
              onPressed: _startRaceWeekend,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_motorsports, size: 20),
                  SizedBox(width: 8),
                  Text('START RACE WEEKEND', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton(
            onPressed: _viewContractOffers,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              padding: EdgeInsets.all(12),
            ),
            child: Icon(Icons.description, size: 20),
          ),
        ],
      ),
    );
  }

  void _upgradeSkill(String skillName) {
    setState(() {
      switch (skillName) {
        case 'Speed':
          careerDriver!.upgradeSpeed();
          break;
        case 'Consistency':
          careerDriver!.upgradeConsistency();
          break;
        case 'Tire Management':
          careerDriver!.upgradeTyreManagement();
          break;
        case 'Racecraft':
          careerDriver!.upgradeRacecraft();
          break;
        case 'Experience':
          careerDriver!.upgradeExperience();
          break;
      }
    });

    // Show upgrade confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$skillName upgraded to ${_getCurrentSkillValue(skillName)}!'),
        backgroundColor: Colors.green[600],
        duration: Duration(seconds: 2),
      ),
    );
  }

  int _getCurrentSkillValue(String skillName) {
    switch (skillName) {
      case 'Speed':
        return careerDriver!.speed;
      case 'Consistency':
        return careerDriver!.consistency;
      case 'Tire Management':
        return careerDriver!.tyreManagementSkill;
      case 'Racecraft':
        return careerDriver!.racecraft;
      case 'Experience':
        return careerDriver!.experience;
      default:
        return 0;
    }
  }

  void _startRaceWeekend() {
    final currentRaceWeekend = CareerCalendar.instance.currentRaceWeekend;

    if (currentRaceWeekend != null && careerDriver != null) {
      // Navigate directly to loading screen, skip race setup
      Navigator.pushNamed(
        context,
        '/race_weekend_loading',
        arguments: {
          'raceWeekend': currentRaceWeekend,
          'careerDriver': careerDriver,
        },
      ).then((_) {
        // 🆕 IMPROVED: When returning from race weekend, refresh all data
        debugPrint("Returned from race weekend - refreshing data...");

        // Refresh career data
        _refreshCareerData();

        // Hide race weekend alert and refresh UI
        setState(() {
          showRaceWeekendAlert = false;
        });

        // Show completion message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Race weekend completed! Data updated.'),
            backgroundColor: Colors.green[600],
            duration: Duration(seconds: 2),
          ),
        );
      });
    } else {
      // Fallback: Show error if no race weekend or career driver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No active race weekend available'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  void _viewContractOffers() {
    // TODO: Navigate to contract offers page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contract offers system coming soon!'),
        backgroundColor: Colors.orange[600],
      ),
    );
  }

  void _saveCareer() {
    // TODO: Implement save system
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Career saved successfully!'),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  // 🆕 NEW: Refresh career data when returning from race
  // 🆕 ENHANCED: Refresh career data including championship standings
  void _refreshCareerData() {
    debugPrint("=== REFRESHING CAREER DATA ===");

    try {
      // Get updated career driver data
      CareerDriver? updatedDriver = CareerManager.currentCareerDriver;

      if (updatedDriver != null) {
        setState(() {
          careerDriver = updatedDriver;
          debugPrint(
              "Career data refreshed - Wins: ${careerDriver!.careerWins}, Points: ${careerDriver!.careerPoints}");
        });

        // Also refresh the calendar instance to get updated race data
        CareerCalendar.instance.notifyListeners();

        // 🆕 NEW: Force UI refresh to show updated championship standings
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {}); // Trigger rebuild to refresh championship standings
          }
        });

        debugPrint("✅ Career data refresh successful");
      } else {
        debugPrint("❌ No career driver found during refresh");
      }
    } catch (e) {
      debugPrint("❌ Error refreshing career data: $e");
    }
  }

  // 🆕 NEW: Build championship standings widget
  Widget _buildChampionshipStandings() {
    if (careerDriver == null) return Container();

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.yellow[600], size: 24),
              SizedBox(width: 12),
              Text(
                'CHAMPIONSHIP STANDINGS',
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
          _buildStandingsTable(),
        ],
      ),
    );
  }

// 🆕 NEW: Build the standings table
  Widget _buildStandingsTable() {
    try {
      List<ChampionshipStanding> standings = ChampionshipManager.getTop5Standings(
        careerDriverName: careerDriver?.name,
      );

      if (standings.isEmpty) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Text(
            'No championship data available',
            style: TextStyle(color: Colors.grey[400]),
          ),
        );
      }

      return Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
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
                      fontWeight: FontWeight.bold,
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
                      fontWeight: FontWeight.bold,
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  width: 50,
                  child: Text(
                    'PTS',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          // Standings rows
          ...standings.asMap().entries.map((entry) {
            int index = entry.key;
            ChampionshipStanding standing = entry.value;
            return _buildStandingRow(index + 1, standing);
          }).toList(),
        ],
      );
    } catch (e) {
      debugPrint("Error building standings table: $e");
      return Container(
        padding: EdgeInsets.all(16),
        child: Text(
          'Error loading championship standings',
          style: TextStyle(color: Colors.red[400]),
        ),
      );
    }
  }

// 🆕 NEW: Build individual standing row
  Widget _buildStandingRow(int position, ChampionshipStanding standing) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: standing.isCareerDriver ? Colors.green[900]?.withOpacity(0.3) : Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: standing.isCareerDriver ? Border.all(color: Colors.green[400]!, width: 2) : null,
      ),
      child: Row(
        children: [
          // Position
          Container(
            width: 40,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getPositionColor(position),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$position',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (standing.isCareerDriver) ...[
                  SizedBox(width: 8),
                  Icon(Icons.person, color: Colors.green[400], size: 16),
                ],
              ],
            ),
          ),
          // Driver name
          Expanded(
            flex: 3,
            child: Text(
              standing.driverName,
              style: TextStyle(
                color: standing.isCareerDriver ? Colors.green[400] : Colors.white,
                fontSize: 14,
                fontWeight: standing.isCareerDriver ? FontWeight.bold : FontWeight.normal,
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
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Points
          Container(
            width: 50,
            child: Text(
              '${standing.points}',
              style: TextStyle(
                color: standing.isCareerDriver ? Colors.green[400] : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

// 🆕 NEW: Get position color for championship standings
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
}
