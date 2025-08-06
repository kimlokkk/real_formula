// Enhanced Strategy Engine with Strategic Planning and Pit Timing Intelligence
import 'dart:math';
import '../models/driver.dart';
import '../models/enums.dart';
import '../models/track.dart';
import '../models/race_strategy.dart';
import '../utils/constants.dart';

// Add these classes at the top of strategy_engine.dart (after imports)

class CompoundStrategy {
  final List<TireCompound> compounds;
  final List<int> stintLengths;

  const CompoundStrategy({
    required this.compounds,
    required this.stintLengths,
  });
}

class StrategyAnalysis {
  final List<TireCompound> compounds;
  final double bestCaseTime;
  final double expectedTime;
  final double worstCaseTime;
  final double uncertaintyRange;
  String reasoning;

  StrategyAnalysis({
    required this.compounds,
    required this.bestCaseTime,
    required this.expectedTime,
    required this.worstCaseTime,
    required this.uncertaintyRange,
    this.reasoning = "",
  });
}

class StrategyEngine {
  // ═══════════════════════════════════════════════════════════════
  // STRATEGIC PLANNING FUNCTIONS (Pre-Race Strategy Selection)
  // ═══════════════════════════════════════════════════════════════

  /// Plans the optimal race strategy for a driver based on track and starting position
  /// This is called BEFORE the race starts to set each driver's strategy
  static RaceStrategy planOptimalStrategy(
      Driver driver,
      Track track,
      int startPosition,
      WeatherCondition weather,
      RainIntensity? rainIntensity) {
    // Calculate viability scores for both strategies
    double oneStopScore =
        _calculateOneStopViability(track, driver, startPosition);
    double twoStopScore =
        _calculateTwoStopViability(track, driver, startPosition);

    // Add some randomness to prevent everyone choosing the same strategy (±0.08)
    double randomVariation =
        (Random().nextDouble() - 0.5) * 0.16; // -0.08 to +0.08
    oneStopScore += randomVariation;
    twoStopScore -= randomVariation; // Opposite variation to maintain balance

    // Clamp scores after randomization
    oneStopScore = oneStopScore.clamp(0.0, 1.0);
    twoStopScore = twoStopScore.clamp(0.0, 1.0);

    // Decide strategy based on higher score
    if (oneStopScore > twoStopScore) {
      return _planOneStopStrategy(
          driver, track, oneStopScore, weather, rainIntensity);
    } else {
      return _planTwoStopStrategy(
          driver, track, twoStopScore, weather, rainIntensity);
    }
  }

  /// Calculates how viable a one-stop strategy is for this track and driver
  /// Returns a score from 0.0 (impossible) to 1.0 (perfect)
  static double _calculateOneStopViability(
      Track track, Driver driver, int startPosition) {
    double viabilityScore = 0.5; // Start with neutral base

    // TRACK FACTORS (most important)

    // 1. Overtaking Difficulty - Hard to overtake = One-stop favored
    if (track.overtakingDifficulty <= 0.3) {
      viabilityScore += 0.25; // Monaco, Hungary type tracks
    } else if (track.overtakingDifficulty <= 0.4) {
      viabilityScore += 0.15; // Spain, Imola type tracks
    } else if (track.overtakingDifficulty >= 0.7) {
      viabilityScore -= 0.15; // Easy overtaking = one-stop less effective
    }

    // 2. Tire Degradation - Low degradation = One-stop possible
    if (track.tireDegradationMultiplier <= 0.9) {
      viabilityScore += 0.2; // Very easy on tires
    } else if (track.tireDegradationMultiplier <= 1.1) {
      viabilityScore += 0.1; // Moderate tire wear
    } else if (track.tireDegradationMultiplier >= 1.3) {
      viabilityScore -= 0.25; // High tire degradation
    } else if (track.tireDegradationMultiplier >= 1.5) {
      viabilityScore -= 0.4; // Extreme tire degradation
    }

    // 3. Pit Lane Time Penalty - Long pit lane = Fewer stops better
    if (track.pitStopTimePenalty >= 1.0) {
      viabilityScore += 0.15; // Long pit lane
    } else if (track.pitStopTimePenalty >= 0.5) {
      viabilityScore += 0.1; // Moderate pit lane penalty
    }

    // 4. Track Type Specific
    switch (track.type) {
      case TrackType.street:
        viabilityScore += 0.15; // Street circuits favor one-stop
        break;
      case TrackType.technical:
        viabilityScore += 0.1; // Technical tracks can work with one-stop
        break;
      case TrackType.power:
        viabilityScore -= 0.05; // Power tracks slightly favor multi-stop
        break;
      case TrackType.highSpeed:
        viabilityScore -= 0.1; // High-speed tracks usually need more stops
        break;
      case TrackType.mixed:
        // No change - depends on other factors
        break;
    }

    // DRIVER-DEPENDENT FACTORS

    // 5. Speed Emphasis - Driver-dependent modifier
    if (track.speedEmphasis >= 1.2) {
      // Fast drivers get penalized on speed tracks (fresher tires matter more)
      double speedPenalty =
          ((driver.speed - 75.0) / 25.0) * 0.03; // Range: -0.03 to +0.03
      viabilityScore -=
          speedPenalty; // Fast drivers lose one-stop viability on speed tracks
    } else if (track.speedEmphasis <= 0.8) {
      // Non-speed tracks: slower drivers get tiny one-stop bonus
      double speedAdvantage =
          ((75.0 - driver.speed) / 25.0) * 0.04; // Max +0.04 for slow drivers
      viabilityScore += speedAdvantage;
    }

    // 6. Car Performance Emphasis - Team-dependent modifier
    if (track.carPerformanceEmphasis >= 1.2) {
      // Bad teams get strategy preference (one-stop is their weapon)
      if (driver.team.carPerformance <= 78) {
        viabilityScore += 0.08; // Strategy is their weapon
      } else if (driver.team.carPerformance <= 82) {
        viabilityScore += 0.04; // Moderate strategy preference
      }

      // SPECIAL: Leading positions prefer track position regardless of car quality
      if (startPosition <= 3) {
        viabilityScore += 0.04; // Leaders protect position
      }
    }

    // 7. Tire Management Skill - Better tire management = Can do longer stints
    double tireSkillBonus = (driver.tyreManagementSkill - 50.0) /
        100.0 *
        0.2; // ±0.2 based on skill
    viabilityScore += tireSkillBonus;

    // 8. Consistency - Consistent drivers can manage long stints better
    double consistencyBonus = (driver.consistency - 50.0) /
        100.0 *
        0.15; // ±0.15 based on consistency
    viabilityScore += consistencyBonus;

    // RACE SITUATION FACTORS

    // 9. Starting Position - Lower positions can benefit more from strategy
    if (startPosition >= 15) {
      viabilityScore += 0.1; // Back of grid - strategy gamble worthwhile
    } else if (startPosition >= 10) {
      viabilityScore += 0.05; // Midfield - some strategy benefit
    } else if (startPosition <= 3) {
      viabilityScore -=
          0.05; // Top positions - safer to follow conventional strategy
    }

    // 10. Team Performance - Better teams can make one-stop work better
    double teamBonus =
        (driver.team.carPerformance - 85.0) / 15.0 * 0.1; // ±0.1 based on team
    viabilityScore += teamBonus;

    // SPECIAL MODIFIERS

    // 11. If track explicitly favors two-stop, penalize one-stop heavily
    if (track.favorsTwoStop) {
      viabilityScore -= 0.3;
    }

    // 12. Race distance - Very long races make one-stop harder
    if (track.totalLaps >= 70) {
      viabilityScore -= 0.1; // Long races
    } else if (track.totalLaps <= 50) {
      viabilityScore += 0.1; // Short races favor one-stop
    }

    // Cap the score between 0.0 and 1.0
    return viabilityScore.clamp(0.0, 1.0);
  }

