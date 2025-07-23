// lib/models/career/contract.dart
import '../team.dart';

enum ContractStatus {
  active,
  expired,
  terminated,
}

class Contract {
  final Team team;
  final int lengthInYears;
  final double salaryPerYear; // In millions (e.g., 5.0 = €5M per year)
  final int startYear;
  ContractStatus status;

  Contract({
    required this.team,
    required this.lengthInYears,
    required this.salaryPerYear,
    required this.startYear,
    this.status = ContractStatus.active,
  });

  // Calculate which year of the contract we're in
  int getContractYear(int currentYear) {
    return (currentYear - startYear) + 1;
  }

  // Check if contract is still valid for given year
  bool isValidForYear(int currentYear) {
    if (status != ContractStatus.active) return false;
    return currentYear >= startYear && currentYear < (startYear + lengthInYears);
  }

  // Check if this is the final year of the contract
  bool isFinalYear(int currentYear) {
    return isValidForYear(currentYear) && (currentYear == startYear + lengthInYears - 1);
  }

  // Get remaining years on contract
  int getRemainingYears(int currentYear) {
    if (!isValidForYear(currentYear)) return 0;
    return (startYear + lengthInYears) - currentYear;
  }

  // Contract summary for display
  String get contractSummary {
    return "${lengthInYears} year${lengthInYears > 1 ? 's' : ''} • €${salaryPerYear.toStringAsFixed(1)}M/year";
  }

  // Total contract value
  double get totalValue {
    return salaryPerYear * lengthInYears;
  }

  // Contract description for UI
  String getContractDescription(int currentYear) {
    if (!isValidForYear(currentYear)) {
      return "Contract expired";
    }

    int year = getContractYear(currentYear);
    int remaining = getRemainingYears(currentYear);

    return "Year $year of $lengthInYears • $remaining year${remaining != 1 ? 's' : ''} remaining";
  }

  // Expire the contract
  void expire() {
    status = ContractStatus.expired;
  }

  // Terminate the contract early
  void terminate() {
    status = ContractStatus.terminated;
  }

  // JSON serialization for save system
  Map<String, dynamic> toJson() {
    return {
      'teamName': team.name,
      'lengthInYears': lengthInYears,
      'salaryPerYear': salaryPerYear,
      'startYear': startYear,
      'status': status.name,
    };
  }

  // Create Contract from JSON
  static Contract fromJson(Map<String, dynamic> json, Team team) {
    return Contract(
      team: team,
      lengthInYears: json['lengthInYears'],
      salaryPerYear: json['salaryPerYear'],
      startYear: json['startYear'],
      status: ContractStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ContractStatus.active,
      ),
    );
  }

  @override
  String toString() {
    return 'Contract(${team.name}, ${lengthInYears}y, €${salaryPerYear}M, $status)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contract &&
          runtimeType == other.runtimeType &&
          team == other.team &&
          lengthInYears == other.lengthInYears &&
          salaryPerYear == other.salaryPerYear &&
          startYear == other.startYear;

  @override
  int get hashCode => team.hashCode ^ lengthInYears.hashCode ^ salaryPerYear.hashCode ^ startYear.hashCode;
}

// Contract offer class for negotiations
class ContractOffer {
  final Team team;
  final int lengthInYears;
  final double salaryPerYear;
  final int forYear; // Which year this offer is for
  final DateTime offerExpirationDate;
  bool isAccepted;
  bool isRejected;

  ContractOffer({
    required this.team,
    required this.lengthInYears,
    required this.salaryPerYear,
    required this.forYear,
    required this.offerExpirationDate,
    this.isAccepted = false,
    this.isRejected = false,
  });

  // ADD this getter:
  double get totalValue {
    return salaryPerYear * lengthInYears;
  }

  // Check if offer is still valid
  bool get isValid {
    return !isAccepted && !isRejected && DateTime.now().isBefore(offerExpirationDate);
  }

  // Accept the offer
  void accept() {
    isAccepted = true;
    isRejected = false;
  }

  // Reject the offer
  void reject() {
    isRejected = true;
    isAccepted = false;
  }

  // Offer summary for UI
  String get offerSummary {
    return "${team.name} • ${lengthInYears} year${lengthInYears > 1 ? 's' : ''} • €${salaryPerYear.toStringAsFixed(1)}M/year";
  }

  // Days until offer expires
  int get daysUntilExpiration {
    return offerExpirationDate.difference(DateTime.now()).inDays;
  }

  // Convert contract offer to actual contract
  Contract toContract() {
    return Contract(
      team: team,
      lengthInYears: lengthInYears,
      salaryPerYear: salaryPerYear,
      startYear: forYear,
      status: ContractStatus.active,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'teamName': team.name,
      'lengthInYears': lengthInYears,
      'salaryPerYear': salaryPerYear,
      'forYear': forYear,
      'offerExpirationDate': offerExpirationDate.toIso8601String(),
      'isAccepted': isAccepted,
      'isRejected': isRejected,
    };
  }

  // Create ContractOffer from JSON
  static ContractOffer fromJson(Map<String, dynamic> json, Team team) {
    return ContractOffer(
      team: team,
      lengthInYears: json['lengthInYears'],
      salaryPerYear: json['salaryPerYear'],
      forYear: json['forYear'],
      offerExpirationDate: DateTime.parse(json['offerExpirationDate']),
      isAccepted: json['isAccepted'] ?? false,
      isRejected: json['isRejected'] ?? false,
    );
  }

  @override
  String toString() {
    return 'ContractOffer(${team.name}, ${lengthInYears}y, €${salaryPerYear}M, expires: ${daysUntilExpiration}d)';
  }
}
