// lib/ui/main_menu_page.dart - Enhanced F1 Theme
import 'package:flutter/material.dart';
import 'package:real_formula/services/career/career_manager.dart';
import 'package:real_formula/services/career/save_manager.dart';
import 'package:real_formula/ui/career/save_load_menu.dart';

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

  @override
  void initState() {
    super.initState();

    // Original animation setup
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

    _backgroundController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat();
    _backgroundShift = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundController);

    _gridController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );
    _gridAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gridController,
      curve: Curves.easeInOut,
    ));

    // NEW: Check for existing career and auto-load if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForExistingCareer();

      // Start animations
      _logoController.forward();
      Future.delayed(Duration(milliseconds: 500), () {
        _buttonController.forward();
      });
      Future.delayed(Duration(milliseconds: 1000), () {
        _gridController.forward();
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _buttonController.dispose();
    _backgroundController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  Future<void> _checkForExistingCareer() async {
    try {
      debugPrint("🔄 Checking for existing career on startup...");

      // Initialize save system (this will auto-load most recent career)
      await SaveManager.initializeSaveSystem();

      // Check if continue career should be shown (after auto-load)
      bool shouldShow = await SaveManager.shouldShowContinueCareer();

      if (shouldShow) {
        debugPrint("✅ Continue career will be shown");
      } else {
        debugPrint("ℹ️ No continue career to show");
      }

      // Refresh UI to show/hide Continue Career button
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("⚠️ Error during startup career check: $e");
    }
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
                  fontWeight: FontWeight.w400, // Formula1-Regular
                  fontFamily: 'Formula1',
                  letterSpacing: 2,
                ),
              ),
              Text(
                'CAREER MODE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700, // Formula1-Bold
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
                'SEASON 2024',
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
                'REAL FORMULA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.3,
                  fontSize: 42,
                  fontWeight: FontWeight.w900, // Uses Formula1-Wide
                  fontFamily: 'Formula1',
                  color: Colors.white,
                  letterSpacing: 5,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 4),
                      blurRadius: 8,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 10,
              ),

              Text(
                'F1 CAREER SIMULATOR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400, // Uses Formula1-Regular
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
                  // Primary action button - New Career
                  _buildEnhancedButton(
                    label: 'NEW CAREER',
                    subtitle: 'Start your F1 journey',
                    icon: Icons.add_circle_outline,
                    onPressed: _handleNewCareer,
                    isPrimary: true,
                    gradientColors: [Colors.red[500]!, Colors.red[700]!],
                    isEnabled: true,
                  ),

                  SizedBox(height: 16),

                  // Load Career - Always visible
                  _buildEnhancedButton(
                    label: 'LOAD CAREER',
                    subtitle: 'Continue saved careers',
                    icon: Icons.folder_open,
                    onPressed: _handleLoadCareer,
                    isPrimary: false,
                    gradientColors: [Colors.blue[600]!, Colors.blue[800]!],
                    isEnabled: true,
                  ),

                  // 🔧 SIMPLE: Continue Career button
                  if (CareerManager.currentCareerDriver != null) ...[
                    SizedBox(height: 16),
                    _buildEnhancedButton(
                      label: 'CONTINUE CAREER',
                      subtitle: 'Resume ${CareerManager.currentCareerDriver!.name}',
                      icon: Icons.play_arrow,
                      onPressed: _handleContinueCareer,
                      isPrimary: false,
                      gradientColors: [Colors.green[600]!, Colors.green[800]!],
                      isEnabled: true,
                    ),
                  ],

                  SizedBox(height: 32),

                  // Secondary options
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryButton(
                          label: 'SETTINGS',
                          icon: Icons.settings,
                          onPressed: _handleSettings,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildSecondaryButton(
                          label: 'ABOUT',
                          icon: Icons.info_outline,
                          onPressed: _handleAbout,
                        ),
                      ),
                    ],
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
    required VoidCallback? onPressed, // Made nullable for disabled state
    required bool isPrimary,
    required List<Color> gradientColors,
    bool isEnabled = true, // Added isEnabled parameter
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
          opacity: isEnabled ? 1.0 : 0.5, // Reduce opacity when disabled
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
                  : [], // No shadow when disabled
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
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isEnabled ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.4),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Disabled overlay (optional visual indicator)
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
                    fontWeight: FontWeight.w400, // Formula1-Regular
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

  void _handleNewCareer() async {
    // Check if there's an active career and warn user
    if (CareerManager.currentCareerDriver != null) {
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Start New Career',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Formula1',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Starting a new career will replace your current progress.\n\nWould you like to save your current career first?',
            style: TextStyle(
              color: Colors.grey[300],
              fontFamily: 'Formula1',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                // Navigate to save menu first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SaveLoadMenu(isLoadMode: false),
                  ),
                );
              },
              child: Text('Save First'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: Text('Start New'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    // Navigate to driver creation
    Navigator.pushNamed(context, '/driver_creation');
  }

  void _handleLoadCareer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaveLoadMenu(isLoadMode: true),
      ),
    );
  }

// ADD this new method for continuing current career:
  void _handleContinueCareer() {
    if (CareerManager.currentCareerDriver != null) {
      Navigator.pushNamed(context, '/career_home');
    }
  }

// ADD this new method for building secondary buttons:
  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'Formula1',
            letterSpacing: 1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

// ADD these placeholder methods for settings and about:
  void _handleSettings() {
    // Placeholder for settings functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings coming soon'),
        backgroundColor: Colors.grey[700],
      ),
    );
  }

  void _handleAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'F1 Career Simulator',
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
              'Version 1.0',
              style: TextStyle(
                color: Colors.grey[400],
                fontFamily: 'Formula1',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Experience the thrill of Formula 1 career mode with realistic progression, championship battles, and career management.',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Formula1',
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('OK'),
          ),
        ],
      ),
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