  /// Calculates how viable a two-stop strategy is for this track and driver
  /// Returns a score from 0.0 (terrible) to 1.0 (perfect)
  static double _calculateTwoStopViability(
      Track track, Driver driver, int startPosition) {
    double viabilityScore =
        0.6; // Start with slightly higher base (2-stop is more common)

    // TRACK FACTORS (most important)

    // 1. Tire Degradation - High degradation = Two-stop necessary
    if (track.tireDegradationMultiplier >= 1.5) {
      viabilityScore += 0.3; // Extreme tire degradation
    } else if (track.tireDegradationMultiplier >= 1.3) {
      viabilityScore += 0.2; // High tire degradation
    } else if (track.tireDegradationMultiplier >= 1.1) {
      viabilityScore += 0.1; // Moderate tire wear
    } else if (track.tireDegradationMultiplier <= 0.9) {
      viabilityScore -= 0.2; // Low degradation = two-stop less necessary
    }

    // 2. Overtaking Difficulty - Easy to overtake = Two-stop more viable
    if (track.overtakingDifficulty >= 0.7) {
      viabilityScore +=
          0.2; // Easy overtaking = can recover positions after pit
    } else if (track.overtakingDifficulty >= 0.5) {
      viabilityScore += 0.1; // Moderate overtaking
    } else if (track.overtakingDifficulty <= 0.3) {
      viabilityScore -= 0.25; // Hard to overtake = two-stop risky
    }

    // 3. Pit Lane Time Penalty - Short pit lane = More stops viable
    if (track.pitStopTimePenalty <= 0.0) {
      viabilityScore += 0.1; // No penalty = stops are cheaper
    } else if (track.pitStopTimePenalty >= 1.0) {
      viabilityScore -= 0.15; // Long pit lane = stops expensive
    } else if (track.pitStopTimePenalty >= 0.5) {
      viabilityScore -= 0.05; // Moderate penalty
    }

    // 4. Track Type Specific
    switch (track.type) {
      case TrackType.street:
        viabilityScore -= 0.2; // Street circuits punish extra stops
        break;
      case TrackType.technical:
        viabilityScore += 0.05; // Technical tracks can reward fresh tires
        break;
      case TrackType.power:
        viabilityScore += 0.1; // Power tracks favor fresher tires
        break;
      case TrackType.highSpeed:
        viabilityScore += 0.15; // High-speed tracks are hard on tires
        break;
      case TrackType.mixed:
        viabilityScore += 0.05; // Mixed tracks slightly favor two-stop
        break;
    }

    // DRIVER-DEPENDENT FACTORS

    // 5. Speed Emphasis - Driver-dependent modifier
    if (track.speedEmphasis >= 1.2) {
      // Fast drivers get advantage on speed tracks (can maximize fresh tire benefit)
      double speedAdvantage =
          ((driver.speed - 75.0) / 25.0) * 0.06; // Range: -0.06 to +0.06
      viabilityScore += speedAdvantage;
    } else if (track.speedEmphasis <= 0.8) {
      // Non-speed tracks: Good teams lose some two-stop advantage
      if (driver.team.carPerformance >= 95) {
        viabilityScore -= 0.02; // Can't rely purely on car speed
      }
      // Bad teams get slight confidence boost
      if (driver.team.carPerformance <= 80) {
        viabilityScore += 0.03; // "We can compete here"
      }
    }

    // 6. Car Performance Emphasis - Team-dependent modifier
    if (track.carPerformanceEmphasis >= 1.2) {
      // Good teams get slight confidence for strategic risks (but small!)
      double teamConfidence = ((driver.team.carPerformance - 85.0) / 15.0) *
          0.03; // Range: -0.03 to +0.03
      viabilityScore += teamConfidence;
    }

    // DRIVER SKILL FACTORS

    // 7. Speed vs Tire Management trade-off
    // Fast drivers can make up time with fresh tires, careful drivers prefer fewer stops
    double speedVsTireBalance =
        (driver.speed - driver.tyreManagementSkill) / 100.0;
    viabilityScore += speedVsTireBalance * 0.15; // ±0.15 based on driver style

    // 8. Racecraft - Good racecraft = more confident with risky strategies
    double racecraftBonus =
        (driver.racecraft - 50.0) / 100.0 * 0.08; // ±0.08 based on racecraft
    viabilityScore += racecraftBonus;

    // 9. Experience - Experienced drivers more likely to attempt complex strategies
    double experienceBonus =
        (driver.experience - 50.0) / 100.0 * 0.06; // ±0.06 based on experience
    viabilityScore += experienceBonus;

    // RACE SITUATION FACTORS

    // 10. Starting Position - Different positions benefit differently
    if (startPosition >= 15) {
      viabilityScore += 0.05; // Back of grid - fresh tires help overtaking
    } else if (startPosition >= 6 && startPosition <= 10) {
      viabilityScore += 0.1; // Midfield sweet spot - can jump positions
    } else if (startPosition <= 3) {
      viabilityScore -=
          0.1; // Top positions - track position valuable, avoid risks
    }

    // 11. Team Pit Crew Quality - Better pit crews favor more stops
    double pitCrewBonus =
        (driver.team.pitStopSpeed - 1.0) * 0.2; // Faster crews get bonus
    viabilityScore += pitCrewBonus;

    // 12. Team Strategy Preference
    if (driver.team.strategy == "aggressive") {
      viabilityScore += 0.1; // Aggressive teams prefer two-stop
    } else if (driver.team.strategy == "conservative") {
      viabilityScore -= 0.05; // Conservative teams prefer one-stop
    }

    // SPECIAL MODIFIERS

    // 13. If track explicitly favors two-stop, bonus
    if (track.favorsTwoStop) {
      viabilityScore += 0.25;
    }

    // 14. Weather considerations (if planning for potential rain)
    if (track.weatherImpactMultiplier >= 1.3) {
      viabilityScore +=
          0.05; // Weather-sensitive tracks benefit from strategy flexibility
    }

    // 15. Race length considerations
    if (track.totalLaps >= 70) {
      viabilityScore += 0.1; // Long races make tire management crucial
    } else if (track.totalLaps <= 45) {
      viabilityScore -= 0.1; // Short races favor fewer stops
    }

    // 16. Tire Management Emphasis - High tire management tracks favor two-stop
    if (track.tireManagementEmphasis >= 1.3) {
      viabilityScore += 0.1; // Tire-critical tracks
    }

    // Cap the score between 0.0 and 1.0
    return viabilityScore.clamp(0.0, 1.0);
  }

