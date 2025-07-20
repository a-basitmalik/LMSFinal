import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';

class FineListScreen extends StatefulWidget {
  const FineListScreen({super.key});

  @override
  State<FineListScreen> createState() => _FineListScreenState();
}

class _FineListScreenState extends State<FineListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Fine> _fines = [];
  List<Fine> _filteredFines = [];
  final Map<String, bool> _selectedFines = {};
  bool _isLoading = false;

  final List<String> _fineTypes = [
    'Absentee Fine',
    'Exam leaving Fine',
    'Uniform Fine',
    'Late Fine',
    'Custom Fine'
  ];
  final List<double> _defaultFineAmounts = [100.00, 500.00, 500.00, 100.00, 0.00];

  @override
  void initState() {
    super.initState();
    _loadFines();
    _searchController.addListener(_filterFines);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFines() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _fines.addAll(_getDummyFines());
      _filteredFines = _fines;
      _isLoading = false;
    });
  }

  List<Fine> _getDummyFines() {
    final random = Random();
    final studentNames = ['John Smith', 'Emma Johnson', 'Michael Brown', 'Olivia Davis'];
    final studentIds = ['ST001', 'ST002', 'ST003', 'ST004'];
    final customReasons = [
      'Library book damage',
      'Lab equipment damage',
      'Graffiti',
      'Cafeteria violation',
      'Parking violation'
    ];

    final List<Fine> dummyFines = [];

    for (int i = 0; i < 20; i++) {
      final studentIndex = random.nextInt(studentNames.length);
      final fineTypeIndex = random.nextInt(_fineTypes.length - 1);
      final baseAmount = _defaultFineAmounts[fineTypeIndex];
      final variation = (random.nextDouble() * 2 - 1) * (baseAmount * 0.1);
      final amount = (baseAmount + variation).clamp(0, double.infinity);

      dummyFines.add(Fine(
        studentName: studentNames[studentIndex],
        studentId: studentIds[studentIndex],
        amount: amount.toDouble(),
        type: _fineTypes[fineTypeIndex],
        isWaived: random.nextDouble() < 0.2,
      ));
    }

    for (int i = 0; i < 5; i++) {
      final studentIndex = random.nextInt(studentNames.length);
      final customAmount = 5 + (random.nextDouble() * 45);
      final reason = customReasons[random.nextInt(customReasons.length)];

      dummyFines.add(Fine(
        studentName: studentNames[studentIndex],
        studentId: studentIds[studentIndex],
        amount: customAmount,
        type: 'Custom Fine: $reason',
        isWaived: false,
      ));
    }

    return dummyFines;
  }

  void _filterFines() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFines = _fines.where((fine) {
        return fine.studentName.toLowerCase().contains(query) ||
            fine.studentId.toLowerCase().contains(query) ||
            fine.type.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleFineSelection(String fineId) {
    setState(() {
      _selectedFines[fineId] = !(_selectedFines[fineId] ?? false);
    });
  }

  List<String> _getStudentsWithSelectedFines() {
    final students = <String>[];
    final added = <String, bool>{};

    for (int i = 0; i < _filteredFines.length; i++) {
      final fine = _filteredFines[i];
      final fineId = '${fine.studentId}_$i';

      if ((_selectedFines[fineId] ?? false) && !added.containsKey(fine.studentId)) {
        students.add(fine.studentId);
        added[fine.studentId] = true;
      }
    }

    return students;
  }

  List<Fine> _getSelectedFinesForStudent(String studentId) {
    return _filteredFines
        .where((fine) => fine.studentId == studentId)
        .where((fine) => _selectedFines['${fine.studentId}_${_filteredFines.indexOf(fine)}'] ?? false)
        .toList();
  }

  Map<String, String> _getStudentNames() {
    final names = <String, String>{};
    for (final fine in _filteredFines) {
      names[fine.studentId] = fine.studentName;
    }
    return names;
  }

  void _clearSelections() {
    setState(() => _selectedFines.clear());
  }

  Future<void> _showAddFineDialog() async {
    String studentName = '';
    String studentId = '';
    double amount = 0;
    String selectedType = _fineTypes[0];
    bool isCustom = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              content: Container(
                decoration: AdminColors.glassDecoration(borderRadius: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add Fine',
                        style: AdminTextStyles.sectionHeader.copyWith(
                          color: AdminColors.primaryAccent,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (value) => studentName = value,
                        style: AdminTextStyles.cardTitle,
                        decoration: InputDecoration(
                          hintText: 'Student Name',
                          hintStyle: AdminTextStyles.cardSubtitle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AdminColors.cardBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => studentId = value,
                        style: AdminTextStyles.cardTitle,
                        decoration: InputDecoration(
                          hintText: 'Student ID',
                          hintStyle: AdminTextStyles.cardSubtitle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AdminColors.cardBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        items: _fineTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              style: AdminTextStyles.cardTitle,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedType = value!;
                            isCustom = value == _fineTypes.last;
                            if (!isCustom) {
                              amount = _defaultFineAmounts[_fineTypes.indexOf(value)];
                            }
                          });
                        },
                        dropdownColor: AdminColors.secondaryBackground,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AdminColors.cardBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        enabled: isCustom,
                        onChanged: (value) => amount = double.tryParse(value) ?? 0,
                        keyboardType: TextInputType.number,
                        style: AdminTextStyles.cardTitle,
                        decoration: InputDecoration(
                          hintText: 'Amount',
                          hintStyle: AdminTextStyles.cardSubtitle,
                          prefixText: isCustom ? '' : 'Default: ',
                          prefixStyle: AdminTextStyles.cardSubtitle,
                          suffixText: isCustom
                              ? ''
                              : _defaultFineAmounts[_fineTypes.indexOf(selectedType)]
                              .toStringAsFixed(2),
                          suffixStyle: AdminTextStyles.cardTitle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AdminColors.cardBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: AdminTextStyles.secondaryButton.copyWith(
                                color: AdminColors.primaryAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.primaryAccent,
                            ),
                            onPressed: () {
                              if (studentName.isEmpty || studentId.isEmpty) return;
                              _fines.add(Fine(
                                studentName: studentName,
                                studentId: studentId,
                                amount: isCustom
                                    ? amount
                                    : _defaultFineAmounts[_fineTypes.indexOf(selectedType)],
                                type: selectedType,
                                isWaived: false,
                              ));
                              _filterFines();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Add',
                              style: AdminTextStyles.primaryButton.copyWith(
                                color: AdminColors.primaryBackground,
                              ),
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
      },
    );
  }


  Future<void> _handleGenerateReport() async {
    final studentsWithFines = _getStudentsWithSelectedFines();

    if (studentsWithFines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one fine',
            style: AdminTextStyles.cardSubtitle,
          ),
          backgroundColor: AdminColors.dangerAccent,
        ),
      );
      return;
    }

    if (studentsWithFines.length > 1) {
      await _showSelectStudentDialog(studentsWithFines);
    } else {
      final studentId = studentsWithFines.first;
      final selectedFines = _getSelectedFinesForStudent(studentId);
      await _generateChallanForStudent(studentId, selectedFines);
    }
  }

  Future<void> _showSelectStudentDialog(List<String> studentIds) async {
    final studentNames = _getStudentNames();
    final displayNames = studentIds.map((id) => '${studentNames[id]} ($id)').toList();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: Container(
            decoration: AdminColors.glassDecoration(borderRadius: 20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Student for Challan',
                    style: AdminTextStyles.sectionHeader.copyWith(
                      color: AdminColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...displayNames.map((name) {
                    return ListTile(
                      title: Text(
                        name,
                        style: AdminTextStyles.cardTitle,
                      ),
                      onTap: () {
                        final studentId = studentIds[displayNames.indexOf(name)];
                        final selectedFines = _getSelectedFinesForStudent(studentId);
                        Navigator.pop(context);
                        _generateChallanForStudent(studentId, selectedFines);
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AdminTextStyles.secondaryButton.copyWith(
                        color: AdminColors.primaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateChallanForStudent(String studentId, List<Fine> selectedFines) async {
    if (selectedFines.isEmpty) return;

    final studentName = _getStudentNames()[studentId] ?? 'Unknown';
    final totalAmount = selectedFines.fold(0.0, (sum, fine) => sum + fine.amount);
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final challanNumber = 'FINE-$date-$studentId';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: Container(
            decoration: AdminColors.glassDecoration(borderRadius: 20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Challan Generated',
                    style: AdminTextStyles.sectionHeader.copyWith(
                      color: AdminColors.primaryAccent,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Student: $studentName ($studentId)',
                    style: AdminTextStyles.cardTitle,
                  ),
                  Text(
                    'Challan #: $challanNumber',
                    style: AdminTextStyles.cardTitle,
                  ),
                  Text(
                    'Total Amount: Rs${totalAmount.toStringAsFixed(2)}',
                    style: AdminTextStyles.sectionHeader.copyWith(
                      color: AdminColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fines:',
                    style: AdminTextStyles.cardTitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...selectedFines.map((fine) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${fine.type}: Rs${fine.amount.toStringAsFixed(2)}',
                        style: AdminTextStyles.cardSubtitle,
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primaryAccent,
                      ),
                      onPressed: () {
                        _clearSelections();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: AdminTextStyles.primaryButton.copyWith(
                          color: AdminColors.primaryBackground,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Future<void> _showWaiverConfirmation(Fine fine, int index) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: Container(
            decoration: AdminColors.glassDecoration(borderRadius: 20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirm Waiver',
                    style: AdminTextStyles.sectionHeader.copyWith(
                      color: AdminColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Waive this fine for ${fine.studentName}?',
                    style: AdminTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: AdminTextStyles.secondaryButton.copyWith(
                            color: AdminColors.primaryAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.primaryAccent,
                        ),
                        onPressed: () {
                          setState(() => fine.isWaived = true);
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Confirm',
                          style: AdminTextStyles.primaryButton.copyWith(
                            color: AdminColors.primaryBackground,
                          ),
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

  Future<void> _showRemoveConfirmation(Fine fine, int index) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: Container(
            decoration: AdminColors.glassDecoration(borderRadius: 20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Remove Fine',
                    style: AdminTextStyles.sectionHeader.copyWith(
                      color: AdminColors.dangerAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Remove this fine for ${fine.studentName}?',
                    style: AdminTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: AdminTextStyles.secondaryButton.copyWith(
                            color: AdminColors.primaryAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.dangerAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            _fines.remove(fine);
                            _filterFines();
                          });
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Remove',
                          style: AdminTextStyles.primaryButton.copyWith(
                            color: AdminColors.primaryText,
                          ),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  AdminColors.primaryBackground,
                  AdminColors.secondaryBackground,
                ],
              ),
            ),
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'FINE MANAGEMENT',
                    style: AdminTextStyles.sectionHeader.copyWith(
                      fontSize: 18,
                      letterSpacing: 3,
                    ),
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AdminColors.secondaryAccent.withOpacity(0.7),
                          AdminColors.primaryAccent.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.print, color: AdminColors.primaryAccent),
                    onPressed: _handleGenerateReport,
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: AdminColors.glassDecoration(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        style: AdminTextStyles.cardTitle,
                        decoration: InputDecoration(
                          hintText: 'Search by name or ID',
                          hintStyle: AdminTextStyles.cardSubtitle,
                          prefixIcon: Icon(
                            Icons.search,
                            color: AdminColors.primaryAccent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AdminColors.cardBorder,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AdminColors.primaryAccent,
                    ),
                  ),
                )
              else if (_filteredFines.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No fines found',
                      style: AdminTextStyles.cardSubtitle,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final fine = _filteredFines[index];
                        final fineId = '${fine.studentId}_$index';
                        final isSelected = _selectedFines[fineId] ?? false;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _FineCard(
                            fine: fine,
                            isSelected: isSelected,
                            onTap: () => _toggleFineSelection(fineId),
                            onWaiver: () => _showWaiverConfirmation(fine, index),
                            onRemove: () => _showRemoveConfirmation(fine, index),
                          ),
                        );
                      },
                      childCount: _filteredFines.length,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFineDialog,
        icon: Icon(Icons.add, color: AdminColors.primaryBackground),
        label: Text(
          'ADD FINE',
          style: AdminTextStyles.primaryButton.copyWith(
            color: AdminColors.primaryBackground,
          ),
        ),
        backgroundColor: AdminColors.primaryAccent,
      ),
    );
  }
}

class _FineCard extends StatelessWidget {
  final Fine fine;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onWaiver;
  final VoidCallback onRemove;

  const _FineCard({
    required this.fine,
    required this.isSelected,
    required this.onTap,
    required this.onWaiver,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AdminColors.glassDecoration(
          borderRadius: 12,
          borderColor: isSelected ? AdminColors.primaryAccent : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    fine.studentName,
                    style: AdminTextStyles.cardTitle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rs${fine.amount.toStringAsFixed(2)}',
                    style: AdminTextStyles.cardTitle.copyWith(
                      color: fine.isWaived ? AdminColors.dangerAccent : AdminColors.primaryAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    fine.studentId,
                    style: AdminTextStyles.cardSubtitle,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AdminColors.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AdminColors.primaryAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      fine.type,
                      style: AdminTextStyles.cardSubtitle.copyWith(
                        color: AdminColors.primaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: fine.isWaived
                            ? AdminColors.disabledText.withOpacity(0.2)
                            : AdminColors.primaryAccent.withOpacity(0.2),
                        foregroundColor: fine.isWaived
                            ? AdminColors.disabledText
                            : AdminColors.primaryAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: fine.isWaived ? null : onWaiver,
                      child: Text(
                        fine.isWaived ? 'WAIVED' : 'WAIVER',
                        style: AdminTextStyles.secondaryButton.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.dangerAccent.withOpacity(0.2),
                        foregroundColor: AdminColors.dangerAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onRemove,
                      child: Text(
                        'REMOVE',
                        style: AdminTextStyles.secondaryButton.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Fine {
  final String studentName;
  final String studentId;
  final double amount;
  final String type;
  bool isWaived;

  Fine({
    required this.studentName,
    required this.studentId,
    required this.amount,
    required this.type,
    this.isWaived = false,
  });
}