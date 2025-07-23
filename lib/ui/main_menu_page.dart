// lib/ui/main_menu_page.dart - Updated with Career Mode
import 'package:flutter/material.dart';
import 'package:real_formula/services/career/career_manager.dart';

class MainMenuPage extends StatefulWidget {
  @override
  _MainMenuPageState createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _buttonController;
  late Animation<double> _logoAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Button animation
    _buttonController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.bounceOut,
    ));

    // Start animations
    _logoController.forward();
    Future.delayed(Duration(milliseconds: 500), () {
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red[900]!,
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top spacer
              Expanded(child: Container()),

              // Logo section
              Expanded(
                flex: 3,
                child: AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // F1 Logo
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Text(
                              'F1',
                              style: TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[600],
                                letterSpacing: 5,
                              ),
                            ),
                          ),

                          SizedBox(height: 20),

                          // Title
                          Text(
                            'REAL FORMULA',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              letterSpacing: 5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Buttons section
              Expanded(
                flex: 4,
                child: AnimatedBuilder(
                  animation: _buttonAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - _buttonAnimation.value)),
                      child: Opacity(
                        opacity: _buttonAnimation.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Career Mode Button (NEW - Primary)
                            _buildMainButton(
                              label: 'CAREER MODE',
                              icon: Icons.timeline,
                              onPressed: _handleCareerMode,
                              isPrimary: true,
                              description: 'Build your F1 legend',
                            ),

                            SizedBox(height: 16),

                            // Quick Race Button
                            _buildMainButton(
                              label: 'QUICK RACE',
                              icon: Icons.flash_on,
                              onPressed: () {
                                Navigator.pushNamed(context, '/setup');
                              },
                              isPrimary: false,
                              description: 'Single race weekend',
                            ),

                            SizedBox(height: 16),

                            // Championship Button (for full season mode)
                            _buildMainButton(
                              label: 'CHAMPIONSHIP',
                              icon: Icons.emoji_events,
                              onPressed: () {
                                Navigator.pushNamed(context, '/setup');
                              },
                              isPrimary: false,
                              description: 'Full F1 season',
                            ),

                            SizedBox(height: 30),

                            // Secondary buttons row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSecondaryButton(
                                  label: 'SETTINGS',
                                  icon: Icons.settings,
                                  onPressed: () {
                                    _showSettingsDialog();
                                  },
                                ),
                                _buildSecondaryButton(
                                  label: 'ABOUT',
                                  icon: Icons.info,
                                  onPressed: () {
                                    _showAboutDialog();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom section
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'v1.1.0 - Career Mode',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
    String? description,
  }) {
    return Container(
      width: 320,
      child: Column(
        children: [
          Container(
            height: 60,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPrimary ? Colors.red[600] : Colors.grey[700],
                foregroundColor: Colors.white,
                elevation: 10,
                shadowColor: isPrimary ? Colors.red.withOpacity(0.5) : Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (description != null) ...[
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 120,
      height: 45,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.grey[600]!, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Handle Career Mode button press
  void _handleCareerMode() {
    // Check if there's an existing career
    if (CareerManager.currentCareerDriver != null) {
      // Resume existing career
      Navigator.pushNamed(context, '/career_home');
    } else {
      // Show career options dialog
      _showCareerModeDialog();
    }
  }

  // NEW: Show career mode options
  void _showCareerModeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            children: [
              Icon(Icons.timeline, color: Colors.red[600], size: 24),
              SizedBox(width: 8),
              Text(
                'CAREER MODE',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your career path:',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              SizedBox(height: 16),

              // New Career Button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/driver_creation');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add, size: 20),
                      SizedBox(width: 8),
                      Text('NEW CAREER', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Load Career Button (placeholder)
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: null, // TODO: Implement load career
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload, size: 20),
                      SizedBox(width: 8),
                      Text('LOAD CAREER', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'CANCEL',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'SETTINGS',
            style: TextStyle(
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Game settings will be available in future updates.',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'CLOSE',
                style: TextStyle(color: Colors.red[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'ABOUT F1 RACE SIMULATOR',
            style: TextStyle(
              color: Colors.white,
              letterSpacing: 2,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A realistic Formula 1 race simulation featuring:',
                style: TextStyle(color: Colors.grey[400]),
              ),
              SizedBox(height: 10),
              Text(
                '• Career Mode - Build your F1 legend',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                '• Real driver skills and car performance',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                '• Dynamic weather conditions',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                '• Strategic pit stops and tire management',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                '• Multiple authentic F1 tracks',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                '• Live race visualization',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'CLOSE',
                style: TextStyle(color: Colors.red[600]),
              ),
            ),
          ],
        );
      },
    );
  }
}
