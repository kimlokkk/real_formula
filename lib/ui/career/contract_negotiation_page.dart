// lib/ui/career/contract_negotiation_page.dart
import 'package:flutter/material.dart';
import 'package:real_formula/models/career/contract.dart';
import 'package:real_formula/services/career/career_manager.dart';
import '../../models/career/career_driver.dart';

class ContractNegotiationPage extends StatefulWidget {
  @override
  _ContractNegotiationPageState createState() => _ContractNegotiationPageState();
}

class _ContractNegotiationPageState extends State<ContractNegotiationPage> with TickerProviderStateMixin {
  List<ContractOffer> availableOffers = [];
  ContractOffer? selectedOffer;
  ContractOffer? counterOffer;
  bool isLoading = true;
  bool isNegotiating = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _slideController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 1.0),
      end: Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _loadOffers();
  }

  void _loadOffers() async {
    // Simulate loading delay
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      availableOffers = CareerManager.generateContractOffers();
      isLoading = false;
    });

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: isLoading ? _buildLoadingScreen() : _buildNegotiationInterface(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.red[600],
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'F1',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'CONTRACT NEGOTIATIONS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'GENERATING CONTRACT OFFERS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Teams are evaluating your performance...',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiationInterface() {
    if (availableOffers.isEmpty) {
      return _buildNoOffersScreen();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          _buildDriverStatus(),
          _buildOffersHeader(),
          Expanded(
            child: _buildOffersList(),
          ),
          if (selectedOffer != null) _buildNegotiationPanel(),
        ],
      ),
    );
  }

  Widget _buildNoOffersScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied,
            size: 80,
            color: Colors.grey[600],
          ),
          SizedBox(height: 24),
          Text(
            'NO CONTRACT OFFERS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Your reputation needs improvement\nbefore teams will make offers.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text('RETURN TO CAREER'),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverStatus() {
    CareerDriver? driver = CareerManager.currentCareerDriver;
    if (driver == null) return Container();

    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: driver.team.primaryColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                driver.abbreviation,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Season ${CareerManager.currentSeason} • Rating: ${driver.careerRating.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Wins: ${driver.careerWins} • Podiums: ${driver.careerPodiums} • Points: ${driver.careerPoints}',
                  style: TextStyle(
                    color: Colors.orange[300],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[600],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'FREE AGENT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(
          bottom: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.description, color: Colors.blue, size: 20),
          SizedBox(width: 8),
          Text(
            'CONTRACT OFFERS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Spacer(),
          Text(
            '${availableOffers.length} OFFER${availableOffers.length != 1 ? 'S' : ''}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersList() {
    return ListView.builder(
      itemCount: availableOffers.length,
      itemBuilder: (context, index) {
        ContractOffer offer = availableOffers[index];
        bool isSelected = selectedOffer == offer;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedOffer = isSelected ? null : offer;
              counterOffer = null;
            });
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[600]!.withOpacity(0.2) : Colors.grey[850],
              border: Border.all(
                color: isSelected ? Colors.blue[600]! : Colors.grey[700]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Team logo
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: offer.team.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          offer.team.name.substring(0, 2).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),

                    // Offer details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.team.name.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${offer.team.performanceTier} • ${offer.team.reliabilityTier}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '€${offer.salaryPerYear.toStringAsFixed(1)}M per year',
                            style: TextStyle(
                              color: Colors.green[300],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contract terms
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${offer.lengthInYears} YEAR${offer.lengthInYears > 1 ? 'S' : ''}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total: €${offer.totalValue.toStringAsFixed(1)}M',
                          style: TextStyle(
                            color: Colors.orange[300],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Expires: ${offer.daysUntilExpiration}d',
                          style: TextStyle(
                            color: offer.daysUntilExpiration <= 3 ? Colors.red[300] : Colors.grey[400],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isSelected) ...[
                  SizedBox(height: 16),
                  _buildOfferDetails(offer),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOfferDetails(ContractOffer offer) {
    CareerDriver? driver = CareerManager.currentCareerDriver;
    if (driver == null) return Container();

    int reputation = driver.getTeamReputation(offer.team.name);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OFFER DETAILS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Team Performance', '${offer.team.carPerformance}/100'),
                    _buildDetailRow('Reliability', '${offer.team.reliability}/100'),
                    _buildDetailRow('Your Reputation', '$reputation/100'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Annual Salary', '€${offer.salaryPerYear.toStringAsFixed(1)}M'),
                    _buildDetailRow(
                        'Contract Length', '${offer.lengthInYears} year${offer.lengthInYears > 1 ? 's' : ''}'),
                    _buildDetailRow('Total Value', '€${offer.totalValue.toStringAsFixed(1)}M'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 10),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiationPanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(
          top: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEGOTIATION OPTIONS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptOffer(selectedOffer!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 20),
                      SizedBox(width: 8),
                      Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isNegotiating ? null : () => _counterOffer(selectedOffer!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.handshake, size: 20),
                      SizedBox(width: 8),
                      Text('NEGOTIATE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _rejectOffer(selectedOffer!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 20),
                      SizedBox(width: 8),
                      Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _acceptOffer(ContractOffer offer) {
    bool success = CareerManager.acceptContractOffer(offer);

    if (success) {
      _showResultDialog(
        title: 'CONTRACT SIGNED!',
        message: 'Welcome to ${offer.team.name}!\n\n'
            'You have signed a ${offer.lengthInYears}-year contract worth €${offer.totalValue.toStringAsFixed(1)}M.',
        isSuccess: true,
      );
    } else {
      _showResultDialog(
        title: 'CONTRACT FAILED',
        message: 'There was an error processing your contract.',
        isSuccess: false,
      );
    }
  }

  void _counterOffer(ContractOffer offer) {
    setState(() {
      isNegotiating = true;
    });

    // Simple counter-offer logic: ask for +20% salary
    double counterSalary = offer.salaryPerYear * 1.2;

    // Simulate negotiation delay
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        isNegotiating = false;
      });

      // Simple success/failure based on reputation
      CareerDriver? driver = CareerManager.currentCareerDriver;
      if (driver != null) {
        int reputation = driver.getTeamReputation(offer.team.name);
        bool negotiationSuccess = reputation >= 70; // Need good reputation to negotiate

        if (negotiationSuccess) {
          // Create improved offer
          counterOffer = ContractOffer(
            team: offer.team,
            lengthInYears: offer.lengthInYears,
            salaryPerYear: counterSalary.clamp(offer.salaryPerYear, offer.salaryPerYear * 1.3),
            forYear: offer.forYear,
            offerExpirationDate: offer.offerExpirationDate,
          );

          _showResultDialog(
            title: 'COUNTER-OFFER ACCEPTED!',
            message: '${offer.team.name} has agreed to improve their offer!\n\n'
                'New salary: €${counterOffer!.salaryPerYear.toStringAsFixed(1)}M per year',
            isSuccess: true,
          );
        } else {
          _showResultDialog(
            title: 'NEGOTIATION FAILED',
            message: '${offer.team.name} rejected your counter-offer.\n\n'
                'Your reputation with this team may not be high enough.',
            isSuccess: false,
          );
        }
      }
    });
  }

  void _rejectOffer(ContractOffer offer) {
    offer.reject();

    setState(() {
      availableOffers.remove(offer);
      if (selectedOffer == offer) {
        selectedOffer = null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rejected offer from ${offer.team.name}'),
        backgroundColor: Colors.red[600],
      ),
    );
  }

  void _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isSuccess) {
                  Navigator.of(context).pop(); // Return to career home
                }
              },
              child: Text(
                'CONTINUE',
                style: TextStyle(
                  color: isSuccess ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
