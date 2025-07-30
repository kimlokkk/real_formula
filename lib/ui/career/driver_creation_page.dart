// lib/ui/career/driver_creation_page.dart - Enhanced F1 Theme
import 'package:flutter/material.dart';
import 'package:real_formula/services/career/career_manager.dart';
import '../../models/team.dart';
import '../../models/career/career_driver.dart';
import '../../data/team_data.dart';

class DriverCreationPage extends StatefulWidget {
  @override
  _DriverCreationPageState createState() => _DriverCreationPageState();
}

class _DriverCreationPageState extends State<DriverCreationPage> with TickerProviderStateMixin {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _abbreviationController = TextEditingController();

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

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
    _initializeAnimations();
    _initializeAvailableTeams();

    // Add listeners for validation
    _nameController.addListener(_validateForm);
    _abbreviationController.addListener(_validateForm);

    // Start animations
    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);
  }

  void _initializeAvailableTeams() {
    // Only show lower-tier teams for rookies
    availableTeams = TeamData.teams
        .where((team) => team.carPerformance <= 85) // Exclude top teams for rookies
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
    _slideController.dispose();
    _fadeController.dispose();
    _nameController.dispose();
    _abbreviationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
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
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
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

          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DRIVER CREATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Create your F1 legend',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Formula1',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red[600]!.withOpacity(0.1),
            Colors.red[800]!.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red[600]!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Driver icon with racing theme
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.red[400]!,
                  Colors.red[600]!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red[600]!.withOpacity(0.3),
                  spreadRadius: 4,
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(
              Icons.person_add,
              size: 40,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 16),

          Text(
            'CREATE YOUR DRIVER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'Formula1',
              letterSpacing: 2,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'Start your journey to F1 glory',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Formula1',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                'DRIVER INFORMATION',
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

          // Driver name field
          _buildEnhancedTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'e.g., Lewis Hamilton',
            isValid: _nameValid,
            icon: Icons.person,
            validationText: 'Minimum 2 characters',
          ),

          SizedBox(height: 16),

          // Abbreviation field
          _buildEnhancedTextField(
            controller: _abbreviationController,
            label: 'Driver Abbreviation',
            hint: 'e.g., HAM',
            isValid: _abbreviationValid,
            icon: Icons.badge,
            validationText: 'Exactly 3 characters',
            maxLength: 3,
            textCapitalization: TextCapitalization.characters,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isValid,
    required IconData icon,
    required String validationText,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Formula1',
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isValid ? Colors.green[400]! : Colors.grey[600]!,
              width: 2,
            ),
          ),
          child: TextField(
            cursorColor: Colors.white,
            controller: controller,
            textCapitalization: textCapitalization,
            maxLength: maxLength,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontFamily: 'Formula1',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontFamily: 'Formula1',
              ),
              prefixIcon: Icon(
                icon,
                color: isValid ? Colors.green[400] : Colors.grey[500],
              ),
              suffixIcon: isValid ? Icon(Icons.check_circle, color: Colors.green[400]) : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              counterText: '',
            ),
          ),
        ),
        if (!isValid && controller.text.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 4, left: 8),
            child: Text(
              validationText,
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 12,
                fontFamily: 'Formula1',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSkillDistributionSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                    'SKILL DISTRIBUTION',
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _remainingSkillPoints > 0
                        ? [Colors.orange[500]!, Colors.orange[700]!]
                        : [Colors.green[500]!, Colors.green[700]!],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '$_remainingSkillPoints/$maxSkillPoints',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 0.5,
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
              fontFamily: 'Formula1',
            ),
          ),

          SizedBox(height: 20),

          // Skill sliders
          _buildSkillSlider('Speed', 'speed', 'Qualifying pace and overtaking ability', Icons.speed),
          _buildSkillSlider('Consistency', 'consistency', 'Mistake avoidance and reliability', Icons.track_changes),
          _buildSkillSlider('Tire Management', 'tyreManagement', 'Tire conservation and strategy', Icons.donut_small),
          _buildSkillSlider('Racecraft', 'racecraft', 'Wheel-to-wheel racing and defense', Icons.sports_motorsports),
          _buildSkillSlider('Experience', 'experience', 'Pressure handling and racecraft', Icons.star),
        ],
      ),
    );
  }

  Widget _buildSkillSlider(String label, String key, String description, IconData icon) {
    int currentValue = skillPoints[key]!;
    int finalValue = 70 + currentValue;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                        fontFamily: 'Formula1',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[500]!, Colors.red[700]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$finalValue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.red[400],
              inactiveTrackColor: Colors.grey[700],
              thumbColor: Colors.red[500],
              overlayColor: Colors.red[500]!.withOpacity(0.2),
              trackHeight: 8,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: currentValue.toDouble(),
              min: 0,
              max: 20,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  int newValue = value.round();
                  int difference = newValue - currentValue;

                  if (_remainingSkillPoints >= difference) {
                    skillPoints[key] = newValue;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelectionSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                'TEAM SELECTION',
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

          SizedBox(height: 8),

          Text(
            'Choose your starting team (rookie-friendly teams only)',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontFamily: 'Formula1',
            ),
          ),

          SizedBox(height: 16),

          // Team selection grid
          ...availableTeams.map((team) => _buildTeamCard(team)).toList(),
        ],
      ),
    );
  }

  Widget _buildTeamCard(Team team) {
    bool isSelected = selectedTeam == team;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedTeam = team;
              _teamSelected = true;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [team.primaryColor.withOpacity(0.3), team.primaryColor.withOpacity(0.1)],
                    )
                  : null,
              color: isSelected ? null : Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? team.primaryColor : Colors.grey[600]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Team color indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: team.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.sports_motorsports,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Formula1',
                        ),
                      ),
                      Text(
                        'Performance: ${team.carPerformance}/100',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontFamily: 'Formula1',
                        ),
                      ),
                    ],
                  ),
                ),

                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: team.primaryColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    if (!_formValid) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[600]!.withOpacity(0.1),
            Colors.green[800]!.withOpacity(0.05),
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
                'DRIVER SUMMARY',
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
          _buildSummaryRow('Driver Name', _nameController.text),
          _buildSummaryRow('Abbreviation', _abbreviationController.text.toUpperCase()),
          _buildSummaryRow('Starting Team', selectedTeam!.name),
          SizedBox(height: 12),
          Text(
            'Final Driver Stats:',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Formula1',
            ),
          ),
          SizedBox(height: 8),
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
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontFamily: 'Formula1',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Formula1',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateDriverButton() {
    bool canCreate = _formValid && _remainingSkillPoints == 0;

    return Container(
      margin: EdgeInsets.all(20),
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: canCreate ? _createDriver : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: canCreate
                ? LinearGradient(
                    colors: [Colors.green[500]!, Colors.green[700]!],
                  )
                : LinearGradient(
                    colors: [Colors.grey[700]!, Colors.grey[800]!],
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: canCreate
                ? [
                    BoxShadow(
                      color: Colors.green[600]!.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              // Racing stripe
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(canCreate ? 0.3 : 0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),

              // Button content
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flag,
                      size: 24,
                      color: canCreate ? Colors.white : Colors.white.withOpacity(0.5),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'START CAREER',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Formula1',
                        color: canCreate ? Colors.white : Colors.white.withOpacity(0.5),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
