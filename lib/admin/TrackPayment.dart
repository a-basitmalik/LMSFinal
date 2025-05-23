import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
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
        useMaterial3: true, // This needs to be outside of colorScheme
      ),
      home: const TrackPaymentScreen(),
      debugShowCheckedModeBanner: false,
    );

  }
}

class TrackPaymentScreen extends StatefulWidget {
  const TrackPaymentScreen({super.key});

  @override
  State<TrackPaymentScreen> createState() => _TrackPaymentScreenState();
}

class _TrackPaymentScreenState extends State<TrackPaymentScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;
  List<Payment> _payments = [];
  List<Payment> _filteredPayments = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
    _searchController.addListener(_filterPayments);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    setState(() {
      _payments = _getDummyPaymentRecords();
      _filteredPayments = _payments;
      _isLoading = false;
    });
  }

  void _filterPayments() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPayments = _payments.where((payment) {
        final matchesSearch = query.isEmpty ||
            payment.studentName.toLowerCase().contains(query) ||
            payment.studentId.toLowerCase().contains(query);

        final matchesDate = _fromDate == null || _toDate == null ||
            (payment.paymentDate.isAfter(_fromDate!) &&
                payment.paymentDate.isBefore(_toDate!));

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: GlassCard(
            borderRadius: 20,
            child: SfDateRangePicker(
              selectionMode: DateRangePickerSelectionMode.range,
              minDate: DateTime.now().subtract(const Duration(days: 365)),
              maxDate: DateTime.now(),
              monthViewSettings: const DateRangePickerMonthViewSettings(
                showTrailingAndLeadingDates: true,
              ),
              headerStyle: DateRangePickerHeaderStyle(
                textStyle: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selectionTextStyle: TextStyle(
                color: Colors.black,
                fontFamily: GoogleFonts.orbitron().fontFamily,
              ),
              rangeSelectionColor: Colors.cyanAccent.withOpacity(0.3),
              startRangeSelectionColor: Colors.cyanAccent,
              endRangeSelectionColor: Colors.cyanAccent,
              todayHighlightColor: Colors.cyanAccent,
              monthCellStyle: DateRangePickerMonthCellStyle(
                textStyle: const TextStyle(color: Colors.white),
                todayTextStyle: TextStyle(
                  color: Colors.black,
                  fontFamily: GoogleFonts.orbitron().fontFamily,
                ),
              ),
              yearCellStyle: DateRangePickerYearCellStyle(
                textStyle: const TextStyle(color: Colors.white),
                todayTextStyle: TextStyle(
                  color: Colors.black,
                  fontFamily: GoogleFonts.orbitron().fontFamily,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
        _filterPayments();
      });
    }
  }

  List<Payment> _getDummyPaymentRecords() {
    final random = Random();
    final now = DateTime.now();
    final studentNames = [
      'John Smith', 'Emma Johnson', 'Michael Brown', 'Sarah Davis',
      'James Wilson', 'Emily Taylor', 'William Anderson', 'Olivia Martinez',
      'Alexander Thomas', 'Sophia Garcia'
    ];
    final statuses = ['Completed', 'Pending', 'Failed', 'Processing'];

    return List.generate(20, (index) {
      final studentId = 'STU${1001 + index}';
      final amount = 50 + random.nextDouble() * 450;
      final paymentDate = now.subtract(Duration(days: random.nextInt(30)));
      final studentName = studentNames[random.nextInt(studentNames.length)];
      final status = statuses[random.nextInt(statuses.length)];

      return Payment(
        studentName: studentName,
        studentId: studentId,
        amount: amount,
        paymentDate: paymentDate,
        status: status,
      );
    });
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
                    'PAYMENT HISTORY',
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
                    icon: const Icon(Icons.download),
                    color: Colors.cyanAccent,
                    onPressed: () {
                      // TODO: Implement export functionality
                    },
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
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            style: GoogleFonts.orbitron(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search by Student Name/ID',
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
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showDateRangePicker,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.cyanAccent.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _fromDate == null
                                              ? 'From Date'
                                              : _dateFormat.format(_fromDate!),
                                          style: GoogleFonts.orbitron(
                                            color: _fromDate == null
                                                ? Colors.white.withOpacity(0.5)
                                                : Colors.white,
                                          ),
                                        ),
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.cyanAccent,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showDateRangePicker,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.cyanAccent.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _toDate == null
                                              ? 'To Date'
                                              : _dateFormat.format(_toDate!),
                                          style: GoogleFonts.orbitron(
                                            color: _toDate == null
                                                ? Colors.white.withOpacity(0.5)
                                                : Colors.white,
                                          ),
                                        ),
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.cyanAccent,
                                          size: 20,
                                        ),
                                      ],
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
              else if (_filteredPayments.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No payments found',
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
                        final payment = _filteredPayments[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PaymentCard(payment: payment),
                        );
                      },
                      childCount: _filteredPayments.length,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new payment
        },
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final amountColor = payment.status == 'Completed'
        ? Colors.greenAccent
        : payment.status == 'Failed'
        ? Colors.redAccent
        : Colors.orangeAccent;

    return GlassCard(
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  payment.studentName,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rs${payment.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.orbitron(
                    color: amountColor,
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
                  payment.studentId,
                  style: GoogleFonts.orbitron(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                Text(
                  dateFormat.format(payment.paymentDate),
                  style: GoogleFonts.orbitron(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: amountColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  payment.status,
                  style: GoogleFonts.orbitron(
                    color: amountColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Payment {
  final String studentName;
  final String studentId;
  final double amount;
  final DateTime paymentDate;
  final String status;

  Payment({
    required this.studentName,
    required this.studentId,
    required this.amount,
    required this.paymentDate,
    required this.status,
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