  /// Plans a specific one-stop strategy with pit lap and tire compounds
  static RaceStrategy _planOneStopStrategy(
      Driver driver,
      Track track,
      double viabilityScore,
      WeatherCondition weather, // ADD THIS PARAMETER
      RainIntensity? rainIntensity // ADD THIS PARAMETER
      ) {
    // Calculate optimal pit window for one-stop (later than two-stop)
    int basePitLap =
        (track.totalLaps * 0.45).round(); // Around 45% through the race

    // Adjust based on track characteristics
    if (track.tireDegradationMultiplier >= 1.3) {
      basePitLap -= 5; // Pit earlier on high degradation tracks
    } else if (track.tireDegradationMultiplier <= 0.9) {
      basePitLap += 5; // Can stay out longer on easy tire tracks
    }

    // Adjust based on driver skills
    double tireSkillFactor =
        (driver.tyreManagementSkill - 75.0) / 25.0; // -1.0 to +1.0
    int skillAdjustment =
        (tireSkillFactor * 3).round(); // ±3 laps based on tire skill
    basePitLap += skillAdjustment;

    // Position-based adjustments
    int startPosition = driver.startingPosition;
    if (startPosition <= 3) {
      basePitLap += 3; // Leaders can stay out longer (track position)
    } else if (startPosition >= 15) {
      basePitLap -= 2; // Back markers pit earlier (avoid traffic)
    }

    // Add some randomness (±4 laps)
    int randomVariation = Random().nextInt(9) - 4; // -4 to +4
    basePitLap += randomVariation;

    // Clamp to reasonable bounds
    int minPitLap =
        (track.totalLaps * 0.25).round(); // No earlier than 25% distance
    int maxPitLap = track.totalLaps - 8; // Must pit at least 8 laps before end
    int plannedPitLap = basePitLap.clamp(minPitLap, maxPitLap);

    // Choose tire compounds for one-stop strategy
    List<TireCompound> plannedCompounds = _chooseOneStopCompounds(
        driver,
        track,
        plannedPitLap,
        weather, // ADD WEATHER PARAMETER
        rainIntensity // ADD RAIN INTENSITY PARAMETER
        );

    // Calculate expected race time (rough estimate)
    double expectedRaceTime =
        _estimateRaceTime(track, driver, StrategyType.oneStop, [plannedPitLap]);

    // Generate reasoning
    String reasoning = _getStrategyReasoning(
        track, driver, startPosition, true, viabilityScore);

    return RaceStrategy(
      type: StrategyType.oneStop,
      plannedPitLaps: [plannedPitLap],
      plannedCompounds: plannedCompounds,
      expectedRaceTime: expectedRaceTime,
      reasoning: reasoning,
      viabilityScore: viabilityScore,
    );
  }

  /// Plans a specific two-stop strategy with pit laps and tire compounds
  static RaceStrategy _planTwoStopStrategy(
      Driver driver,
      Track track,
      double viabilityScore,
      WeatherCondition weather, // ADD THIS PARAMETER
      RainIntensity? rainIntensity // ADD THIS PARAMETER
      ) {
    // Calculate optimal pit windows for two-stop
    // First pit: Around 25-30% race distance, Second pit: Around 60-70% race distance
    int firstPitLap =
        (track.totalLaps * 0.27).round(); // Around 27% through the race
    int secondPitLap =
        (track.totalLaps * 0.65).round(); // Around 65% through the race

    // Adjust based on track characteristics
    if (track.tireDegradationMultiplier >= 1.4) {
      // High degradation - pit more frequently
      firstPitLap -= 3;
      secondPitLap -= 2;
    } else if (track.tireDegradationMultiplier <= 1.0) {
      // Low degradation - can extend stints
      firstPitLap += 2;
      secondPitLap += 3;
    }

    // Adjust based on driver skills and team strategy
    double tireSkillFactor =
        (driver.tyreManagementSkill - 75.0) / 25.0; // -1.0 to +1.0
    int skillAdjustment =
        (tireSkillFactor * 2).round(); // ±2 laps based on tire skill
    firstPitLap += skillAdjustment;
    secondPitLap += skillAdjustment;

    // Position-based strategy adjustments
    int startPosition = driver.startingPosition;
    if (startPosition <= 3) {
      // Leaders: slightly more conservative (later pits)
      firstPitLap += 2;
      secondPitLap += 2;
    } else if (startPosition >= 15) {
      // Back markers: more aggressive (earlier pits to jump strategy)
      firstPitLap -= 2;
      secondPitLap -= 1;
    } else if (startPosition >= 6 && startPosition <= 10) {
      // Midfield: aggressive strategy to gain positions
      firstPitLap -= 1;
      // Keep second pit normal
    }

    // Team strategy influence
    if (driver.team.strategy == "aggressive") {
      firstPitLap -= 2; // Earlier first pit for undercut attempts
    } else if (driver.team.strategy == "conservative") {
      firstPitLap += 1; // Slightly later, more cautious
      secondPitLap += 1;
    }

    // Add randomness to create variety (±3 laps each)
    int firstVariation = Random().nextInt(7) - 3; // -3 to +3
    int secondVariation = Random().nextInt(7) - 3; // -3 to +3
    firstPitLap += firstVariation;
    secondPitLap += secondVariation;

    // Ensure proper spacing between pit stops (minimum 15 laps apart)
    if (secondPitLap - firstPitLap < 15) {
      secondPitLap = firstPitLap + 15;
    }

    // Clamp to reasonable bounds
    int minFirstPit = 12; // No earlier than lap 12
    int maxFirstPit =
        (track.totalLaps * 0.4).round(); // No later than 40% distance
    int minSecondPit = firstPitLap + 15; // At least 15 laps after first pit
    int maxSecondPit = track.totalLaps - 5; // Must leave at least 5 laps at end

    firstPitLap = firstPitLap.clamp(minFirstPit, maxFirstPit);
    secondPitLap = secondPitLap.clamp(minSecondPit, maxSecondPit);

    // Choose tire compounds for two-stop strategy
    List<TireCompound> plannedCompounds = _chooseTwoStopCompounds(
        driver,
        track,
        firstPitLap,
        secondPitLap,
        weather, // ADD WEATHER PARAMETER
        rainIntensity // ADD RAIN INTENSITY PARAMETER
        );

    // Calculate expected race time
    double expectedRaceTime = _estimateRaceTime(
        track, driver, StrategyType.twoStop, [firstPitLap, secondPitLap]);

    // Generate reasoning
    String reasoning = _getStrategyReasoning(
        track, driver, startPosition, false, viabilityScore);

    return RaceStrategy(
      type: StrategyType.twoStop,
      plannedPitLaps: [firstPitLap, secondPitLap],
      plannedCompounds: plannedCompounds,
      expectedRaceTime: expectedRaceTime,
      reasoning: reasoning,
      viabilityScore: viabilityScore,
    );
  }

