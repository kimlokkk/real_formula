// 📁 lib/ui/career/career_calendar_widget.dart
// 🔧 FIXED VERSION - Complete file with bug fixes

import 'package:flutter/material.dart';
import '../../services/career/career_calendar.dart';
import '../../models/career/race_weekend.dart';

class CareerCalendarWidget extends StatefulWidget {
  final Function()? onRaceWeekendReached;

  const CareerCalendarWidget({
    Key? key,
    this.onRaceWeekendReached,
  }) : super(key: key);

  @override
  _CareerCalendarWidgetState createState() => _CareerCalendarWidgetState();
}

class _CareerCalendarWidgetState extends State<CareerCalendarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    CareerCalendar.instance.initialize();

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    CareerCalendar.instance.addListener(_onCalendarUpdate);
  }

  // 🔧 FIX: Enhanced calendar update handler with proper state management
  void _onCalendarUpdate() {
    if (mounted) {
      // 🔧 FIX: Add mounted check
      setState(() {}); // 🔧 FIX: Force widget rebuild

      if (CareerCalendar.instance.currentRaceWeekend != null && widget.onRaceWeekendReached != null) {
        widget.onRaceWeekendReached!();
      }

      if (CareerCalendar.instance.isRunning && !CareerCalendar.instance.isPaused) {
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    CareerCalendar.instance.removeListener(_onCalendarUpdate);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CareerCalendar.instance,
      builder: (context, child) {
        final calendar = CareerCalendar.instance;
        final nextRace = calendar.nextRaceWeekend; // 🔧 FIX: Get fresh next race

        // 🔧 FIX: Add debug logging to track state
        debugPrint("📅 Calendar Widget Rebuild:");
        debugPrint("   Next race: ${nextRace?.name ?? 'None'}");
        debugPrint("   Completed races: ${calendar.getCompletedRaces().length}");

        return Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[900]!, Colors.red[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar header
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'F1 CALENDAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          calendar.currentMonthYear,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: calendar.isRunning && !calendar.isPaused ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStatusColor(calendar),
                            shape: BoxShape.circle,
                            boxShadow: calendar.isRunning && !calendar.isPaused
                                ? [BoxShadow(color: _getStatusColor(calendar).withOpacity(0.6), blurRadius: 4)]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 16),

              // 🔧 FIX: Updated next race display with better state handling
              if (nextRace != null) ...[
                _buildNextRaceInfo(nextRace),
                SizedBox(height: 12),
              ] else ...[
                // 🔧 FIX: Handle case when all races are completed
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.yellow, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'SEASON COMPLETE! 🏆',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
              ],

              // Controls
              _buildCalendarControls(calendar),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNextRaceInfo(RaceWeekend nextRace) {
    final calendar = CareerCalendar.instance;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_motorsports, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'NEXT: ${nextRace.name}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                nextRace.dateRange,
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white70, size: 14),
              SizedBox(width: 6),
              Text(
                nextRace.track.name,
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Spacer(),
              if (calendar.daysUntilNextRace >= 0)
                Text(
                  '${calendar.daysUntilNextRace} days',
                  style: TextStyle(
                    color: Colors.orange[300],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarControls(CareerCalendar calendar) {
    return Row(
      children: [
        // Play/Pause
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (calendar.isRunning && !calendar.isPaused) {
                calendar.pauseCalendar();
              } else {
                calendar.startCalendar();
              }
            },
            icon: Icon(
              calendar.isRunning && !calendar.isPaused ? Icons.pause : Icons.play_arrow,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              calendar.isRunning && !calendar.isPaused ? 'PAUSE' : 'CONTINUE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: calendar.isRunning && !calendar.isPaused ? Colors.orange[600] : Colors.green[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),

        SizedBox(width: 8),

        // Skip to next race
        ElevatedButton(
          onPressed: calendar.nextRaceWeekend != null ? () => calendar.skipToNextRaceWeekend() : null,
          child: Icon(
            Icons.skip_next,
            size: 18,
            color: Colors.white,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: EdgeInsets.all(8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        SizedBox(width: 8),

        // Speed control
        PopupMenuButton<String>(
          icon: Icon(Icons.speed, color: Colors.white, size: 18),
          onSelected: (String value) {
            switch (value) {
              case 'normal':
                calendar.setSpeedNormal();
                break;
              case 'fast':
                calendar.setSpeedFast();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(value: 'normal', child: Text('Normal')),
            PopupMenuItem(value: 'fast', child: Text('Fast')),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(CareerCalendar calendar) {
    if (calendar.currentRaceWeekend != null) {
      return Colors.orange;
    } else if (calendar.isRunning && !calendar.isPaused) {
      return Colors.green;
    } else if (calendar.isPaused) {
      return Colors.yellow;
    } else {
      return Colors.grey;
    }
  }
}
