// lib/ui/career/save_load_menu.dart - F1-Themed to match main menu
import 'package:flutter/material.dart';
import '../../services/career/save_manager.dart';
import '../../services/career/career_manager.dart';

class SaveLoadMenu extends StatefulWidget {
  final bool isLoadMode; // true = Load Menu, false = Save Menu

  const SaveLoadMenu({
    Key? key,
    this.isLoadMode = true,
  }) : super(key: key);

  @override
  _SaveLoadMenuState createState() => _SaveLoadMenuState();
}

class _SaveLoadMenuState extends State<SaveLoadMenu> with TickerProviderStateMixin {
  List<SaveSlot> saveSlots = [];
  bool isLoading = true;
  String? errorMessage;

  late AnimationController _fadeController;
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _backgroundShift;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSaveSlots();
  }

  void _initializeAnimations() {
    // Main fade animation
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Background animation (like main menu)
    _backgroundController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat();
    _backgroundShift = Tween<double>(begin: 0.0, end: 1.0).animate(_backgroundController);

    // Card stagger animation
    _cardController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 300), () {
      _cardController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _backgroundController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadSaveSlots() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      List<SaveSlot> slots = await SaveManager.getAllSaveSlots();

      setState(() {
        saveSlots = slots;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load save slots: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: _buildBackgroundGradient(),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildContent()),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Same gradient as main menu
  BoxDecoration _buildBackgroundGradient() {
    return BoxDecoration(
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.red[600]!.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          SizedBox(width: 16),

          // Racing stripe
          Container(
            width: 4,
            height: 30,
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

          // Title section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isLoadMode ? 'LOAD CAREER' : 'SAVE CAREER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  widget.isLoadMode
                      ? 'Choose a saved career to continue your F1 journey'
                      : 'Save your current career progress to a slot',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Formula1',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading save slots...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Formula1',
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red[600]!.withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.red[600]!, width: 2),
              ),
              child: Icon(Icons.error_outline, color: Colors.red[400], size: 40),
            ),
            SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Formula1',
              ),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontFamily: 'Formula1',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            _buildEnhancedButton(
              label: 'RETRY',
              onPressed: _loadSaveSlots,
              gradientColors: [Colors.red[500]!, Colors.red[700]!],
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimation.value)),
          child: Opacity(
            opacity: _cardAnimation.value,
            child: _buildSaveSlotsList(),
          ),
        );
      },
    );
  }

  Widget _buildSaveSlotsList() {
    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: saveSlots.length,
      itemBuilder: (context, index) {
        // Stagger animation for each card
        double delay = index * 0.1;
        return AnimatedBuilder(
          animation: _cardAnimation,
          builder: (context, child) {
            double animProgress = (_cardAnimation.value - delay).clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, 30 * (1 - animProgress)),
              child: Opacity(
                opacity: animProgress,
                child: _buildSaveSlotCard(saveSlots[index], index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSaveSlotCard(SaveSlot slot, int index) {
    final bool isEmpty = slot.isEmpty;
    final bool canLoad = widget.isLoadMode && !isEmpty;
    final bool canSave = !widget.isLoadMode;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEmpty
              ? [Colors.grey[800]!.withOpacity(0.3), Colors.grey[900]!.withOpacity(0.1)]
              : [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEmpty ? Colors.grey[700]!.withOpacity(0.3) : Colors.red[600]!.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: isEmpty
            ? null
            : [
                BoxShadow(
                  color: Colors.red[600]!.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (widget.isLoadMode && canLoad) {
              _loadCareerFromSlot(slot);
            } else if (!widget.isLoadMode && canSave) {
              _saveCareerToSlot(slot);
            }
          },
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSlotHeader(slot),
                if (!isEmpty) ...[
                  SizedBox(height: 20),
                  _buildSlotDetails(slot),
                ],
                SizedBox(height: 20),
                _buildSlotActions(slot),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotHeader(SaveSlot slot) {
    return Row(
      children: [
        // Slot number with F1 styling
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: slot.isEmpty ? [Colors.grey[700]!, Colors.grey[800]!] : [Colors.red[500]!, Colors.red[700]!],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: slot.isEmpty
                ? null
                : [
                    BoxShadow(
                      color: Colors.red[600]!.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              '${slot.slotIndex + 1}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Formula1',
              ),
            ),
          ),
        ),

        SizedBox(width: 20),

        // Slot info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot.isEmpty ? 'Empty Slot' : slot.saveName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                ),
              ),
              if (!slot.isEmpty) ...[
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[400], size: 16),
                    SizedBox(width: 6),
                    Text(
                      slot.driverName,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontFamily: 'Formula1',
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.sports_motorsports, color: Colors.grey[400], size: 16),
                    SizedBox(width: 6),
                    Text(
                      slot.teamName,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontFamily: 'Formula1',
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: 10),

              // Status indicator
              if (!slot.isEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[500]!, Colors.green[700]!],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    slot.progressText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Formula1',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotDetails(SaveSlot slot) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildDetailBadge('WINS', slot.careerWins.toString(), Icons.emoji_events, Colors.amber),
          SizedBox(width: 16),
          _buildDetailBadge('POINTS', slot.careerPoints.toString(), Icons.stars, Colors.blue[400]!),
          SizedBox(width: 16),
          _buildDetailBadge('SEASON', slot.currentSeason.toString(), Icons.calendar_today, Colors.purple[400]!),
          Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'LAST SAVED',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                slot.lastSavedText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBadge(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Formula1',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 9,
            fontWeight: FontWeight.w700,
            fontFamily: 'Formula1',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSlotActions(SaveSlot slot) {
    return Row(
      children: [
        if (widget.isLoadMode) ...[
          if (!slot.isEmpty) ...[
            Expanded(
              child: _buildEnhancedButton(
                label: 'LOAD CAREER',
                onPressed: () => _loadCareerFromSlot(slot),
                gradientColors: [Colors.green[500]!, Colors.green[700]!],
                icon: Icons.play_arrow,
              ),
            ),
            SizedBox(width: 12),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red[600]!.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[600]!, width: 1),
              ),
              child: IconButton(
                onPressed: () => _deleteCareerFromSlot(slot),
                icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                tooltip: 'Delete Save',
              ),
            ),
          ] else ...[
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!, width: 1),
                ),
                child: Center(
                  child: Text(
                    'No saved career',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontFamily: 'Formula1',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ] else ...[
          // Save mode
          Expanded(
            child: _buildEnhancedButton(
              label: slot.isEmpty ? 'SAVE HERE' : 'OVERWRITE',
              onPressed: () => _saveCareerToSlot(slot),
              gradientColors:
                  slot.isEmpty ? [Colors.blue[500]!, Colors.blue[700]!] : [Colors.orange[500]!, Colors.orange[700]!],
              icon: Icons.save,
            ),
          ),
          if (!slot.isEmpty) ...[
            SizedBox(width: 12),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red[600]!.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[600]!, width: 1),
              ),
              child: IconButton(
                onPressed: () => _deleteCareerFromSlot(slot),
                icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                tooltip: 'Delete Save',
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildEnhancedButton({
    required String label,
    required VoidCallback onPressed,
    required List<Color> gradientColors,
    IconData? icon,
  }) {
    return Container(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                ],
                Text(
                  label,
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
          ),
        ),
      ),
    );
  }

  // All the existing functionality methods remain unchanged
  Future<void> _loadCareerFromSlot(SaveSlot slot) async {
    if (slot.isEmpty) return;

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Load Career',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Load "${slot.saveName}"?\n\nThis will replace your current career progress.',
          style: TextStyle(
            color: Colors.grey[300],
            fontFamily: 'Formula1',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Load'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            ),
            SizedBox(width: 16),
            Text(
              'Loading career...',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Formula1',
              ),
            ),
          ],
        ),
      ),
    );

    try {
      bool success = await SaveManager.loadCareerFromSlot(slot.slotIndex);

      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/career_home',
          (route) => false,
        );
      } else {
        _showErrorDialog('Failed to load career from slot ${slot.slotIndex + 1}');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog('Error loading career: $e');
    }
  }

  Future<void> _saveCareerToSlot(SaveSlot slot) async {
    if (CareerManager.currentCareerDriver == null) {
      _showErrorDialog('No active career to save');
      return;
    }

    String? saveName = await _showSaveNameDialog(slot);
    if (saveName == null) return;

    if (!slot.isEmpty) {
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Overwrite Save',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Formula1',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This will overwrite "${slot.saveName}".\n\nAre you sure?',
            style: TextStyle(
              color: Colors.grey[300],
              fontFamily: 'Formula1',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Overwrite'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    // Show saving dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
            SizedBox(width: 16),
            Text(
              'Saving career...',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Formula1',
              ),
            ),
          ],
        ),
      ),
    );

    try {
      bool success = await SaveManager.saveCareerToSlot(slot.slotIndex, saveName);

      Navigator.of(context).pop(); // Close saving dialog

      if (success) {
        await _loadSaveSlots(); // Refresh the list

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Career saved successfully!'),
            backgroundColor: Colors.green[600],
          ),
        );
      } else {
        _showErrorDialog('Failed to save career to slot ${slot.slotIndex + 1}');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close saving dialog
      _showErrorDialog('Error saving career: $e');
    }
  }

  Future<String?> _showSaveNameDialog(SaveSlot slot) async {
    TextEditingController controller = TextEditingController(
      text: slot.isEmpty ? '${CareerManager.currentCareerDriver?.name ?? "Player"} Career' : slot.saveName,
    );

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Save Name',
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
            hintStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue[600]!),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              String name = controller.text.trim();
              if (name.isEmpty) {
                name = '${CareerManager.currentCareerDriver?.name ?? "Player"} Career';
              }
              Navigator.of(context).pop(name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCareerFromSlot(SaveSlot slot) async {
    if (slot.isEmpty) return;

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Save',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Delete "${slot.saveName}"?\n\nThis action cannot be undone.',
          style: TextStyle(
            color: Colors.grey[300],
            fontFamily: 'Formula1',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bool success = await SaveManager.deleteCareerFromSlot(slot.slotIndex);
      if (success) {
        await _loadSaveSlots(); // Refresh the list

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save deleted successfully'),
            backgroundColor: Colors.green[600],
          ),
        );

        if (widget.isLoadMode) {
          Future.delayed(Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            }
          });
        }
      } else {
        _showErrorDialog('Failed to delete save');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Error',
          style: TextStyle(
            color: Colors.red[400],
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Formula1',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
