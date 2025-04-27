import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fee Management',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00F0FF),
          brightness: Brightness.dark,
          background: const Color(0xFF0A0A1A),
        ),
        useMaterial3: true,
      ),
      home: const FineListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
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

    // Generate standard fines
    for (int i = 0; i < 20; i++) {
      final studentIndex = random.nextInt(studentNames.length);
      final fineTypeIndex = random.nextInt(_fineTypes.length - 1);
      final baseAmount = _defaultFineAmounts[fineTypeIndex];
      final variation = (random.nextDouble() * 2 - 1) * (baseAmount * 0.1);
      final amount = (baseAmount + variation).clamp(0, double.infinity);

      final fine = Fine(
        studentName: studentNames[studentIndex],
        studentId: studentIds[studentIndex],
        amount: amount.toDouble(),
        type: _fineTypes[fineTypeIndex],
        isWaived: random.nextDouble() < 0.2,
      );

      dummyFines.add(fine);
    }

    // Generate custom fines
    for (int i = 0; i < 5; i++) {
      final studentIndex = random.nextInt(studentNames.length);
      final customAmount = 5 + (random.nextDouble() * 45);
      final reason = customReasons[random.nextInt(customReasons.length)];

      final customFine = Fine(
        studentName: studentNames[studentIndex],
        studentId: studentIds[studentIndex],
        amount: customAmount,
        type: 'Custom Fine: $reason',
        isWaived: false,
      );

      dummyFines.add(customFine);
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
              insetPadding: const EdgeInsets.all(16),
              content: GlassCard(
                borderRadius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add Fine',
                        style: GoogleFonts.orbitron(
                          color: Colors.cyanAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (value) => studentName = value,
                        style: GoogleFonts.orbitron(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Student Name',
                          hintStyle: GoogleFonts.orbitron(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.cyanAccent.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.cyanAccent.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => studentId = value,
                        style: GoogleFonts.orbitron(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Student ID',
                          hintStyle: GoogleFonts.orbitron(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.cyanAccent.withOpacity(0.3),
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
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedType = value!;
                            isCustom = value == _fineTypes.last;
                            if (!isCustom) {
                              amount = _defaultFineAmounts[_fineTypes.indexOf(value!)];
                            }
                          });
                        },
                        dropdownColor: const Color(0xFF1A1A2E),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.cyanAccent.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        enabled: isCustom,
                        onChanged: (value) => amount = double.tryParse(value) ?? 0,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.orbitron(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Amount',
                          hintStyle: GoogleFonts.orbitron(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          prefixText: isCustom ? '' : 'Default: ',
                          prefixStyle: GoogleFonts.orbitron(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          suffixText: isCustom ? '' : _defaultFineAmounts[_fineTypes.indexOf(selectedType)].toStringAsFixed(2),
                          suffixStyle: GoogleFonts.orbitron(
                            color: Colors.white,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.cyanAccent.withOpacity(0.3),
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
                              style: GoogleFonts.orbitron(
                                color: Colors.cyanAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                            ),
                            onPressed: () {
                              if (studentName.isEmpty || studentId.isEmpty) {
                                return;
                              }
                              final fine = Fine(
                                studentName: studentName,
                                studentId: studentId,
                                amount: isCustom ? amount : _defaultFineAmounts[_fineTypes.indexOf(selectedType)],
                                type: selectedType,
                                isWaived: false,
                              );
                              _fines.add(fine);
                              _filterFines();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Add',
                              style: GoogleFonts.orbitron(
                                color: Colors.black,
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
            style: GoogleFonts.orbitron(),
          ),
          backgroundColor: Colors.redAccent,
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
          content: GlassCard(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Student for Challan',
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...displayNames.map((name) {
                    return ListTile(
                      title: Text(
                        name,
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                        ),
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
                      style: GoogleFonts.orbitron(
                        color: Colors.cyanAccent,
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
    if (selectedFines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fines selected for this student',
            style: GoogleFonts.orbitron(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final studentName = _getStudentNames()[studentId] ?? 'Unknown';
    final totalAmount = selectedFines.fold(0.0, (sum, fine) => sum + fine.amount);
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final challanNumber = 'FINE-$date-$studentId';

    // In a real app, you would navigate to a challan screen
    // Here we just show a dialog with the summary
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassCard(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Challan Generated',
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Student: $studentName ($studentId)',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Challan #: $challanNumber',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Total Amount: Rs${totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fines:',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...selectedFines.map((fine) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${fine.type}: Rs${fine.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.orbitron(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                      ),
                      onPressed: () {
                        _clearSelections();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: GoogleFonts.orbitron(
                          color: Colors.black,
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
          content: GlassCard(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirm Waiver',
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Waive this fine for ${fine.studentName}?',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.orbitron(
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            fine.isWaived = true;
                          });
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Confirm',
                          style: GoogleFonts.orbitron(
                            color: Colors.black,
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
          content: GlassCard(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Remove Fine',
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Remove this fine for ${fine.studentName}?',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.orbitron(
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
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
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Cyberpunk background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF0A0A1A),
                  Color(0xFF000000),
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
                    style: GoogleFonts.orbitron(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0066FF).withOpacity(0.7),
                          const Color(0xFF00F0FF).withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.print),
                    color: Colors.cyanAccent,
                    onPressed: _handleGenerateReport,
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: GlassCard(
                    borderRadius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.orbitron(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by name or ID',
                          hintStyle: GoogleFonts.orbitron(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.cyanAccent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.cyanAccent.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.cyanAccent.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.cyanAccent,
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
                      color: Colors.cyanAccent,
                    ),
                  ),
                )
              else if (_filteredFines.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No fines found',
                      style: GoogleFonts.orbitron(
                        color: Colors.white.withOpacity(0.5),
                      ),
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
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          'ADD FINE',
          style: GoogleFonts.orbitron(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.cyanAccent,
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
      child: GlassCard(
        borderRadius: 12,
        borderColor: isSelected ? Colors.cyanAccent : null,
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
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rs${fine.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.orbitron(
                      color: fine.isWaived ? Colors.redAccent : Colors.cyanAccent,
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
                    style: GoogleFonts.orbitron(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      fine.type,
                      style: GoogleFonts.orbitron(
                        color: Colors.cyanAccent,
                        fontSize: 12,
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
                            ? Colors.grey.withOpacity(0.2)
                            : Colors.cyanAccent.withOpacity(0.2),
                        foregroundColor: fine.isWaived
                            ? Colors.grey
                            : Colors.cyanAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: fine.isWaived ? null : onWaiver,
                      child: Text(
                        fine.isWaived ? 'WAIVED' : 'WAIVER',
                        style: GoogleFonts.orbitron(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.2),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onRemove,
                      child: Text(
                        'REMOVE',
                        style: GoogleFonts.orbitron(
                          fontSize: 12,
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

class GlassCard extends StatelessWidget {
  final Widget? child;
  final double borderRadius;
  final Color? borderColor;
  final EdgeInsets? padding;

  const GlassCard({
    super.key,
    this.child,
    this.borderRadius = 16,
    this.borderColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: padding != null
            ? Padding(
          padding: padding!,
          child: child,
        )
            : child,
      ),
    );
  }
}