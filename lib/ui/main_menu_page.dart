// lib/ui/main_menu_page.dart - Complete Main Menu with Save Slot Management
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_formula/services/career/career_manager.dart';
import 'package:real_formula/services/career/save_manager.dart';

class MainMenuPage extends StatefulWidget {
  @override
  _MainMenuPageState createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _buttonController;
  late AnimationController _backgroundController;
  late AnimationController _gridController;

  late Animation<double> _logoAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _backgroundShift;
  late Animation<double> _gridAnimation;

  // Save detection variables
  bool _hasSavedCareer = false;
  Map<String, dynamic>? _saveInfo;
  bool _isLoadingSaveInfo = true;

  @override
  void initState() {
    super.initState();

    // Logo entrance animation
    _logoController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Button slide-in animation
    _buttonController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOutCubic,
    ));

    // Subtle background animation
    _backgroundController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat();
    _backgroundShift = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundController);

    // Grid pattern animation
    _gridController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    _gridAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gridController,
      curve: Curves.easeInOut,
    ));

    // Check for saved careers on startup
    _checkForSavedCareer();

    // Start animations sequence
    _logoController.forward();
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) _buttonController.forward();
    });
    Future.delayed(Duration(milliseconds: 1200), () {
      if (mounted) _gridController.forward();
    });
  }

  // Check if there's a saved career
  Future<void> _checkForSavedCareer() async {
    try {
      bool hasSaved = await SaveManager.hasSavedCareer();
      Map<String, dynamic>? saveInfo = await SaveManager.getCareerSaveInfo();

      if (mounted) {
        setState(() {
          _hasSavedCareer = hasSaved;
          _saveInfo = saveInfo;
          _isLoadingSaveInfo = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking for saved career: $e');
      if (mounted) {
        setState(() {
          _hasSavedCareer = false;
          _isLoadingSaveInfo = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _buttonController.dispose();
    _backgroundController.dispose();
    _gridController.dispose();
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
              Color(0xFF1A1A2E), // Deep navy
              Color(0xFF16213E), // Rich midnight blue
              Color(0xFF0F3460), // F1 inspired dark blue
              Color(0xFF0A1128), // Almost black
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            _buildAnimatedBackground(),

            // Racing grid pattern overlay
            _buildGridPattern(),

            // Main content
            SafeArea(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundShift,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: F1BackgroundPainter(_backgroundShift.value),
          ),
        );
      },
    );
  }

  Widget _buildGridPattern() {
    return AnimatedBuilder(
      animation: _gridAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _gridAnimation.value * 0.15,
          child: Container(),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Header with racing elements
        _buildHeader(),

        // Logo section
        Expanded(
          child: _buildLogoSection(),
        ),

        // Buttons section
        Expanded(
          child: _buildButtonsSection(),
        ),

        // Footer
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Racing stripes indicator
          Container(
            width: 4,
            height: 40,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FORMULA 1',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Formula1',
                  letterSpacing: 2,
                ),
              ),
              Text(
                'CAREER MODE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Spacer(),
          // Season indicator (if career exists)
          if (CareerManager.currentCareerDriver != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red[600]?.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[600]!, width: 1),
              ),
              child: Text(
                'SEASON 2025',
                style: TextStyle(
                  color: Colors.red[300],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoAnimation.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main logo container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.red[400]!,
                      Colors.red[600]!,
                      Colors.red[800]!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red[600]!.withOpacity(0.4),
                      spreadRadius: 8,
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Motorsport icon
                    Icon(
                      Icons.sports_motorsports,
                      size: 50,
                      color: Colors.white,
                    ),
                    // Racing stripes
                    Positioned(
                      top: 20,
                      child: Container(
                        width: 80,
                        height: 2,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      child: Container(
                        width: 80,
                        height: 2,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Title
              Text(
                'F1 CAREER',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Formula1',
                  color: Colors.white,
                  letterSpacing: 6,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 4),
                      blurRadius: 8,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),

              Text(
                'SIMULATOR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Formula1',
                  color: Colors.grey[400],
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButtonsSection() {
    return AnimatedBuilder(
      animation: _buttonAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _buttonAnimation.value)),
          child: Opacity(
            opacity: _buttonAnimation.value,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Continue Career button (if save exists)
                  if (_isLoadingSaveInfo)
                    _buildEnhancedButton(
                      label: 'CHECKING SAVES...',
                      subtitle: 'Please wait',
                      icon: Icons.hourglass_empty,
                      onPressed: null,
                      isPrimary: false,
                      gradientColors: [Colors.grey[700]!, Colors.grey[800]!],
                      isEnabled: false,
                    )
                  else if (_hasSavedCareer)
                    _buildEnhancedButton(
                      label: 'CONTINUE CAREER',
                      subtitle: _saveInfo != null
                          ? '${_saveInfo!['driverName']} - ${_saveInfo!['teamName']}'
                          : 'Resume your championship',
                      icon: Icons.play_arrow,
                      onPressed: _handleContinueCareer,
                      isPrimary: true,
                      gradientColors: [Colors.blue[600]!, Colors.blue[800]!],
                      isEnabled: true,
                    ),

                  if (_hasSavedCareer) SizedBox(height: 20),

                  // Start/New Career button
                  _buildEnhancedButton(
                    label: _hasSavedCareer ? 'NEW CAREER' : 'START CAREER',
                    subtitle: _hasSavedCareer ? 'Begin a fresh journey' : 'Begin your F1 journey',
                    icon: Icons.flag,
                    onPressed: _handleNewCareer, // 🔧 FIXED: Always create new career
                    isPrimary: !_hasSavedCareer,
                    gradientColors: [Colors.red[500]!, Colors.red[700]!],
                    isEnabled: true,
                  ),

                  SizedBox(height: 20),

                  // Slot Manager button
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _showSaveSlotDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[600]!, Colors.orange[800]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange[600]!.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Racing stripe accent
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
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
                                    Icons.folder,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'MANAGE SAVE SLOTS',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                      fontFamily: 'Formula1',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isPrimary,
    required List<Color> gradientColors,
    bool isEnabled = true,
  }) {
    return Container(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: gradientColors[1].withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                // Racing stripe accent
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isEnabled ? 0.3 : 0.1),
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
                        icon,
                        size: 28,
                        color: isEnabled ? Colors.white : Colors.white.withOpacity(0.6),
                      ),
                      SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isEnabled ? Colors.white : Colors.white.withOpacity(0.6),
                              letterSpacing: 1.2,
                              fontFamily: 'Formula1',
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isEnabled ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.4),
                              fontWeight: FontWeight.w300,
                              fontFamily: 'Formula1',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Disabled overlay
                if (!isEnabled)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.lock_outline,
                          color: Colors.white.withOpacity(0.3),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 1,
                color: Colors.grey[600],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Build your F1 legend',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Formula1',
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 1,
                color: Colors.grey[600],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Handle continuing existing career
  void _handleContinueCareer() async {
    try {
      bool success = await SaveManager.loadCurrentCareer();
      if (success && mounted) {
        Navigator.pushNamed(context, '/career_home');
      } else if (mounted) {
        _showErrorDialog('Failed to load saved career. The save file may be corrupted.');
      }
    } catch (e) {
      debugPrint('Error loading career: $e');
      if (mounted) {
        _showErrorDialog('Error loading career: $e');
      }
    }
  }

  // Handle starting new career (always goes to driver creation)
  void _handleNewCareer() {
    // Always go to driver creation, regardless of existing careers
    Navigator.pushNamed(context, '/driver_creation');
  }

  // Handle continuing existing career
  void _handleCareerMode() {
    if (CareerManager.currentCareerDriver != null) {
      Navigator.pushNamed(context, '/career_home');
    } else {
      Navigator.pushNamed(context, '/driver_creation');
    }
  }

  // Show save slot management dialog
  void _showSaveSlotDialog() async {
    try {
      List<Map<String, dynamic>> slots = await SaveManager.getCareerSlots();
      Map<String, dynamic>? currentSave = await SaveManager.getCareerSaveInfo();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A1A2E),
                    Color(0xFF16213E),
                    Color(0xFF0F3460),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red[600]!.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red[600]!.withOpacity(0.2),
                    spreadRadius: 4,
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red[600]!, Colors.red[800]!],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.save, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'SAVE SLOT MANAGER',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Formula1',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Slot List
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        // 🆕 Current Save (Main Save)
                        if (currentSave != null) ...[
                          _buildMainSaveCard(currentSave),
                          SizedBox(height: 8),
                          Divider(color: Colors.grey[600], thickness: 1),
                          SizedBox(height: 8),
                        ],

                        // Regular Slots
                        ...List.generate(SaveManager.maxCareerSlots, (index) {
                          bool hasData = index < slots.length && slots[index].isNotEmpty;
                          Map<String, dynamic>? slotData = hasData ? slots[index] : null;

                          return Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: _buildSlotCard(index, slotData, hasData),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Footer
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Manage your F1 career saves',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontFamily: 'Formula1',
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      _showErrorDialog('Error loading save slots: $e');
    }
  }

  // Build main save card (current career)
  Widget _buildMainSaveCard(Map<String, dynamic> saveInfo) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[900]!.withOpacity(0.4), Colors.green[700]!.withOpacity(0.4)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green[600]!.withOpacity(0.6),
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔧 FIXED: Same layout as slot cards - Top row with indicator and info
            Row(
              children: [
                // Main save indicator (same style as slot number)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // Save info (same style as slot cards)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'CURRENT CAREER',
                            style: TextStyle(
                              color: Colors.green[400],
                              fontFamily: 'Formula1',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Formula1',
                                fontWeight: FontWeight.w700,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${saveInfo['driverName']} - ${saveInfo['teamName']}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontFamily: 'Formula1',
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Season ${saveInfo['currentSeason']} | Wins: ${saveInfo['careerWins']} | Points: ${saveInfo['careerPoints']}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontFamily: 'Formula1',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 🔧 FIXED: Action buttons below content (same as slot cards)
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Copy to slot button
                Expanded(
                  child: _buildSlotActionButton(
                    icon: Icons.content_copy,
                    color: Colors.blue[600]!,
                    onPressed: () => _copyMainSaveToSlot(),
                    label: 'COPY', // 🔧 CHANGED: Shortened from "COPY TO SLOT"
                  ),
                ),
                SizedBox(width: 12),
                // Delete main save button
                Expanded(
                  child: _buildSlotActionButton(
                    icon: Icons.delete,
                    color: Colors.red[600]!,
                    onPressed: () => _deleteMainSave(),
                    label: 'DELETE',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotCard(int index, Map<String, dynamic>? slotData, bool hasData) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasData
              ? [Colors.blue[900]!.withOpacity(0.3), Colors.blue[700]!.withOpacity(0.3)]
              : [Colors.grey[900]!.withOpacity(0.3), Colors.grey[800]!.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasData ? Colors.blue[600]!.withOpacity(0.5) : Colors.grey[600]!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Slot number indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasData ? Colors.blue[600] : Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Formula1',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // Slot info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasData ? (slotData!['slotName'] ?? 'Career ${index + 1}') : 'Empty Slot',
                        style: TextStyle(
                          color: hasData ? Colors.white : Colors.grey[500],
                          fontFamily: 'Formula1',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (hasData) ...[
                        SizedBox(height: 4),
                        Text(
                          '${slotData!['careerDriver']['name']} - ${slotData['careerDriver']['teamName']}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontFamily: 'Formula1',
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Wins: ${slotData['careerDriver']['careerWins'] ?? 0} | Points: ${slotData['careerDriver']['careerPoints'] ?? 0}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontFamily: 'Formula1',
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (hasData) ...[
                  // Load button
                  Expanded(
                    child: _buildSlotActionButton(
                      icon: Icons.play_arrow,
                      color: Colors.green[600]!,
                      onPressed: () => _loadFromSlot(index),
                      label: 'LOAD',
                    ),
                  ),
                  SizedBox(width: 12),
                  // Delete button
                  Expanded(
                    child: _buildSlotActionButton(
                      icon: Icons.delete,
                      color: Colors.red[600]!,
                      onPressed: () => _deleteSlot(index),
                      label: 'DELETE',
                    ),
                  ),
                ] else ...[
                  // Save to slot button (only if current career exists)
                  if (CareerManager.currentCareerDriver != null)
                    Expanded(
                      child: _buildSlotActionButton(
                        icon: Icons.save,
                        color: Colors.blue[600]!,
                        onPressed: () => _saveToSlot(index),
                        label: 'COPY',
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build action button for slots with labels
  Widget _buildSlotActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String label,
  }) {
    return Container(
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Formula1',
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Load career from specific slot
  void _loadFromSlot(int slotIndex) async {
    Navigator.pop(context); // Close slot dialog
    _showLoadingDialog('Loading Slot ${slotIndex + 1}...');

    try {
      bool success = await SaveManager.loadCareerFromSlot(slotIndex);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          // Refresh save info
          await _checkForSavedCareer();

          // Navigate to career home
          Navigator.pushNamed(context, '/career_home');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Career loaded from Slot ${slotIndex + 1}!',
                    style: TextStyle(fontFamily: 'Formula1'),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        } else {
          _showErrorDialog('Failed to load career from Slot ${slotIndex + 1}');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Error loading from slot: $e');
      }
    }
  }

  // Save current career to specific slot
  void _saveToSlot(int slotIndex) async {
    Navigator.pop(context); // Close slot dialog

    // Show name input dialog
    String? slotName = await _showSlotNameDialog(slotIndex);
    if (slotName == null || slotName.isEmpty) return;

    _showLoadingDialog('Saving to Slot ${slotIndex + 1}...');

    try {
      bool success = await SaveManager.saveCareerToSlot(slotIndex, slotName);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.save, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Career saved to Slot ${slotIndex + 1}!',
                    style: TextStyle(fontFamily: 'Formula1'),
                  ),
                ],
              ),
              backgroundColor: Colors.blue[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        } else {
          _showErrorDialog('Failed to save to Slot ${slotIndex + 1}');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Error saving to slot: $e');
      }
    }
  }

  // Copy main save to a slot
  void _copyMainSaveToSlot() async {
    Navigator.pop(context); // Close slot dialog

    // Show slot selection dialog
    int? selectedSlot = await _showSlotSelectionDialog();
    if (selectedSlot == null) return;

    // Get slot name
    String? slotName = await _showSlotNameDialog(selectedSlot);
    if (slotName == null || slotName.isEmpty) return;

    _showLoadingDialog('Copying to Slot ${selectedSlot + 1}...');

    try {
      bool success = await SaveManager.saveCareerToSlot(selectedSlot, slotName);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.content_copy, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Career copied to Slot ${selectedSlot + 1}!',
                    style: TextStyle(fontFamily: 'Formula1'),
                  ),
                ],
              ),
              backgroundColor: Colors.blue[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        } else {
          _showErrorDialog('Failed to copy to Slot ${selectedSlot + 1}');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Error copying to slot: $e');
      }
    }
  }

  // Delete main save
  void _deleteMainSave() async {
    Navigator.pop(context); // Close slot dialog

    // Show confirmation dialog
    bool? confirmed = await _showDeleteMainSaveConfirmDialog();
    if (confirmed != true) return;

    _showLoadingDialog('Deleting main save...');

    try {
      await SaveManager.clearAllSaveData();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Update UI state
        setState(() {
          _hasSavedCareer = false;
          _saveInfo = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Main career deleted!',
                  style: TextStyle(fontFamily: 'Formula1'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Error deleting main save: $e');
      }
    }
  }

  // Show slot selection dialog
  Future<int?> _showSlotSelectionDialog() async {
    List<Map<String, dynamic>> slots = await SaveManager.getCareerSlots();

    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Select Slot',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Formula1',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(SaveManager.maxCareerSlots, (index) {
                bool hasData = index < slots.length && slots[index].isNotEmpty;
                return ListTile(
                  leading: Icon(
                    hasData ? Icons.warning : Icons.save,
                    color: hasData ? Colors.orange[400] : Colors.blue[400],
                  ),
                  title: Text(
                    'Slot ${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Formula1',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    hasData ? 'Will overwrite existing save' : 'Empty slot',
                    style: TextStyle(
                      color: hasData ? Colors.orange[400] : Colors.grey[400],
                      fontFamily: 'Formula1',
                      fontSize: 10,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, index),
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Formula1',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show delete main save confirmation dialog
  Future<bool?> _showDeleteMainSaveConfirmDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Delete Main Career?',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Formula1',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will delete your current active career and all progress.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Formula1',
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[900]!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[600]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[400], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Make sure to copy to a slot first if you want to keep this career!',
                        style: TextStyle(
                          color: Colors.orange[400],
                          fontFamily: 'Formula1',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Formula1',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: Text(
                'DELETE',
                style: TextStyle(
                  fontFamily: 'Formula1',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteSlot(int slotIndex) async {
    Navigator.pop(context); // Close slot dialog

    // Show confirmation dialog
    bool? confirmed = await _showDeleteConfirmDialog(slotIndex);
    if (confirmed != true) return;

    _showLoadingDialog('Deleting Slot ${slotIndex + 1}...');

    try {
      bool success = await SaveManager.deleteCareerSlot(slotIndex);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.delete, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Slot ${slotIndex + 1} deleted!',
                    style: TextStyle(fontFamily: 'Formula1'),
                  ),
                ],
              ),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        } else {
          _showErrorDialog('Failed to delete Slot ${slotIndex + 1}');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Error deleting slot: $e');
      }
    }
  }

  // Show slot name input dialog
  Future<String?> _showSlotNameDialog(int slotIndex) async {
    TextEditingController controller = TextEditingController();
    controller.text = 'Career ${slotIndex + 1}';

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Name Your Save',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Formula1',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter a name for Slot ${slotIndex + 1}:',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Formula1',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: controller,
                style: TextStyle(color: Colors.white, fontFamily: 'Formula1'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Career Name',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                ),
                maxLength: 20,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Formula1',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: Text(
                'SAVE',
                style: TextStyle(
                  fontFamily: 'Formula1',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show delete confirmation dialog
  Future<bool?> _showDeleteConfirmDialog(int slotIndex) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Delete Slot ${slotIndex + 1}?',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Formula1',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This action cannot be undone. Your career progress in this slot will be permanently lost.',
            style: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'Formula1',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Formula1',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: Text(
                'DELETE',
                style: TextStyle(
                  fontFamily: 'Formula1',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Loading dialog
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.red[600]),
              SizedBox(width: 20),
              Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Formula1',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Error',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Formula1',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'Formula1',
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Formula1',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Custom painter for animated F1-themed background elements
class F1BackgroundPainter extends CustomPainter {
  final double animationValue;

  F1BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;

    // Draw subtle racing lines that move across the screen
    for (int i = 0; i < 5; i++) {
      final double yPos = (size.height / 6) * (i + 1);
      final double xOffset = (animationValue * size.width * 2) - size.width;

      canvas.drawLine(
        Offset(xOffset + (i * 50), yPos),
        Offset(xOffset + (i * 50) + 100, yPos),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