  /// Choose optimal tire compounds for one-stop strategy
  /// Choose optimal tire compounds for one-stop strategy with time range analysis
  /// Choose optimal tire compounds for one-stop strategy with weather and time range analysis
  static List<TireCompound> _chooseOneStopCompounds(
      Driver driver,
      Track track,
      int pitLap,
      WeatherCondition weather, // ADD THIS
      RainIntensity? rainIntensity // ADD THIS
      ) {
    TireCompound startingCompound = driver.currentCompound;

    // 🌧️ WEATHER CHECK FIRST - Rain overrides all dry strategy
    if (weather == WeatherCondition.rain) {
      return _chooseWetOneStopCompounds(driver, track, pitLap, rainIntensity);
    }

    // 🌞 DRY WEATHER - Use complex analysis
    // Calculate stint lengths
    int firstStintLength = pitLap;
    int secondStintLength = track.totalLaps - pitLap;
    List<int> stintLengths = [firstStintLength, secondStintLength];

    // Generate all possible one-stop compound strategies
    List<CompoundStrategy> possibleStrategies = _generateOneStopStrategies(
        startingCompound, stintLengths, track.tireDegradationMultiplier);

    if (possibleStrategies.isEmpty) {
      // Fallback to safe strategy
      return [startingCompound, TireCompound.hard];
    }

    // Analyze each strategy's performance with time ranges
    List<StrategyAnalysis> analyzedStrategies = [];
    for (CompoundStrategy strategy in possibleStrategies) {
      StrategyAnalysis analysis =
          _analyzeCompoundStrategy(strategy, stintLengths, driver, track);
      analyzedStrategies.add(analysis);
    }

    // Select the best strategy based on driver/car/track characteristics
    StrategyAnalysis bestStrategy =
        _selectOptimalStrategy(analyzedStrategies, driver, track);

    print("🧠 ONE-STOP ANALYSIS for ${driver.name} (DRY):");
    for (StrategyAnalysis strategy in analyzedStrategies) {
      String compounds = _getCompoundString(strategy.compounds);
      print(
          "   $compounds: ${strategy.bestCaseTime.toStringAsFixed(1)}s - ${strategy.worstCaseTime.toStringAsFixed(1)}s " +
              "(${strategy.expectedTime.toStringAsFixed(1)}s expected)");
    }
    print(
        "   → Chose ${_getCompoundString(bestStrategy.compounds)}: ${bestStrategy.reasoning}");

    return bestStrategy.compounds;
  }

  static String _getCompoundString(List<TireCompound> compounds) {
    return compounds.map((c) => c.name.substring(0, 1).toUpperCase()).join('');
  }

  /// Choose compounds for two-stop strategy in rain conditions
  static List<TireCompound> _chooseWetTwoStopCompounds(Driver driver,
      Track track, int firstPit, int secondPit, RainIntensity? rainIntensity) {
    if (rainIntensity == null) {
      // Fallback if no rain intensity provided
      return [
        TireCompound.intermediate,
        TireCompound.intermediate,
        TireCompound.wet
      ];
    }

    print(
        "🌧️ RAIN TWO-STOP for ${driver.name}: ${rainIntensity.name} (${rainIntensity.description})");

    // Rain intensity-based compound selection
    switch (rainIntensity) {
      case RainIntensity.light:
        // Light rain: Start conservative, might switch to optimal
        print("   Strategy: Conservative start, optimal compound later");
        return [
          driver.currentCompound,
          TireCompound.intermediate,
          TireCompound.intermediate
        ];

      case RainIntensity.moderate:
        // Moderate rain: All optimal compound
        print("   Strategy: Consistent intermediate compounds");
        return [
          TireCompound.intermediate,
          TireCompound.intermediate,
          TireCompound.intermediate
        ];

      case RainIntensity.heavy:
        // Heavy rain: Mix of intermediate and wet
        print("   Strategy: Progressive wet compound strategy");
        return [TireCompound.intermediate, TireCompound.wet, TireCompound.wet];

      case RainIntensity.extreme:
        // Extreme rain: All wet compounds for safety
        print("   Strategy: Full wet compounds for safety");
        return [TireCompound.wet, TireCompound.wet, TireCompound.wet];
    }
  }

  /// Choose compounds for one-stop strategy in rain conditions
  static List<TireCompound> _chooseWetOneStopCompounds(
      Driver driver, Track track, int pitLap, RainIntensity? rainIntensity) {
    if (rainIntensity == null) {
      // Fallback if no rain intensity provided
      return [TireCompound.intermediate, TireCompound.wet];
    }

    print(
        "🌧️ RAIN ONE-STOP for ${driver.name}: ${rainIntensity.name} (${rainIntensity.description})");

    // Rain intensity-based compound selection for longer stints
    switch (rainIntensity) {
      case RainIntensity.light:
        // Light rain: Start intermediate, stay intermediate
        print("   Strategy: Conservative intermediate strategy");
        return [TireCompound.intermediate, TireCompound.intermediate];

      case RainIntensity.moderate:
        // Moderate rain: Intermediate throughout
        print("   Strategy: Intermediate compounds throughout");
        return [TireCompound.intermediate, TireCompound.intermediate];

      case RainIntensity.heavy:
        // Heavy rain: Progress to wet compounds
        print("   Strategy: Start intermediate, switch to wet");
        return [TireCompound.intermediate, TireCompound.wet];

      case RainIntensity.extreme:
        // Extreme rain: Wet compounds for safety
        print("   Strategy: Wet compounds for safety");
        return [TireCompound.wet, TireCompound.wet];
    }
  }

  /// Generate all viable one-stop compound strategies
  static List<CompoundStrategy> _generateOneStopStrategies(
      TireCompound startingCompound,
      List<int> stintLengths,
      double trackMultiplier) {
    List<CompoundStrategy> strategies = [];
    List<TireCompound> dryCompounds = [
      TireCompound.soft,
      TireCompound.medium,
      TireCompound.hard
    ];

    // Generate combinations where first compound matches starting compound
    for (TireCompound second in dryCompounds) {
      List<TireCompound> strategy = [startingCompound, second];

      // Check if strategy is feasible for one-stop stint lengths
      if (_isOneStopStrategyFeasible(strategy, stintLengths, trackMultiplier)) {
        strategies.add(CompoundStrategy(
            compounds: strategy, stintLengths: List.from(stintLengths)));
      }
    }

    return strategies;
  }

  /// Check if one-stop strategy can handle the stint lengths
  static bool _isOneStopStrategyFeasible(List<TireCompound> compounds,
      List<int> stintLengths, double trackMultiplier) {
    for (int i = 0; i < compounds.length; i++) {
      int maxViableLaps =
          _getMaxViableLapsForCompound(compounds[i], trackMultiplier);

      // One-stop strategies need to be more conservative (longer stints)
      int safeLimit =
          (maxViableLaps * 0.90).round(); // 90% of maximum for one-stop

      if (stintLengths[i] > safeLimit) {
        return false;
      }
    }
    return true;
  }

  /// Choose optimal tire compounds for two-stop strategy with time range analysis
  /// Choose optimal tire compounds for two-stop strategy with weather and time range analysis
  static List<TireCompound> _chooseTwoStopCompounds(
      Driver driver,
      Track track,
      int firstPit,
      int secondPit,
      WeatherCondition weather, // ADD THIS
      RainIntensity? rainIntensity // ADD THIS
      ) {
    TireCompound startingCompound = driver.currentCompound;

    // 🌧️ WEATHER CHECK FIRST - Rain overrides all dry strategy
    if (weather == WeatherCondition.rain) {
      return _chooseWetTwoStopCompounds(
          driver, track, firstPit, secondPit, rainIntensity);
    }

    // 🌞 DRY WEATHER - Use complex analysis
    // Calculate stint lengths
    int firstStintLength = firstPit;
    int secondStintLength = secondPit - firstPit;
    int thirdStintLength = track.totalLaps - secondPit;
    List<int> stintLengths = [
      firstStintLength,
      secondStintLength,
      thirdStintLength
    ];

    // Generate all possible compound strategies
    List<CompoundStrategy> possibleStrategies = _generateCompoundStrategies(
        startingCompound, stintLengths, track.tireDegradationMultiplier);

    if (possibleStrategies.isEmpty) {
      // Fallback to safe strategy
      return [startingCompound, TireCompound.medium, TireCompound.hard];
    }

    // Analyze each strategy's performance with time ranges
    List<StrategyAnalysis> analyzedStrategies = [];
    for (CompoundStrategy strategy in possibleStrategies) {
      StrategyAnalysis analysis =
          _analyzeCompoundStrategy(strategy, stintLengths, driver, track);
      analyzedStrategies.add(analysis);
    }

    // Select the best strategy based on driver/car/track characteristics
    StrategyAnalysis bestStrategy =
        _selectOptimalStrategy(analyzedStrategies, driver, track);

    print("🧠 TWO-STOP ANALYSIS for ${driver.name} (DRY):");
    for (StrategyAnalysis strategy in analyzedStrategies) {
      String compounds = _getCompoundString(strategy.compounds);
      print(
          "   $compounds: ${strategy.bestCaseTime.toStringAsFixed(1)}s - ${strategy.worstCaseTime.toStringAsFixed(1)}s " +
              "(${strategy.expectedTime.toStringAsFixed(1)}s expected)");
    }
    print(
        "   → Chose ${_getCompoundString(bestStrategy.compounds)}: ${bestStrategy.reasoning}");

    return bestStrategy.compounds;
  }

