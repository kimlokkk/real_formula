// lib/ui/career/race_weekend_loading.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/career/race_weekend.dart';
import '../../models/career/career_driver.dart';
import '../../models/enums.dart';
import '../../models/driver.dart';
import '../../services/weather_generator.dart';
import '../../data/driver_data.dart';

class RaceWeekendLoadingScreen extends StatefulWidget {
  final RaceWeekend raceWeekend;
  final CareerDriver careerDriver;

  const RaceWeekendLoadingScreen({
    Key? key,
    required this.raceWeekend,
    required this.careerDriver,
  }) : super(key: key);

  @override
  _RaceWeekendLoadingScreenState createState() => _RaceWeekendLoadingScreenState();
}

class _RaceWeekendLoadingScreenState extends State<RaceWeekendLoadingScreen> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _mainController;
  late AnimationController _progressController;
  late AnimationController _carController;

  // Animations
  late Animation<double> _fadeInAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _carSlideAnimation;

  // Loading State
  int _currentStep = 0;
  final int _totalSteps = 4;
  late Timer _stepTimer;
  WeatherCondition? _generatedWeather;

  // Loading Steps
  final List<String> _loadingSteps = [
    'Preparing race weekend...',
    'Analyzing track conditions...',
    'Generating weather patterns...',
    'Finalizing setup...'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLoadingSequence();
  }

  void _initializeAnimations() {
    // Main fade-in animation
    _mainController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Progress bar animation
    _progressController = AnimationController(
      duration: Duration(milliseconds: 5000), // 5 seconds total
      vsync: this,
    );

    // Car sliding animation
    _carController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _carSlideAnimation = Tween<double>(begin: -1.0, end: 1.2).animate(
      CurvedAnimation(parent: _carController, curve: Curves.easeInOut),
    );

    // Start animations
    _mainController.forward();
    _progressController.forward();
    _carController.repeat();
  }

  void _startLoadingSequence() {
    // Update steps every 1.25 seconds (5 seconds total / 4 steps)
    _stepTimer = Timer.periodic(Duration(milliseconds: 1250), (timer) {
      if (mounted) {
        setState(() {
          if (_currentStep < _totalSteps - 1) {
            _currentStep++;

            // Generate weather on step 2 (weather analysis)
            if (_currentStep == 2) {
              _generateWeather();
            }
          }
        });

        // Complete loading after all steps
        if (_currentStep >= _totalSteps - 1) {
          timer.cancel();
          _completeLoading();
        }
      }
    });
  }

  void _generateWeather() {
    _generatedWeather = WeatherGenerator.generateWeatherForTrack(widget.raceWeekend.track.name);
  }

  void _completeLoading() {
    // Wait a moment then navigate to qualifying
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _navigateToQualifying();
      }
    });
  }

  void _navigateToQualifying() {
    // Create drivers list (career driver + AI)
    List<Driver> drivers = _createRaceDrivers();

    // Navigate to qualifying with all pre-configured data
    Navigator.pushReplacementNamed(
      context,
      '/qualifying',
      arguments: {
        'track': widget.raceWeekend.track,
        'weather': _generatedWeather ?? WeatherCondition.clear,
        'speed': SimulationSpeed.normal,
        'drivers': drivers,
        'careerMode': true,
        'careerDriver': widget.careerDriver,
        'raceWeekend': widget.raceWeekend,
        'isCalendarRace': true,
        'preConfigured': true, // Flag to skip setup
      },
    );
  }

  List<Driver> _createRaceDrivers() {
    List<Driver> raceDrivers = [];

    // Get all AI drivers
    List<Driver> aiDrivers = DriverData.createDefaultDrivers();

    // Find and remove the driver that the career driver is replacing
    // (the one from the same team as the career driver)
    List<Driver> teammateDrivers =
        aiDrivers.where((driver) => driver.team.name == widget.careerDriver.team.name).toList();

    if (teammateDrivers.isNotEmpty) {
      // Remove the first teammate to make room for career driver
      Driver driverToReplace = teammateDrivers.first;
      aiDrivers.removeWhere((driver) => driver.name == driverToReplace.name);

      print(
          '🔄 Replacing ${driverToReplace.name} with ${widget.careerDriver.name} in ${widget.careerDriver.team.name}');
    }

    // Create career driver for race
    Driver careerDriverForRace = Driver(
      name: widget.careerDriver.name,
      abbreviation: widget.careerDriver.abbreviation,
      team: widget.careerDriver.team,
      speed: widget.careerDriver.speed,
      consistency: widget.careerDriver.consistency,
      racecraft: widget.careerDriver.racecraft,
      tyreManagementSkill: widget.careerDriver.tyreManagementSkill,
      experience: widget.careerDriver.experience,
    );

    // Add career driver first
    raceDrivers.add(careerDriverForRace);

    // Add the remaining AI drivers (should be 19 now)
    raceDrivers.addAll(aiDrivers);

    print('📊 Total drivers: ${raceDrivers.length}');
    print(
        '🏎️ ${widget.careerDriver.team.name} drivers: ${raceDrivers.where((d) => d.team.name == widget.careerDriver.team.name).map((d) => d.name).join(", ")}');

    return raceDrivers;
  }

  @override
  void dispose() {
    _stepTimer.cancel();
    _mainController.dispose();
    _progressController.dispose();
    _carController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Container(
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
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 40),
                  _buildTrackInfo(),
                  SizedBox(height: 40),
                  _buildAnimatedCar(),
                  Spacer(),
                  _buildLoadingProgress(),
                  SizedBox(height: 40),
                  _buildWeatherInfo(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.sports_motorsports,
          color: Colors.red[400],
          size: 48,
        ),
        SizedBox(height: 16),
        Text(
          'RACE WEEKEND',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Round ${widget.raceWeekend.round} of 23',
          style: TextStyle(
            color: Colors.red[300],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            widget.raceWeekend.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            '${widget.raceWeekend.track.name}, ${widget.raceWeekend.track.country}',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTrackStat('Laps', '${widget.raceWeekend.track.totalLaps}'),
              _buildTrackStat('Type', widget.raceWeekend.track.typeDescription),
              _buildTrackStat('Date', widget.raceWeekend.dateRange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCar() {
    return Container(
      height: 60,
      child: Stack(
        children: [
          // Track line
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.red[400]!,
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          // Animated car
          AnimatedBuilder(
            animation: _carSlideAnimation,
            builder: (context, child) {
              return Positioned(
                left: MediaQuery.of(context).size.width * 0.8 * _carSlideAnimation.value,
                bottom: 5,
                child: Icon(
                  Icons.double_arrow_outlined,
                  color: Colors.red[400],
                  size: 32,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingProgress() {
    return Column(
      children: [
        Text(
          _loadingSteps[_currentStep],
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(3),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: [Colors.red[600]!, Colors.red[400]!],
                  ),
                ),
                width: MediaQuery.of(context).size.width * 0.8 * _progressAnimation.value,
              );
            },
          ),
        ),
        SizedBox(height: 12),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            int percentage = (_progressAnimation.value * 100).round();
            return Text(
              '$percentage%',
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeatherInfo() {
    if (_currentStep < 2) {
      return Container(
        height: 60,
        child: Center(
          child: Text(
            'Weather analysis pending...',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (_generatedWeather == WeatherCondition.rain ? Colors.blue[900] : Colors.green[900])!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_generatedWeather == WeatherCondition.rain ? Colors.blue[400] : Colors.green[400])!.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _generatedWeather == WeatherCondition.rain ? Icons.water_drop : Icons.wb_sunny,
                color: _generatedWeather == WeatherCondition.rain ? Colors.blue[300] : Colors.yellow[300],
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'WEATHER CONDITIONS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            WeatherGenerator.getWeatherDescription(
                widget.raceWeekend.track.name, _generatedWeather ?? WeatherCondition.clear),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
