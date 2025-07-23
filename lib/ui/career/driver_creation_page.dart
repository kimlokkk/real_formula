// lib/ui/career/driver_creation_page.dart
import 'package:flutter/material.dart';
import 'package:real_formula/services/career/career_manager.dart';
import '../../models/team.dart';
import '../../models/career/career_driver.dart';
import '../../data/team_data.dart';

class DriverCreationPage extends StatefulWidget {
  @override
  _DriverCreationPageState createState() => _DriverCreationPageState();
}

class _DriverCreationPageState extends State<DriverCreationPage> {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _abbreviationController = TextEditingController();

  // Skill distribution (starts at 0, base is 70)
  Map<String, int> skillPoints = {
    'speed': 0,
    'consistency': 0,
    'tyreManagement': 0,
    'racecraft': 0,
    'experience': 0,
  };

  // Team selection
  Team? selectedTeam;
  List<Team> availableTeams = [];

  // Validation
  bool _nameValid = false;
  bool _abbreviationValid = false;
  bool _teamSelected = false;

  final int maxSkillPoints = 50;

  @override
  void initState() {
    super.initState();
    _initializeAvailableTeams();

    // Add listeners for validation
    _nameController.addListener(_validateForm);
    _abbreviationController.addListener(_validateForm);
  }

  void _initializeAvailableTeams() {
    // Only show lower-tier teams for rookies
    availableTeams = TeamData.teams
        .where((team) => team.carPerformance <= 85 // Exclude top teams for rookies
            )
        .toList();

    // Sort by car performance (worst to best for rookies)
    availableTeams.sort((a, b) => a.carPerformance.compareTo(b.carPerformance));
  }

  void _validateForm() {
    setState(() {
      _nameValid = _nameController.text.trim().length >= 2;
      _abbreviationValid = _abbreviationController.text.trim().length == 3;
      _teamSelected = selectedTeam != null;
    });
  }

  bool get _formValid => _nameValid && _abbreviationValid && _teamSelected;

  int get _usedSkillPoints => skillPoints.values.fold(0, (sum, points) => sum + points);
  int get _remainingSkillPoints => maxSkillPoints - _usedSkillPoints;

