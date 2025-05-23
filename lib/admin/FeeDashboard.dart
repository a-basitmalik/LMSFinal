import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/animation.dart';
import 'dart:math';
import 'TrackPayment.dart';
import 'FineList.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fee Management',
      debugShowCheckedModeBanner: false, // ✅ Here
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00F0FF),
          brightness: Brightness.dark,
          background: const Color(0xFF0A0A1A),
        ),
        useMaterial3: true, // ✅ Move this to ThemeData if supported
      ),
      home: const FeeDashboard(), // ✅ Here
    );

  }
}

class FeeDashboard extends StatefulWidget {
  const FeeDashboard({super.key});

  @override
  State<FeeDashboard> createState() => _FeeDashboardState();
}

class _FeeDashboardState extends State<FeeDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  double _totalCollections = 125000;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Simulate data loading
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToFineList() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: const FineListScreen(),
        ),
      ),
    );
  }

  void _navigateToTrackPayment() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: const TrackPaymentScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Cyberpunk background with animated grid
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      const Color(0xFF0A0A1A).withOpacity(0.9),
                      const Color(0xFF000000).withOpacity(0.9),
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: _CyberGridPainter(animation: _animationController),
                ),
              );
            },
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Text(
                        'FEE MANAGEMENT',
                        style: GoogleFonts.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: Colors.cyanAccent.withOpacity(_fadeAnimation.value),
                          shadows: [
                            Shadow(
                              blurRadius: 10 * _glowAnimation.value,
                              color: Colors.cyanAccent.withOpacity(_glowAnimation.value * 0.5),
                            ),
                          ],
                        ),
                      );
                    },
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
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 1,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.cyanAccent.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card with Holographic Effect
                      _buildHolographicSummaryCard(),
                      const SizedBox(height: 30),
                      // Management Options Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 0.9,
                        children: [
                          _buildHolographicButton(
                            icon: Icons.money_off,
                            label: 'FINE',
                            color: const Color(0xFFFF2D75),
                            onTap: _navigateToFineList,
                          ),
                          _buildHolographicButton(
                            icon: Icons.payment,
                            label: 'TRACK PAYMENT',
                            color: const Color(0xFF00F0FF),
                            onTap: _navigateToTrackPayment,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // Recent Transactions Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'RECENT TRANSACTIONS',
                          style: GoogleFonts.orbitron(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Recent Transactions List
                      _buildRecentTransactions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          'NEW PAYMENT',
          style: GoogleFonts.orbitron(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.cyanAccent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildHolographicSummaryCard() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GlassCard(
          borderColor: Colors.cyanAccent.withOpacity(0.3 * _glowAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0066FF).withOpacity(0.2),
                  const Color(0xFF00F0FF).withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL COLLECTIONS',
                      style: GoogleFonts.orbitron(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.cyanAccent.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'THIS MONTH',
                        style: GoogleFonts.orbitron(
                          color: Colors.cyanAccent,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.cyanAccent,
                  strokeWidth: 2,
                )
                    : AnimatedDigitalCounter(
                  value: _totalCollections,
                  duration: const Duration(milliseconds: 1500),
                  textStyle: GoogleFonts.orbitron(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.cyanAccent.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat(
                      label: 'PAID',
                      value: '85%',
                      color: Colors.greenAccent,
                    ),
                    _buildMiniStat(
                      label: 'PENDING',
                      value: '12%',
                      color: Colors.orangeAccent,
                    ),
                    _buildMiniStat(
                      label: 'OVERDUE',
                      value: '3%',
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.orbitron(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildHolographicButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_fadeAnimation.value * 0.05),
          child: GlassCard(
            borderColor: color.withOpacity(0.3 * _glowAnimation.value),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      color.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            color.withOpacity(0.8),
                            color.withOpacity(0.2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4 * _glowAnimation.value),
                            blurRadius: 15 * _glowAnimation.value,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      label,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            blurRadius: 5 * _glowAnimation.value,
                            color: color.withOpacity(0.6 * _glowAnimation.value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactions() {
    final transactions = [
      {'name': 'John Doe', 'amount': '₹5,000', 'status': 'Paid', 'color': Colors.greenAccent},
      {'name': 'Jane Smith', 'amount': '₹3,500', 'status': 'Pending', 'color': Colors.orangeAccent},
      {'name': 'Robert Johnson', 'amount': '₹7,200', 'status': 'Paid', 'color': Colors.greenAccent},
      {'name': 'Emily Davis', 'amount': '₹2,800', 'status': 'Overdue', 'color': Colors.redAccent},
    ];

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: transactions.map((txn) {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          txn['name'] as String,
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Today, 10:30 AM',
                          style: GoogleFonts.orbitron(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          txn['amount'] as String,
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (txn['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (txn['color'] as Color).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            txn['status'] as String,
                            style: GoogleFonts.orbitron(
                              color: txn['color'] as Color,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (txn != transactions.last)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.cyanAccent.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.borderColor,
    this.borderRadius = 16,
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
        child: child,
      ),
    );
  }
}

class AnimatedDigitalCounter extends StatefulWidget {
  final double value;
  final Duration duration;
  final TextStyle textStyle;

  const AnimatedDigitalCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 500),
    required this.textStyle,
  });

  @override
  _AnimatedDigitalCounterState createState() => _AnimatedDigitalCounterState();
}

class _AnimatedDigitalCounterState extends State<AnimatedDigitalCounter> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(AnimatedDigitalCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.value),
      duration: widget.duration,
      builder: (context, value, child) {
        final formattedValue = value.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
        );
        return Text(
          '₹$formattedValue',
          style: widget.textStyle,
        );
      },
    );
  }
}

class _CyberGridPainter extends CustomPainter {
  final Animation<double> animation;

  _CyberGridPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final random = Random(42);
    final gridSize = 40;
    final cols = (size.width / gridSize).ceil();
    final rows = (size.height / gridSize).ceil();

    // Draw grid lines
    for (var i = 0; i < cols; i++) {
      final x = i * gridSize;
      canvas.drawLine(
        Offset(x.toDouble(), 0),
        Offset(x.toDouble(), size.height),
        paint..color = Colors.cyanAccent.withOpacity(0.03 + 0.03 * animation.value),
      );
    }

    for (var i = 0; i < rows; i++) {
      final y = i * gridSize;
      canvas.drawLine(
        Offset(0, y.toDouble()),
        Offset(size.width, y.toDouble()),
        paint..color = Colors.cyanAccent.withOpacity(0.03 + 0.03 * animation.value),
      );
    }

    // Draw random glowing points
    for (var i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1 + random.nextDouble() * 3;
      final opacity = 0.1 + random.nextDouble() * 0.3;

      canvas.drawCircle(
        Offset(x, y),
        radius * (0.8 + 0.4 * animation.value),
        paint
          ..color = Colors.cyanAccent.withOpacity(opacity * animation.value)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