  /// Generate all viable compound strategies
  static List<CompoundStrategy> _generateCompoundStrategies(
      TireCompound startingCompound,
      List<int> stintLengths,
      double trackMultiplier) {
    List<CompoundStrategy> strategies = [];
    List<TireCompound> dryCompounds = [
      TireCompound.soft,
      TireCompound.medium,
      TireCompound.hard
    ];

    // Generate combinations where first compound matches starting compound
    for (TireCompound second in dryCompounds) {
      for (TireCompound third in dryCompounds) {
        List<TireCompound> strategy = [startingCompound, second, third];

        // Check if strategy is feasible (compounds can handle stint lengths)
        if (_isCompoundStrategyFeasible(
            strategy, stintLengths, trackMultiplier)) {
          strategies.add(CompoundStrategy(
              compounds: strategy, stintLengths: List.from(stintLengths)));
        }
      }
    }

    return strategies;
  }

  /// Check if compound strategy can handle the stint lengths
  static bool _isCompoundStrategyFeasible(List<TireCompound> compounds,
      List<int> stintLengths, double trackMultiplier) {
    for (int i = 0; i < compounds.length; i++) {
      int maxViableLaps =
          _getMaxViableLapsForCompound(compounds[i], trackMultiplier);
      int safeLimit = (maxViableLaps * 0.85).round(); // 85% of maximum

      if (stintLengths[i] > safeLimit) {
        return false;
      }
    }
    return true;
  }

  /// Analyze the performance of a compound strategy with time ranges
  static StrategyAnalysis _analyzeCompoundStrategy(CompoundStrategy strategy,
      List<int> stintLengths, Driver driver, Track track) {
    // Calculate base expected time
    double expectedTime = 0.0;

    // Calculate tire degradation time for each stint
    for (int i = 0; i < strategy.compounds.length; i++) {
      TireCompound compound = strategy.compounds[i];
      int stintLength = stintLengths[i];

      // Estimate average degradation over the stint (simplified)
      double stintTireTime = _estimateStintTireTime(
          compound, stintLength, track.tireDegradationMultiplier);
      expectedTime += stintTireTime;

      // Add compound delta (soft = faster, hard = slower)
      expectedTime += compound.lapTimeDelta * stintLength;
    }

    // Calculate uncertainty range
    double uncertaintyRange =
        _calculateStrategyUncertainty(strategy, driver, track);

    return StrategyAnalysis(
      compounds: strategy.compounds,
      bestCaseTime: expectedTime - uncertaintyRange,
      expectedTime: expectedTime,
      worstCaseTime: expectedTime + uncertaintyRange,
      uncertaintyRange: uncertaintyRange,
    );
  }

  /// Estimate tire time loss for a complete stint (simplified)
  static double _estimateStintTireTime(
      TireCompound compound, int stintLength, double trackMultiplier) {
    double totalTime = 0.0;

    // Simplified calculation - average degradation over stint
    double avgDegradation =
        stintLength * 0.02 * stintLength; // Quadratic growth
    totalTime = avgDegradation * trackMultiplier;

    return totalTime;
  }

  /// Calculate strategy uncertainty range based on risk factors
  static double _calculateStrategyUncertainty(
      CompoundStrategy strategy, Driver driver, Track track) {
    double baseUncertainty = 2.0; // 2-second base uncertainty

    // Soft compounds = more uncertainty
    int softCount =
        strategy.compounds.where((c) => c == TireCompound.soft).length;
    baseUncertainty += softCount * 1.0;

    // Hard to overtake = more traffic uncertainty
    if (track.overtakingDifficulty <= 0.3) {
      baseUncertainty += 2.0;
    }

    // Inconsistent drivers = more uncertainty
    double consistencyFactor = driver.consistency / 100.0;
    baseUncertainty += (1.0 - consistencyFactor) * 1.5;

    return baseUncertainty.clamp(1.0, 6.0);
  }

  /// Select strategy based on driver/car/track characteristics (no team philosophies)
  static StrategyAnalysis _selectOptimalStrategy(
      List<StrategyAnalysis> strategies, Driver driver, Track track) {
    // Calculate natural risk tolerance
    double riskTolerance = _calculateNaturalRiskTolerance(driver, track);

    if (riskTolerance >= 0.7) {
      // High risk tolerance: focus on best case
      strategies.sort((a, b) => a.bestCaseTime.compareTo(b.bestCaseTime));
      strategies.first.reasoning = "High risk approach - targeting best case";
      return strategies.first;
    } else if (riskTolerance <= 0.3) {
      // Low risk tolerance: focus on worst case
      strategies.sort((a, b) => a.worstCaseTime.compareTo(b.worstCaseTime));
      strategies.first.reasoning = "Conservative approach - minimizing risk";
      return strategies.first;
    } else {
      // Balanced: focus on expected time
      strategies.sort((a, b) => a.expectedTime.compareTo(b.expectedTime));
      strategies.first.reasoning = "Balanced approach - best expected time";
      return strategies.first;
    }
  }

  /// Calculate natural risk tolerance based on driver/car/track
  static double _calculateNaturalRiskTolerance(Driver driver, Track track) {
    double riskTolerance = 0.5;

    // Elite drivers + good cars = more willing to take risks
    if (driver.speed >= 90 && driver.team.carPerformance >= 90) {
      riskTolerance += 0.2;
    }

    // Bad cars = must take strategic risks
    if (driver.team.carPerformance <= 75) {
      riskTolerance += 0.15;
    }

    // Back of grid = desperate for strategy
    if (driver.startingPosition >= 15) {
      riskTolerance += 0.15;
    }

    // Hard to overtake tracks = strategy is crucial
    if (track.overtakingDifficulty <= 0.3) {
      riskTolerance += 0.2;
    }

    return riskTolerance.clamp(0.0, 1.0);
  }

  /// Rough estimation of race time for strategy comparison
  static double _estimateRaceTime(Track track, Driver driver,
      StrategyType strategyType, List<int> pitLaps) {
    // Base race time calculation
    double baseTime = track.baseLapTime * track.totalLaps;

    // Add pit stop time penalties
    int pitStops = pitLaps.length;
    double pitPenalty = pitStops *
        (25.0 + track.pitStopTimePenalty); // ~25 seconds per pit stop

    // Tire degradation penalty (simplified)
    double tirePenalty = 0.0;
    if (strategyType == StrategyType.oneStop) {
      // One-stop has more tire degradation in final stint
      tirePenalty =
          track.tireDegradationMultiplier * 15.0; // ~15 seconds penalty
    } else {
      // Two-stop has fresher tires but more pit stops
      tirePenalty = track.tireDegradationMultiplier * 8.0; // ~8 seconds penalty
    }

    // Driver/team performance modifier
    double performanceModifier =
        (100.0 - driver.team.carPerformance) / 100.0 * baseTime * 0.1;

    return baseTime + pitPenalty + tirePenalty + performanceModifier;
  }