  @override
  void dispose() {
    _nameController.dispose();
    _abbreviationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildDriverInfoSection(),
            _buildSkillDistributionSection(),
            _buildTeamSelectionSection(),
            _buildSummarySection(),
            _buildCreateDriverButton(),
            SizedBox(height: 20),
          ],
        ),
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
            'CREATE CAREER DRIVER',
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
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.person_add, color: Colors.orange, size: 48),
          SizedBox(height: 12),
          Text(
            'CREATE YOUR F1 DRIVER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start your journey from rookie to legend',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoSection() {
    return Container(
      margin: EdgeInsets.all(16),
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
            'DRIVER INFORMATION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 16),

          // Driver Name
          TextField(
            controller: _nameController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Driver Name',
              labelStyle: TextStyle(color: Colors.grey[400]),
              hintText: 'e.g., Alex Johnson',
              hintStyle: TextStyle(color: Colors.grey[600]),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red[600]!),
              ),
              suffixIcon: _nameValid ? Icon(Icons.check, color: Colors.green) : null,
            ),
          ),

          SizedBox(height: 16),

          // Abbreviation
          TextField(
            controller: _abbreviationController,
            style: TextStyle(color: Colors.white),
            maxLength: 3,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Abbreviation (3 letters)',
              labelStyle: TextStyle(color: Colors.grey[400]),
              hintText: 'e.g., JOH',
              hintStyle: TextStyle(color: Colors.grey[600]),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red[600]!),
              ),
              suffixIcon: _abbreviationValid ? Icon(Icons.check, color: Colors.green) : null,
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillDistributionSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SKILL DISTRIBUTION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _remainingSkillPoints > 0 ? Colors.orange[600] : Colors.green[600],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Points: $_remainingSkillPoints/$maxSkillPoints',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Base stats: 70 | Distribute 50 bonus points',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          SizedBox(height: 16),

          // Skill sliders
          _buildSkillSlider('Speed', 'speed', 'Qualifying pace and overtaking ability'),
          _buildSkillSlider('Consistency', 'consistency', 'Mistake avoidance and reliability'),
          _buildSkillSlider('Tire Management', 'tyreManagement', 'Tire conservation and strategy'),
          _buildSkillSlider('Racecraft', 'racecraft', 'Wheel-to-wheel racing and defense'),
          _buildSkillSlider('Experience', 'experience', 'Pressure handling and racecraft'),
        ],
      ),
    );
  }

  // Fixed _buildSkillSlider method for driver_creation_page.dart

  Widget _buildSkillSlider(String label, String key, String description) {
    int currentValue = skillPoints[key]!;
    int totalValue = 70 + currentValue;

    // Calculate the maximum this slider can go based on remaining points
    int maxPossibleValue = (currentValue + _remainingSkillPoints).clamp(0, 29);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$totalValue (70+$currentValue)',
                style: TextStyle(
                  color: Colors.orange[300],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              // Decrease button
              IconButton(
                onPressed: currentValue > 0 ? () => setState(() => skillPoints[key] = currentValue - 1) : null,
                icon: Icon(Icons.remove),
                color: currentValue > 0 ? Colors.red[400] : Colors.grey[600],
              ),

              // Slider
              Expanded(
                child: Slider(
                  value: currentValue.toDouble(),
                  min: 0,
                  max: 29.0, // Fixed maximum
                  divisions: 29, // Fixed divisions to avoid the assertion error
                  activeColor: Colors.red[600],
                  inactiveColor: Colors.grey[700],
                  onChanged: (value) {
                    int newValue = value.round();

                    // Calculate how many points this change would use
                    int pointsDifference = newValue - currentValue;

                    // Only allow the change if we have enough remaining points
                    if (pointsDifference <= _remainingSkillPoints) {
                      setState(() {
                        skillPoints[key] = newValue;
                      });
                    } else {
                      // If not enough points, set to the maximum possible value
                      setState(() {
                        skillPoints[key] = maxPossibleValue;
                      });
                    }
                  },
                ),
              ),

              // Increase button
              IconButton(
                onPressed: _remainingSkillPoints > 0 && currentValue < 29
                    ? () => setState(() => skillPoints[key] = currentValue + 1)
                    : null,
                icon: Icon(Icons.add),
                color: _remainingSkillPoints > 0 && currentValue < 29 ? Colors.green[400] : Colors.grey[600],
              ),
            ],
          ),

          // Add a visual indicator of the current limit
          Container(
            height: 2,
            margin: EdgeInsets.symmetric(horizontal: 40),
            child: Stack(
              children: [
                // Background bar
                Container(
                  width: double.infinity,
                  height: 2,
                  color: Colors.grey[700],
                ),
                // Current limit indicator
                FractionallySizedBox(
                  widthFactor: maxPossibleValue / 29.0,
                  child: Container(
                    height: 2,
                    color: _remainingSkillPoints > 0 ? Colors.orange[400] : Colors.green[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelectionSection() {
    return Container(
      margin: EdgeInsets.all(16),
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
            'SELECT STARTING TEAM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'As a rookie, you can only join lower-tier teams',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          SizedBox(height: 16),

          // Team selection grid
          ...availableTeams.map((team) => _buildTeamOption(team)).toList(),
        ],
      ),
    );
  }

  Widget _buildTeamOption(Team team) {
    bool isSelected = selectedTeam?.name == team.name;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTeam = team;
          _validateForm();
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? team.primaryColor.withOpacity(0.2) : Colors.grey[800],
          border: Border.all(
            color: isSelected ? team.primaryColor : Colors.grey[600]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: team.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  team.name.substring(0, 2).toUpperCase(),
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
                    team.name.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${team.performanceTier} • ${team.reliabilityTier}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'CAR: ${team.carPerformance}',
                  style: TextStyle(
                    color: Colors.orange[300],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'REL: ${team.reliability}',
                  style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              SizedBox(width: 8),
              Icon(Icons.check_circle, color: team.primaryColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[600]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DRIVER SUMMARY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 12),
          if (_nameValid) _buildSummaryRow('Name', _nameController.text),
          if (_abbreviationValid) _buildSummaryRow('Abbreviation', _abbreviationController.text.toUpperCase()),
          if (_teamSelected) _buildSummaryRow('Team', selectedTeam!.name),
          SizedBox(height: 8),
          Text('Final Stats:', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          SizedBox(height: 4),
          _buildSummaryRow('Speed', '${70 + skillPoints['speed']!}'),
          _buildSummaryRow('Consistency', '${70 + skillPoints['consistency']!}'),
          _buildSummaryRow('Tire Management', '${70 + skillPoints['tyreManagement']!}'),
          _buildSummaryRow('Racecraft', '${70 + skillPoints['racecraft']!}'),
          _buildSummaryRow('Experience', '${70 + skillPoints['experience']!}'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
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

  Widget _buildCreateDriverButton() {
    return Container(
      margin: EdgeInsets.all(16),
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _formValid && _remainingSkillPoints == 0 ? _createDriver : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _formValid && _remainingSkillPoints == 0 ? Colors.green[600] : Colors.grey[700],
          foregroundColor: Colors.white,
          elevation: _formValid && _remainingSkillPoints == 0 ? 8 : 0,
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
              'START CAREER',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createDriver() {
    // Create the career driver
    CareerDriver driver = CareerManager.startNewCareer(
      driverName: _nameController.text.trim(),
      abbreviation: _abbreviationController.text.trim().toUpperCase(),
      startingTeam: selectedTeam!,
      initialSkillDistribution: skillPoints,
    );

    // Navigate to career home
    Navigator.pushReplacementNamed(
      context,
      '/career_home',
      arguments: {'careerDriver': driver},
    );
  }
}
