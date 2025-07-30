// lib/ui/main_menu_page.dart - Enhanced F1 Theme
import 'package:flutter/material.dart';
import 'package:real_formula/services/career/career_manager.dart';

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

    // Start animations sequence
    _logoController.forward();
    Future.delayed(Duration(milliseconds: 800), () {
      _buttonController.forward();
    });
    Future.delayed(Duration(milliseconds: 1200), () {
      _gridController.forward();
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
                'F1 CAREER',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900, // Uses Formula1-Wide
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
                  // Primary action button
                  _buildEnhancedButton(
                    label: 'START CAREER',
                    subtitle: 'Begin your F1 journey',
                    icon: Icons.flag,
                    onPressed: _handleCareerMode,
                    isPrimary: true,
                    gradientColors: [Colors.red[500]!, Colors.red[700]!],
                    isEnabled: true,
                  ),

                  SizedBox(height: 20),

                  // Continue career (always visible, disabled if no career)
                  _buildEnhancedButton(
                    label: 'CONTINUE CAREER',
                    subtitle:
                        CareerManager.currentCareerDriver != null ? 'Resume your championship' : 'No career found',
                    icon: Icons.play_arrow,
                    onPressed: CareerManager.currentCareerDriver != null
                        ? () {
                            Navigator.pushNamed(context, '/career_home');
                          }
                        : null, // null makes button disabled
                    isPrimary: false,
                    gradientColors: CareerManager.currentCareerDriver != null
                        ? [Colors.blue[600]!, Colors.blue[800]!]
                        : [Colors.grey[700]!, Colors.grey[800]!],
                    isEnabled: CareerManager.currentCareerDriver != null,
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

  void _handleCareerMode() {
    if (CareerManager.currentCareerDriver != null) {
      Navigator.pushNamed(context, '/career_home');
    } else {
      Navigator.pushNamed(context, '/driver_creation');
    }
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