  /// Get strategy reasoning based on scores and factors
  static String _getStrategyReasoning(Track track, Driver driver,
      int startPosition, bool isOneStop, double score) {
    List<String> reasons = [];

    // Track factors
    if (track.overtakingDifficulty <= 0.3) {
      reasons.add("Hard to overtake");
    } else if (track.overtakingDifficulty >= 0.7) {
      reasons.add("Easy overtaking");
    }

    if (track.tireDegradationMultiplier >= 1.3) {
      reasons.add("High tire wear");
    } else if (track.tireDegradationMultiplier <= 0.9) {
      reasons.add("Low tire wear");
    }

    if (track.favorsTwoStop) {
      reasons.add("Track favors two-stop");
    }

    // Position factors
    if (startPosition <= 3) {
      reasons.add("Protect track position");
    } else if (startPosition >= 15) {
      reasons.add("Strategic gamble from back");
    } else if (startPosition >= 6 && startPosition <= 10) {
      reasons.add("Midfield opportunity");
    }

    // Driver factors
    if (driver.tyreManagementSkill >= 85) {
      reasons.add("Excellent tire management");
    } else if (driver.speed >= 90) {
      reasons.add("High speed can exploit fresh tires");
    }

    // Team factors
    if (driver.team.carPerformance <= 78) {
      reasons.add("Strategy is main weapon");
    } else if (driver.team.carPerformance >= 95) {
      reasons.add("Car can recover positions");
    }

    String baseReason = isOneStop ? "One-stop" : "Two-stop";
    if (reasons.isEmpty) {
      return "$baseReason strategy (balanced factors)";
    } else {
      return "$baseReason: ${reasons.take(2).join(', ')}"; // Limit to 2 main reasons
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STRATEGIC PIT TIMING FUNCTIONS (Enhanced During-Race Logic)
  // ═══════════════════════════════════════════════════════════════

  /// Enhanced pit stop decision making with strategic planning integration
  static bool shouldPitStop(Driver driver, int currentLap, int totalLaps,
      double gapBehind, double gapAhead, Track track) {
    // SAFETY CONSTRAINTS FIRST (prevent unrealistic decisions)
    if (currentLap < F1Constants.minLapsBeforePit) return false;
    if (driver.pitStops >= F1Constants.maxPitStops) return false;
    if (driver.lapsOnCurrentTires < F1Constants.minLapsForPit) return false;
    if (currentLap > totalLaps - F1Constants.lastLapsToPit) return false;

    // CHECK STRATEGIC PIT WINDOW FIRST (if driver has a planned strategy)
    if (driver.raceStrategy != null && !driver.raceStrategy!.isAbandoned) {
      bool strategicDecision =
          _checkStrategicPitWindow(driver, currentLap, totalLaps, track);
      if (strategicDecision) return true;
    }

    // FALL BACK TO EMERGENCY/REACTIVE PIT LOGIC
    return _shouldPitEmergency(
        driver, currentLap, totalLaps, gapBehind, gapAhead, track);
  }

  /// Check if driver should pit based on planned strategy
  static bool _checkStrategicPitWindow(
      Driver driver, int currentLap, int totalLaps, Track track) {
    RaceStrategy strategy = driver.raceStrategy!;

    // Get next planned pit lap
    int? nextPitLap = strategy.nextPlannedPitLap;
    if (nextPitLap == null) return false; // No more planned stops

    // Strategic pit window: ±4 laps around planned pit lap
    int windowStart = nextPitLap - 4;
    int windowEnd = nextPitLap + 4;

    if (currentLap >= windowStart && currentLap <= windowEnd) {
      double degradation = driver.calculateTyreDegradation();
      double trackAdjustedDegradation =
          degradation * track.tireDegradationMultiplier;

      // Within strategic window - check if conditions are right

      // 1. If we're at the planned lap exactly, pit (unless conditions are terrible)
      if (currentLap == nextPitLap) {
        return trackAdjustedDegradation >
            0.3; // Only avoid if tires are very fresh
      }

      // 2. If we're past planned lap, increasing urgency
      if (currentLap > nextPitLap) {
        double urgency = (currentLap - nextPitLap) / 4.0; // 0.0 to 1.0
        double urgencyThreshold =
            0.4 - (urgency * 0.2); // Gets easier as we get later
        return trackAdjustedDegradation > urgencyThreshold;
      }

      // 3. If we're before planned lap, only pit if tires are getting bad
      if (currentLap < nextPitLap) {
        double conservativeThreshold =
            _getConservativeThreshold(driver.currentCompound);
        return trackAdjustedDegradation > conservativeThreshold;
      }
    }

    return false;
  }

  /// Emergency/reactive pit logic (original logic but cleaner)
  static bool _shouldPitEmergency(Driver driver, int currentLap, int totalLaps,
      double gapBehind, double gapAhead, Track track) {
    double currentDegradation = driver.calculateTyreDegradation();
    double trackAdjustedDegradation =
        currentDegradation * track.tireDegradationMultiplier;

    // MANDATORY PIT STOP: Must pit at least once
    bool mustPitSoon = driver.pitStops == 0 &&
        currentLap >= totalLaps - F1Constants.lastMandatoryPitLaps;

    // MANDATORY COMPOUND CHANGE: Must use different compound if only used one type
    bool mustChangeCompound =
        _mustUseSecondCompound(driver, currentLap, totalLaps);

    // Compound-specific emergency thresholds
    double emergencyThreshold = _getEmergencyThreshold(driver.currentCompound);
    double conservativeThreshold =
        _getConservativeThreshold(driver.currentCompound);

    // EMERGENCY: Tire degradation is killing pace
    if (trackAdjustedDegradation > emergencyThreshold) {
      return true;
    }

    // CLIFF WARNING: Approaching tire performance cliff AND degradation is already bad
    if (driver.isApproachingTireCliff() &&
        trackAdjustedDegradation > (conservativeThreshold * 1.2)) {
      return true;
    }

    // MANDATORY COMPOUND RULE: Force pit if must change compound and running out of time
    if (mustChangeCompound && currentLap >= totalLaps - 15) {
      return true;
    }

    // MANDATORY PIT: Force pit stop if really running out of time
    if (mustPitSoon) return true;

    return false;
  }

  // ═══════════════════════════════════════════════════════════════
  // THRESHOLD CALCULATION FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  static double _getEmergencyThreshold(TireCompound compound) {
    switch (compound) {
      case TireCompound.soft:
        return F1Constants.softEmergencyThreshold *
            1.1; // 1.32s instead of 1.2s
      case TireCompound.medium:
        return F1Constants.mediumEmergencyThreshold *
            1.1; // 1.65s instead of 1.5s
      case TireCompound.hard:
        return F1Constants.hardEmergencyThreshold * 1.1; // 2.2s instead of 2.0s
      case TireCompound.intermediate:
        return 2.0;
      case TireCompound.wet:
        return 2.4;
    }
  }

  static double _getConservativeThreshold(TireCompound compound) {
    switch (compound) {
      case TireCompound.soft:
        return F1Constants.softConservativeThreshold *
            1.5; // 0.6s instead of 0.4s
      case TireCompound.medium:
        return F1Constants.mediumConservativeThreshold *
            1.5; // 0.75s instead of 0.5s
      case TireCompound.hard:
        return F1Constants.hardConservativeThreshold *
            1.5; // 1.05s instead of 0.7s
      case TireCompound.intermediate:
        return 0.9;
      case TireCompound.wet:
        return 1.2;
    }
  }

  /// Checks if driver must use a second compound type
  static bool _mustUseSecondCompound(
      Driver driver, int currentLap, int totalLaps) {
    // Rule doesn't apply in wet conditions
    if (driver.currentCompound == TireCompound.intermediate ||
        driver.currentCompound == TireCompound.wet) {
      return false;
    }

    // Get dry compounds already used
    List<TireCompound> dryCompoundsUsed = driver.usedCompounds
        .where((compound) =>
            compound == TireCompound.soft ||
            compound == TireCompound.medium ||
            compound == TireCompound.hard)
        .toSet()
        .toList();

    // Add current compound if not already tracked
    if (!dryCompoundsUsed.contains(driver.currentCompound) &&
        (driver.currentCompound == TireCompound.soft ||
            driver.currentCompound == TireCompound.medium ||
            driver.currentCompound == TireCompound.hard)) {
      dryCompoundsUsed.add(driver.currentCompound);
    }

    // Must use second compound if only used one type and race is progressing
    return dryCompoundsUsed.length == 1 &&
        currentLap >= (totalLaps * 0.4); // 40% of race distance
  }

  // ═══════════════════════════════════════════════════════════════
  // COMPOUND SELECTION FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  static TireCompound selectCompoundDynamic(
      Driver driver,
      WeatherCondition weather,
      int currentLap,
      int totalLaps,
      double gapAhead,
      double gapBehind,
      Track track) {
    // WEATHER FIRST (mandatory)
    if (weather == WeatherCondition.rain) {
      return TireCompound.intermediate;
    }

    // STRATEGIC COMPOUND SELECTION (if driver has planned strategy)
    if (driver.raceStrategy != null && !driver.raceStrategy!.isAbandoned) {
      TireCompound? plannedCompound = driver.raceStrategy!.nextPlannedCompound;
      if (plannedCompound != null) {
        return plannedCompound; // Follow the strategic plan
      }
    }

    // FALL BACK TO DYNAMIC SELECTION (original logic but streamlined)
    List<TireCompound> availableCompounds =
        _getAvailableCompounds(driver, weather);
    if (availableCompounds.isEmpty) {
      return TireCompound.medium; // Safety fallback
    }

    int estimatedStintLength =
        _estimateRemainingStintLength(currentLap, totalLaps, driver.pitStops);
    List<TireCompound> feasibleCompounds = _filterFeasibleCompounds(
        availableCompounds,
        estimatedStintLength,
        track.tireDegradationMultiplier);

    if (feasibleCompounds.isEmpty) {
      feasibleCompounds = availableCompounds;
    }

    if (feasibleCompounds.length == 1) {
      return feasibleCompounds.first;
    }

    // Apply probability system for multiple choices
    TireCompound optimalCompound = _selectOptimalCompoundForStint(
        feasibleCompounds,
        estimatedStintLength,
        track.tireDegradationMultiplier);
    Map<TireCompound, double> compoundProbabilities = {};

    for (TireCompound compound in feasibleCompounds) {
      double probability = compound == optimalCompound ? 0.7 : 0.3;
      probability *= _getSkillMultiplier(driver, compound);
      probability *= _getPerformancePressureMultiplier(driver, compound);
      probability *= _getTeamStrategyMultiplier(driver, compound);
      probability *= _getRandomDecisionMultiplier();
      probability *= _getCompoundHistoryMultiplier(driver, compound);

      compoundProbabilities[compound] = probability;
    }

    return _selectFromWeightedProbabilities(compoundProbabilities);
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITY FUNCTIONS (Existing logic - kept for compatibility)
  // ═══════════════════════════════════════════════════════════════

  static List<TireCompound> _filterFeasibleCompounds(
      List<TireCompound> available, int stintLength, double trackMultiplier) {
    List<TireCompound> feasible = [];
    for (TireCompound compound in available) {
      int maxViableLaps =
          _getMaxViableLapsForCompound(compound, trackMultiplier);
      if (stintLength <= maxViableLaps) {
        feasible.add(compound);
      }
    }
    return feasible;
  }

  static int _getMaxViableLapsForCompound(
      TireCompound compound, double trackMultiplier) {
    int baseCliff;
    switch (compound) {
      case TireCompound.soft:
        baseCliff = 15;
        break;
      case TireCompound.medium:
        baseCliff = 25;
        break;
      case TireCompound.hard:
        baseCliff = 40;
        break;
      case TireCompound.intermediate:
        baseCliff = 20;
        break;
      case TireCompound.wet:
        baseCliff = 15;
        break;
    }

    int adjustedCliff = (baseCliff / trackMultiplier).round();
    return adjustedCliff + 3;
  }

  static int _estimateRemainingStintLength(
      int currentLap, int totalLaps, int pitStops) {
    int remainingLaps = totalLaps - currentLap;

    if (pitStops == 0) {
      if (remainingLaps <= 20) {
        return remainingLaps;
      } else {
        return remainingLaps ~/ 2;
      }
    } else if (pitStops == 1) {
      if (remainingLaps <= 35) {
        return remainingLaps;
      } else {
        return remainingLaps ~/ 2;
      }
    } else {
      return remainingLaps;
    }
  }

  static TireCompound _selectOptimalCompoundForStint(
      List<TireCompound> available, int stintLength, double trackMultiplier) {
    int softLimit =
        _getMaxViableLapsForCompound(TireCompound.soft, trackMultiplier) - 2;
    int mediumLimit =
        _getMaxViableLapsForCompound(TireCompound.medium, trackMultiplier) - 2;

    if (stintLength <= softLimit && available.contains(TireCompound.soft)) {
      return TireCompound.soft;
    } else if (stintLength <= mediumLimit &&
        available.contains(TireCompound.medium)) {
      return TireCompound.medium;
    } else if (available.contains(TireCompound.hard)) {
      return TireCompound.hard;
    }

    if (available.contains(TireCompound.intermediate)) {
      return TireCompound.intermediate;
    }
    if (available.contains(TireCompound.wet)) {
      return TireCompound.wet;
    }

    return available.first;
  }

  static List<TireCompound> _getAvailableCompounds(
      Driver driver, WeatherCondition weather) {
    if (weather == WeatherCondition.rain) {
      return [TireCompound.intermediate, TireCompound.wet];
    }

    List<TireCompound> allDryCompounds = [
      TireCompound.soft,
      TireCompound.medium,
      TireCompound.hard
    ];
    List<TireCompound> dryCompoundsUsed = driver.usedCompounds
        .where((compound) => allDryCompounds.contains(compound))
        .toSet()
        .toList();

    if (!dryCompoundsUsed.contains(driver.currentCompound) &&
        allDryCompounds.contains(driver.currentCompound)) {
      dryCompoundsUsed.add(driver.currentCompound);
    }

    if (dryCompoundsUsed.length == 1) {
      return allDryCompounds
          .where((compound) => !dryCompoundsUsed.contains(compound))
          .toList();
    }

    return allDryCompounds;
  }

  static double _getSkillMultiplier(Driver driver, TireCompound compound) {
    double multiplier = 1.0;

    if (driver.speed > 90) {
      if (compound == TireCompound.soft) multiplier *= 1.2;
      if (compound == TireCompound.hard) multiplier *= 0.9;
    }

    if (driver.consistency > 85) {
      if (compound == TireCompound.medium || compound == TireCompound.hard)
        multiplier *= 1.15;
      if (compound == TireCompound.soft) multiplier *= 0.9;
    }

    if (driver.tyreManagementSkill > 85) {
      if (compound == TireCompound.hard) multiplier *= 1.2;
      if (compound == TireCompound.soft) multiplier *= 0.95;
    }

    if (driver.speed < 70 || driver.consistency < 60) {
      multiplier *= 0.9 + (Random().nextDouble() * 0.2);
    }

    return multiplier;
  }

  static double _getPerformancePressureMultiplier(
      Driver driver, TireCompound compound) {
    double multiplier = 1.0;
    int performanceDelta = driver.position - driver.startingPosition;

    if (performanceDelta > 2) {
      if (compound == TireCompound.soft) multiplier *= 1.15;
      if (compound == TireCompound.hard) multiplier *= 0.9;
    } else if (performanceDelta < -2) {
      if (compound == TireCompound.soft) multiplier *= 0.9;
      if (compound == TireCompound.hard) multiplier *= 1.1;
    }

    if (driver.errorCount > 0) {
      double desperationFactor = 1.0 + (driver.errorCount * 0.05);
      if (compound == TireCompound.soft) multiplier *= desperationFactor;
    }

    return multiplier;
  }

  static double _getTeamStrategyMultiplier(
      Driver driver, TireCompound compound) {
    double multiplier = 1.0;

    if (driver.carPerformance > 90) {
      if (compound == TireCompound.soft) multiplier *= 1.1;
    }

    if (driver.team.reliability < 80) {
      if (compound == TireCompound.hard) multiplier *= 1.15;
      if (compound == TireCompound.soft) multiplier *= 0.9;
    }

    String teamStrategy = driver.getTeamStrategyTendency();
    switch (teamStrategy) {
      case "aggressive":
        if (compound == TireCompound.soft) multiplier *= 1.1;
        break;
      case "conservative":
        if (compound == TireCompound.hard) multiplier *= 1.1;
        break;
      case "balanced":
      default:
        if (compound == TireCompound.medium) multiplier *= 1.05;
        break;
    }

    return multiplier;
  }

  static double _getRandomDecisionMultiplier() {
    return 0.925 + (Random().nextDouble() * 0.15);
  }

  static double _getCompoundHistoryMultiplier(
      Driver driver, TireCompound compound) {
    double multiplier = 1.0;
    int timesUsed = driver.usedCompounds.where((c) => c == compound).length;

    if (timesUsed > 1) {
      multiplier *= 1.02;
    } else if (timesUsed == 0) {
      multiplier *= 0.98;
    }

    return multiplier;
  }

  static TireCompound _selectFromWeightedProbabilities(
      Map<TireCompound, double> probabilities) {
    double totalWeight = probabilities.values.reduce((a, b) => a + b);
    double random = Random().nextDouble() * totalWeight;
    double cumulative = 0.0;

    for (MapEntry<TireCompound, double> entry in probabilities.entries) {
      cumulative += entry.value;
      if (random <= cumulative) {
        return entry.key;
      }
    }

    return probabilities.keys.first;
  }

  // ═══════════════════════════════════════════════════════════════
  // PIT STOP EXECUTION FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  static void executePitStop(
      Driver driver,
      WeatherCondition weather,
      int currentLap,
      int totalLaps,
      double gapAhead,
      double gapBehind,
      Track track) {
    driver.pitStops++;
    driver.lapsOnCurrentTires = 0;

    // Track old compound usage
    if (!driver.usedCompounds.contains(driver.currentCompound)) {
      driver.usedCompounds.add(driver.currentCompound);
    }

    // Update strategic progress
    if (driver.raceStrategy != null && !driver.raceStrategy!.isAbandoned) {
      driver.raceStrategy = driver.raceStrategy!.copyWith(
        currentPitStop: driver.raceStrategy!.currentPitStop + 1,
      );
    }

    TireCompound oldCompound = driver.currentCompound;
    driver.currentCompound = selectCompoundDynamic(
        driver, weather, currentLap, totalLaps, gapAhead, gapBehind, track);

    double pitTime = calculatePitStopTime(driver, track);

    if (oldCompound != driver.currentCompound) {
      pitTime += 0.5;
    }

    driver.totalTime += pitTime;

    // Log the pit stop
    double maxNormalTime = 27.0 + track.pitStopTimePenalty;
    double minNormalTime = 22.0;
    String stopType = pitTime < minNormalTime || pitTime > maxNormalTime
        ? " (EXCEPTIONAL)"
        : " (normal)";
    String compoundChange = oldCompound == driver.currentCompound
        ? "${driver.currentCompound.name}"
        : "${oldCompound.name} → ${driver.currentCompound.name}";

    String ruleInfo = _mustUseSecondCompound(driver, currentLap, totalLaps)
        ? " [MANDATORY]"
        : "";

    String incident =
        "Lap ${driver.lapsCompleted + 1}: Pit stop - $compoundChange (${pitTime.toStringAsFixed(1)}s$stopType)$ruleInfo";
    driver.recordIncident(incident);
  }

