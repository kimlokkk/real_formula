// lib/ui/main_menu_page.dart - Complete Main Menu with New Save System
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
          _saveInfo = null;
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
      body: AnimatedBuilder(
        animation: _backgroundShift,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft + Alignment(_backgroundShift.value * 0.3, 0),
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0A0F),
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated grid pattern
                AnimatedBuilder(
                  animation: _gridAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: GridPatternPainter(_gridAnimation.value),
                      size: Size.infinite,
                    );
                  },
                ),

                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      // Top section with logo and title
                      Expanded(
                        flex: 3,
                        child: AnimatedBuilder(
                          animation: _logoAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _logoAnimation.value,
                              child: Transform.rotate(
                                angle: (1 - _logoAnimation.value) * 0.1,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // F1 Logo/Icon
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          colors: [
                                            Colors.red[400]!,
                                            Colors.red[600]!,
                                            Colors.red[800]!,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(60),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red[600]!.withOpacity(0.4),
                                            spreadRadius: 8,
                                            blurRadius: 20,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.sports_motorsports,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ),

                                    SizedBox(height: 20),

                                    // Main title
                                    Text(
                                      'REAL FORMULA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Formula1',
                                        letterSpacing: 3,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(2, 2),
                                            blurRadius: 8,
                                            color: Colors.black.withOpacity(0.5),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 8),

                                    // Subtitle
                                    Text(
                                      'Racing Simulator',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Formula1',
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Menu buttons section
                      Expanded(
                        flex: 4,
                        child: AnimatedBuilder(
                          animation: _buttonAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 50 * (1 - _buttonAnimation.value)),
                              child: Opacity(
                                opacity: _buttonAnimation.value,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Career Mode section
                                      if (_isLoadingSaveInfo)
                                        _buildLoadingButton()
                                      else if (_hasSavedCareer)
                                        _buildContinueCareerSection()
                                      else
                                        _buildNewCareerButton(),

                                      SizedBox(height: 20),

                                      // Quick Race button
                                      _buildMenuButton(
                                        icon: Icons.flash_on,
                                        title: 'QUICK RACE',
                                        subtitle: 'Jump into action',
                                        color: Colors.orange[600]!,
                                        onPressed: () => Navigator.pushNamed(context, '/track_selection'),
                                      ),

                                      SizedBox(height: 20),

                                      // Championships button
                                      _buildMenuButton(
                                        icon: Icons.emoji_events,
                                        title: 'CHAMPIONSHIPS',
                                        subtitle: 'View standings',
                                        color: Colors.amber[600]!,
                                        onPressed: () => Navigator.pushNamed(context, '/championships'),
                                      ),

                                      SizedBox(height: 20),

                                      // Settings button
                                      _buildMenuButton(
                                        icon: Icons.settings,
                                        title: 'SETTINGS',
                                        subtitle: 'Configure game',
                                        color: Colors.grey[600]!,
                                        onPressed: () => Navigator.pushNamed(context, '/settings'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Bottom section with save management
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_hasSavedCareer) ...[
                              // Save management button
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _showSaveSlotDialog,
                                    icon: Icon(Icons.save, color: Colors.blue[400]),
                                    label: Text(
                                      'MANAGE SAVES',
                                      style: TextStyle(
                                        color: Colors.blue[400],
                                        fontFamily: 'Formula1',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.blue[400]!, width: 2),
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                            ],

                            // Version info
                            Text(
                              'Version 1.0.0',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontFamily: 'Formula1',
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Loading button while checking saves
  Widget _buildLoadingButton() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[600]!, width: 2),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Checking saves...',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontFamily: 'Formula1',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Continue career section (when save exists)
  Widget _buildContinueCareerSection() {
    return Column(
      children: [
        // Continue career button
        _buildMenuButton(
          icon: Icons.play_arrow,
          title: 'CONTINUE CAREER',
          subtitle:
              _saveInfo != null ? '${_saveInfo!['driverName']} - ${_saveInfo!['teamName']}' : 'Resume your journey',
          color: Colors.green[600]!,
          onPressed: _handleContinueCareer,
        ),

        SizedBox(height: 12),

        // New career button (smaller)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleNewCareer,
            icon: Icon(Icons.add, color: Colors.blue[400]),
            label: Text(
              'START NEW CAREER',
              style: TextStyle(
                color: Colors.blue[400],
                fontFamily: 'Formula1',
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue[400]!, width: 2),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // New career button (when no save exists)
  Widget _buildNewCareerButton() {
    return _buildMenuButton(
      icon: Icons.person_add,
      title: 'START CAREER',
      subtitle: 'Begin your F1 journey',
      color: Colors.blue[600]!,
      onPressed: _handleNewCareer,
    );
  }

  // Generic menu button builder
  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: color.withOpacity(0.4),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Formula1',
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontFamily: 'Formula1',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Load existing career
  void _loadExistingCareer() async {
    _showLoadingDialog('Loading career...');

    try {
      bool success = await SaveManager.loadCurrentCareer();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          Navigator.pushNamed(context, '/career_home');
        } else {
          _showErrorDialog('Failed to load career. The save file may be corrupted.');
        }
      }
    } catch (e) {
      debugPrint('Error loading career: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
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
  void _handleContinueCareer() {
    if (CareerManager.currentCareerDriver != null) {
      Navigator.pushNamed(context, '/career_home');
    } else {
      _loadExistingCareer();
    }
  }

  // Show save slot management dialog
  void _showSaveSlotDialog() async {
    try {
      List<Map<String, dynamic>> additionalSlots = await SaveManager.getAdditionalSlots();
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
                        Text(
                          'CAREER SAVES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Formula1',
                            letterSpacing: 2,
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
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Main Save Section (read-only display)
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[900]!.withOpacity(0.3),
                              border: Border.all(color: Colors.blue[400]!, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.blue[400], size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'MAIN CAREER',
                                      style: TextStyle(
                                        color: Colors.blue[400],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Formula1',
                                      ),
                                    ),
                                    Spacer(),
                                    if (currentSave != null)
                                      IconButton(
                                        onPressed: _deleteMainSave,
                                        icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                                        tooltip: 'Delete Main Career',
                                      ),
                                  ],
                                ),
                                if (currentSave != null) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    '${currentSave['driverName']} - ${currentSave['teamName']}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Formula1',
                                    ),
                                  ),
                                  Text(
                                    'Wins: ${currentSave['careerWins']} | Points: ${currentSave['careerPoints']}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                      fontFamily: 'Formula1',
                                    ),
                                  ),
                                ] else ...[
                                  SizedBox(height: 8),
                                  Text(
                                    'No main career',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                      fontFamily: 'Formula1',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          SizedBox(height: 16),

                          // Additional Slots Header
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
                                'ADDITIONAL SAVE SLOTS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Formula1',
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Show 2 additional slots
                          ...List.generate(SaveManager.maxAdditionalSlots, (index) {
                            return _buildAdditionalSlotCard(index, additionalSlots[index]);
                          }),
                        ],
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

  // Build additional slot card
  Widget _buildAdditionalSlotCard(int index, Map<String, dynamic> slotData) {
    bool hasData = slotData.isNotEmpty;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasData ? Colors.orange[900]!.withOpacity(0.3) : Colors.grey[800]!.withOpacity(0.3),
        border: Border.all(
          color: hasData ? Colors.orange[600]! : Colors.grey[600]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: hasData ? Colors.orange[600] : Colors.grey[600],
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasData ? (slotData['slotName'] ?? 'Slot ${index + 1}') : 'Empty Slot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Formula1',
                  ),
                ),
              ),
              if (hasData) ...[
                IconButton(
                  onPressed: () => _loadFromAdditionalSlot(index),
                  icon: Icon(Icons.upload, color: Colors.blue[400], size: 20),
                  tooltip: 'Load to Main',
                ),
                IconButton(
                  onPressed: () => _deleteAdditionalSlot(index),
                  icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                  tooltip: 'Delete Slot',
                ),
              ],
            ],
          ),
          if (hasData) ...[
            SizedBox(height: 8),
            if (slotData['careerDriver'] != null) ...[
              Text(
                '${slotData['careerDriver']['name']} - ${slotData['careerDriver']['teamName']}',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                  fontFamily: 'Formula1',
                ),
              ),
              Text(
                'Wins: ${slotData['careerDriver']['careerWins'] ?? 0} | Points: ${slotData['careerDriver']['careerPoints'] ?? 0}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                  fontFamily: 'Formula1',
                ),
              ),
            ],
          ] else ...[
            SizedBox(height: 8),
            Row(
              children: [
                if (CareerManager.currentCareerDriver != null)
                  ElevatedButton.icon(
                    onPressed: () => _saveToAdditionalSlot(index),
                    icon: Icon(Icons.save, size: 16),
                    label: Text(
                      'SAVE HERE',
                      style: TextStyle(
                        fontFamily: 'Formula1',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Delete main save
  void _deleteMainSave() async {
    Navigator.pop(context); // Close slot dialog

    // Show confirmation dialog
    bool? confirmed = await _showDeleteMainSaveConfirmDialog();
    if (confirmed != true) return;

    _showLoadingDialog('Deleting main save...');

    try {
      // FIX: Use clearMainSave (main save is separate from additional slots)
      await SaveManager.clearMainSave();

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
                  'Main career deleted! (Additional slots preserved)',
                  style: TextStyle(fontFamily: 'Formula1'),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
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
                        'Additional save slots will be preserved!',
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

  // Load from additional slot
  void _loadFromAdditionalSlot(int slotIndex) async {
    Navigator.pop(context); // Close slot dialog
    _showLoadingDialog('Loading from Slot ${slotIndex + 1}...');

    try {
      bool success = await SaveManager.loadCareerFromAdditionalSlot(slotIndex);

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
                  Icon(Icons.upload, color: Colors.white),
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

  // Save to additional slot
  void _saveToAdditionalSlot(int slotIndex) async {
    Navigator.pop(context); // Close slot dialog

    // Show name input dialog
    String? slotName = await _showSlotNameDialog(slotIndex);
    if (slotName == null || slotName.isEmpty) return;

    _showLoadingDialog('Saving to Slot ${slotIndex + 1}...');

    try {
      bool success = await SaveManager.saveCareerToAdditionalSlot(slotIndex, slotName);

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

  // Delete additional slot
  void _deleteAdditionalSlot(int slotIndex) async {
    Navigator.pop(context); // Close slot dialog

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
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
            'This will permanently delete the career saved in this slot.',
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

    if (confirmed != true) return;

    _showLoadingDialog('Deleting Slot ${slotIndex + 1}...');

    try {
      bool success = await SaveManager.deleteAdditionalSlot(slotIndex);

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

  // Helper method for slot naming
  Future<String?> _showSlotNameDialog(int slotIndex) async {
    TextEditingController controller = TextEditingController();

    // Get current career info for default name
    Map<String, dynamic>? currentCareer = await SaveManager.getCareerSaveInfo();
    if (currentCareer != null) {
      controller.text = '${currentCareer['driverName']} Career';
    }

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Name for Slot ${slotIndex + 1}',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Formula1',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(color: Colors.white, fontFamily: 'Formula1'),
            decoration: InputDecoration(
              hintText: 'Enter save name...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue[400]!),
              ),
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

  // Show loading dialog
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
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Formula1',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red[400]),
              SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Formula1',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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

// Custom painter for animated grid pattern
class GridPatternPainter extends CustomPainter {
  final double animationValue;

  GridPatternPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.03 * animationValue)
      ..strokeWidth = 1;

    const double spacing = 30;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
