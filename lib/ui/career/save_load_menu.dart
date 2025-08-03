// lib/ui/career/save_load_menu.dart
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
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSaveSlots();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
      appBar: AppBar(
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        title: Text(
          widget.isLoadMode ? 'LOAD CAREER' : 'SAVE CAREER',
          style: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: _buildContent(),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!),
            ),
            SizedBox(height: 16),
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
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 16,
                fontFamily: 'Formula1',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSaveSlots,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildSaveSlotsList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.red[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isLoadMode ? 'SELECT CAREER TO LOAD' : 'SELECT SLOT TO SAVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Formula1',
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.isLoadMode
                      ? 'Choose a saved career to continue your F1 journey'
                      : 'Save your current career progress to a slot',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
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

  Widget _buildSaveSlotsList() {
    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: saveSlots.length,
      itemBuilder: (context, index) {
        final slot = saveSlots[index];
        return _buildSaveSlotCard(slot, index);
      },
    );
  }

  Widget _buildSaveSlotCard(SaveSlot slot, int index) {
    final bool isEmpty = slot.isEmpty;
    final bool canLoad = widget.isLoadMode && !isEmpty;
    final bool canSave = !widget.isLoadMode;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isEmpty ? 0.03 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(isEmpty ? 0.05 : 0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (widget.isLoadMode && canLoad) {
              _loadCareerFromSlot(slot);
            } else if (!widget.isLoadMode && canSave) {
              _saveCareerToSlot(slot);
            }
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSlotHeader(slot),
                if (!isEmpty) ...[
                  SizedBox(height: 12),
                  _buildSlotDetails(slot),
                ],
                SizedBox(height: 12),
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
        // Slot number
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: slot.isEmpty ? Colors.grey[700] : Colors.red[600],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${slot.slotIndex + 1}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Formula1',
              ),
            ),
          ),
        ),
        SizedBox(width: 16),

        // Slot info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot.isEmpty ? 'Empty Slot' : slot.saveName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Formula1',
                ),
              ),
              if (!slot.isEmpty) ...[
                SizedBox(height: 4),
                Text(
                  '${slot.driverName} • ${slot.teamName}',
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

        // Status indicator
        if (!slot.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[600]!.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green[600]!, width: 1),
            ),
            child: Text(
              slot.progressText,
              style: TextStyle(
                color: Colors.green[400],
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'Formula1',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSlotDetails(SaveSlot slot) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildDetailItem('WINS', slot.careerWins.toString()),
          SizedBox(width: 16),
          _buildDetailItem('POINTS', slot.careerPoints.toString()),
          SizedBox(width: 16),
          _buildDetailItem('SEASON', slot.currentSeason.toString()),
          Spacer(),
          _buildDetailItem('SAVED', slot.lastSavedText),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'Formula1',
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
              child: ElevatedButton.icon(
                onPressed: () => _loadCareerFromSlot(slot),
                icon: Icon(Icons.play_arrow, size: 16),
                label: Text('LOAD CAREER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              onPressed: () => _deleteCareerFromSlot(slot),
              icon: Icon(Icons.delete_outline),
              color: Colors.red[400],
              tooltip: 'Delete Save',
            ),
          ] else ...[
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No saved career',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontFamily: 'Formula1',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ] else ...[
          // Save mode
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _saveCareerToSlot(slot),
              icon: Icon(Icons.save, size: 16),
              label: Text(slot.isEmpty ? 'SAVE HERE' : 'OVERWRITE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: slot.isEmpty ? Colors.blue[600] : Colors.orange[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (!slot.isEmpty) ...[
            SizedBox(width: 8),
            IconButton(
              onPressed: () => _deleteCareerFromSlot(slot),
              icon: Icon(Icons.delete_outline),
              color: Colors.red[400],
              tooltip: 'Delete Save',
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _loadCareerFromSlot(SaveSlot slot) async {
    if (slot.isEmpty) return;

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
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
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
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
        backgroundColor: Colors.grey[900],
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
        // Navigate to career home
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

    // Show save name dialog
    String? saveName = await _showSaveNameDialog(slot);
    if (saveName == null) return;

    // Show confirmation for overwrite
    if (!slot.isEmpty) {
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
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
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
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
        backgroundColor: Colors.grey[900],
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
        // Refresh the save slots list
        await _loadSaveSlots();

        // Show success message
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
        backgroundColor: Colors.grey[900],
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
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue[600]!),
            ),
          ),
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel'),
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
        backgroundColor: Colors.grey[900],
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
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
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
      } else {
        _showErrorDialog('Failed to delete save');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
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
            ),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