  static double calculatePitStopTime(Driver driver, Track track) {
    double performanceRange = 98.0 - 72.0;
    double teamEfficiencyFactor =
        (driver.team.carPerformance - 72.0) / performanceRange;
    double baseTime = F1Constants.maxPitTime -
        (teamEfficiencyFactor *
            (F1Constants.maxPitTime - F1Constants.minPitTime));

    baseTime *= driver.team.pitStopSpeed;

    bool isExceptionalStop =
        Random().nextDouble() < F1Constants.exceptionalPitChance;

    if (isExceptionalStop) {
      double performanceFactor = driver.team.carPerformance / 100.0;
      double exceptionRange = F1Constants.exceptionalPitVariation;
      double bias = (performanceFactor - 0.72) / 0.26;

      double biasedRandom =
          (Random().nextDouble() - 0.5 + (bias - 0.5) * 0.6) * 2;
      double exceptionalVariation = biasedRandom * exceptionRange;

      double finalTime = baseTime + exceptionalVariation;
      finalTime += track.pitStopTimePenalty;
      return finalTime.clamp(18.0, 32.0 + track.pitStopTimePenalty);
    } else {
      double normalVariation =
          (Random().nextDouble() * F1Constants.normalPitVariation * 2) -
              F1Constants.normalPitVariation;
      double finalTime = baseTime + normalVariation;
      finalTime += track.pitStopTimePenalty;
      return finalTime.clamp(22.0, 27.0 + track.pitStopTimePenalty);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITY FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  static String getMandatoryCompoundStatus(Driver driver) {
    List<TireCompound> dryCompoundsUsed = driver.usedCompounds
        .where((compound) =>
            compound == TireCompound.soft ||
            compound == TireCompound.medium ||
            compound == TireCompound.hard)
        .toSet()
        .toList();

    if (!dryCompoundsUsed.contains(driver.currentCompound) &&
        (driver.currentCompound == TireCompound.soft ||
            driver.currentCompound == TireCompound.medium ||
            driver.currentCompound == TireCompound.hard)) {
      dryCompoundsUsed.add(driver.currentCompound);
    }

    if (dryCompoundsUsed.length >= 2) {
      return "✅ Rule satisfied";
    } else if (dryCompoundsUsed.length == 1) {
      return "⚠️ Must use 2nd compound";
    } else {
      return "🔄 No compounds used yet";
    }
  }
}
