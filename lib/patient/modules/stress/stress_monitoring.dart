import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:medcon30/providers/stress_provider.dart';
import 'stress_module.dart';
import 'stress_track.dart';
import 'stress_detailed_insights.dart';
import 'stress_survey.dart';

class StressMonitoringScreen extends ConsumerStatefulWidget {
  const StressMonitoringScreen({super.key});

  @override
  ConsumerState<StressMonitoringScreen> createState() => _StressMonitoringScreenState();
}

class _StressMonitoringScreenState extends ConsumerState<StressMonitoringScreen> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildHomeContent() {
    final isDarkMode = provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor =
        isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF757575);
    final shadowColor = isDarkMode
        ? Colors.black.withOpacity(0.2)
        : Colors.grey.withOpacity(0.08);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stress Insights Section
            Consumer(
              builder: (context, ref, child) {
                final stressInsights = ref.watch(stressInsightsProvider);
                final recentEntries = ref.watch(recentStressEntriesProvider);
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.insights,
                            color: const Color(0xFF7B61FF),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stress Insights',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (recentEntries.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildInsightCard(
                                'Current Level',
                                _getStressLevelText(stressInsights.overallLevel),
                                _getStressLevelColor(stressInsights.overallLevel),
                                textColor,
                                subTextColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInsightCard(
                                'Average Score',
                                '${stressInsights.averageScore.toStringAsFixed(1)}/10',
                                const Color(0xFF4ADE80),
                                textColor,
                                subTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (stressInsights.recommendation.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode 
                                  ? const Color(0xFF2C2C2C) 
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              stressInsights.recommendation,
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode 
                                ? const Color(0xFF2C2C2C) 
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'No stress data yet. Take a survey to get started!',
                            style: TextStyle(
                              fontSize: 14,
                              color: subTextColor,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            // Actions Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _mainCard(
                    icon: Icons.assignment,
                    iconColor: const Color(0xFF7B61FF),
                    title: 'Take Stress Survey',
                    description: 'Assess your current stress levels',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SurveyScreen(),
                        ),
                      );
                    },
                    cardColor: Colors.transparent,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    shadowColor: Colors.transparent,
                  ),
                  const SizedBox(height: 12),
                  _mainCard(
                    icon: Icons.psychology,
                    iconColor: const Color(0xFF7B9EFF),
                    title: 'Relief Strategies',
                    description: 'Discover techniques to reduce stress',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: const Text('Stress Modules'),
                              backgroundColor: cardColor,
                              foregroundColor: textColor,
                              elevation: 0,
                            ),
                            body: const StressModulesScreen(),
                          ),
                        ),
                      );
                    },
                    cardColor: Colors.transparent,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    shadowColor: Colors.transparent,
                  ),
                  const SizedBox(height: 12),
                  _mainCard(
                    icon: Icons.show_chart,
                    iconColor: const Color(0xFF4ADE80),
                    title: 'Track Progress',
                    description: 'Monitor your improvement over time',
                    onTap: () {
                      _onTabChanged(2); // Switch to Track tab (index 2)
                    },
                    cardColor: Colors.transparent,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    shadowColor: Colors.transparent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recent Activity Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _activityCard(
                    icon: Icons.self_improvement,
                    iconColor: const Color(0xFF7B9EFF),
                    title: '5-min Breathing Exercise',
                    subtitle: 'Completed yesterday',
                    cardColor: Colors.transparent,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    shadowColor: Colors.transparent,
                  ),
                  const SizedBox(height: 8),
                  _activityCard(
                    icon: Icons.assignment,
                    iconColor: const Color(0xFF7B61FF),
                    title: 'Stress Survey',
                    subtitle: 'Completed 3 days ago',
                    cardColor: Colors.transparent,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    shadowColor: Colors.transparent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _dailyTipCard(
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              shadowColor: shadowColor,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Stress Management'
              : _currentIndex == 1
                  ? 'Stress Modules'
                  : 'Progress Tracking',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline,
                color: isDarkMode
                    ? const Color(0xFFB0B0B0)
                    : const Color(0xFF757575)),
            onPressed: () {},
          ),
        ],
      ),
      body: _currentIndex == 1
          ? const StressModulesScreen()
          : _currentIndex == 2
              ? const StressTrackScreen()
              : _buildHomeContent(),
      bottomNavigationBar: AnimatedCurveNavBar(
        onTabChanged: _onTabChanged,
        initialIndex: _currentIndex,
        items: const [
          NavBarItem(
            icon: Icons.home,
            label: "Home",
            highlightColor: Color(0xFF0288D1),
          ),
          NavBarItem(
            icon: Icons.view_module,
            label: "Modules",
            highlightColor: Color(0xFF0288D1),
          ),
          NavBarItem(
            icon: Icons.show_chart,
            label: "Track",
            highlightColor: Color(0xFF0288D1),
          ),
        ],
      ),
    );
  }

  Widget _mainCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color shadowColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: cardColor == Colors.transparent
            ? null
            : BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: TextStyle(fontSize: 13, color: subTextColor)),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: subTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color shadowColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: cardColor == Colors.transparent
          ? null
          : BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 13, color: subTextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyTipCard({
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color shadowColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: Color(0xFF7B61FF), size: 24),
              const SizedBox(width: 8),
              Text('Daily Tip',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Take a 5-minute break every hour to stretch and breathe deeply. This helps reduce stress and improve focus.',
            style: TextStyle(fontSize: 14, color: subTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, Color color, Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: subTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getStressLevelText(StressLevel level) {
    switch (level) {
      case StressLevel.low:
        return 'Low';
      case StressLevel.moderate:
        return 'Moderate';
      case StressLevel.high:
        return 'High';
      case StressLevel.severe:
        return 'Very High';
    }
  }

  Color _getStressLevelColor(StressLevel level) {
    switch (level) {
      case StressLevel.low:
        return const Color(0xFF4ADE80); // Green for low
      case StressLevel.moderate:
        return const Color(0xFFF59E0B); // Orange for moderate
      case StressLevel.high:
        return const Color(0xFFEF4444); // Red for high
      case StressLevel.severe:
        return const Color(0xFFEF4444); // Red for very high
    }
  }
}

class NavBarItem {
  final IconData icon;
  final String label;
  final Color highlightColor;

  const NavBarItem({
    required this.icon,
    required this.label,
    required this.highlightColor,
  });
}

class AnimatedCurveNavBar extends StatefulWidget {
  final Function(int) onTabChanged;
  final int initialIndex;
  final List<NavBarItem> items;

  const AnimatedCurveNavBar({
    super.key,
    required this.onTabChanged,
    required this.items,
    this.initialIndex = 0,
  });

  @override
  State<AnimatedCurveNavBar> createState() => _AnimatedCurveNavBarState();
}

class _AnimatedCurveNavBarState extends State<AnimatedCurveNavBar>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _positionAnimation = Tween<double>(
      begin: _getPositionForIndex(_selectedIndex),
      end: _getPositionForIndex(_selectedIndex),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _getPositionForIndex(int index) {
    final count = widget.items.length;
    const width = 1.0;
    final itemWidth = width / count;
    return itemWidth * (index + 0.5);
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    _positionAnimation = Tween<double>(
      begin: _positionAnimation.value,
      end: _getPositionForIndex(index),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(from: 0.0);

    setState(() {
      _selectedIndex = index;
    });

    widget.onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _positionAnimation,
      builder: (context, _) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background with curve
              Positioned.fill(
                child: CustomPaint(
                  painter: CurveNavBarPainter(
                    position: _positionAnimation.value,
                    backgroundColor: const Color(0xFF0288D1),
                  ),
                ),
              ),

              // Tab items (with selected item hidden)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(widget.items.length, (index) {
                    final item = widget.items[index];
                    final isSelected = index == _selectedIndex;

                    return SizedBox(
                      width: 80,
                      child: !isSelected
                          ? GestureDetector(
                              onTap: () => _onTabTapped(index),
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.icon,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(height: 24),
                    );
                  }),
                ),
              ),

              // Floating selected item button
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment(2 * _positionAnimation.value - 1, 0),
                  child: GestureDetector(
                    onTap: () => _onTabTapped(_selectedIndex),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.items[_selectedIndex].icon,
                        color: const Color(0xFF0288D1),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CurveNavBarPainter extends CustomPainter {
  final double position;
  final Color backgroundColor;

  CurveNavBarPainter({required this.position, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final centerX = size.width * position;
    const curveWidth = 70.0;
    const curveHeight = 20.0;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(centerX - curveWidth / 2, 0);
    path.quadraticBezierTo(centerX, curveHeight, centerX + curveWidth / 2, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CurveNavBarPainter oldDelegate) {
    return position != oldDelegate.position ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
