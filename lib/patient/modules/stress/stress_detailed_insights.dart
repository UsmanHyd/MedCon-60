import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:medcon30/providers/stress_provider.dart';

class StressDetailedInsightsScreen extends ConsumerStatefulWidget {
  const StressDetailedInsightsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StressDetailedInsightsScreen> createState() =>
      _StressDetailedInsightsScreenState();
}

class _StressDetailedInsightsScreenState
    extends ConsumerState<StressDetailedInsightsScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Overview', 'Patterns', 'Trends', 'Categories'];

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _patternsKey = GlobalKey();
  final GlobalKey _trendsKey = GlobalKey();
  final GlobalKey _categoriesKey = GlobalKey();

  Future<void> _scrollToSection(int index) async {
    if (index == 0) {
      // Overview: scroll to top
      await _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      final contextMap = {
        1: _patternsKey,
        2: _trendsKey,
        3: _categoriesKey,
      };
      final key = contextMap[index];
      if (key != null && key.currentContext != null) {
        final box = key.currentContext!.findRenderObject() as RenderBox;
        final offset = box.localToGlobal(Offset.zero,
            ancestor: context.findRenderObject());
        final scrollOffset = _scrollController.offset +
            offset.dy -
            100; // 100 for tab bar height
        await _scrollController.animateTo(scrollOffset,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut);
      }
    }
    setState(() => _selectedTab = index);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor =
        isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF757575);
    final borderColor =
        isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Detailed Insights', style: TextStyle(color: textColor)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: bgColor,
        foregroundColor: textColor,
        scrolledUnderElevation: 0,
        surfaceTintColor: bgColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: bgColor,
      body: Column(
        children: [
          _TabBar(
            tabs: _tabs,
            selectedIndex: _selectedTab,
            onTabSelected: _scrollToSection,
            isDarkMode: isDarkMode,
            textColor: textColor,
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _WellnessScoreCard(
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 16),
                _SectionTitle('Activity Patterns',
                    key: _patternsKey, textColor: textColor),
                _ActivityPatternsCard(
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 16),
                _SectionTitle('Progress Trends',
                    key: _trendsKey, textColor: textColor),
                _TrendsChartCard(
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _TrendChip(
                          label: 'Most Improved',
                          value: 'Stress Education',
                          color: const Color(0xFF4ADE80),
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        const SizedBox(width: 8),
                        _TrendChip(
                          label: 'Needs Attention',
                          value: 'Sleep Improvement',
                          color: const Color(0xFFFFC107),
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle('Category Breakdown',
                    key: _categoriesKey, textColor: textColor),
                _CategoryBreakdownCard(
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 16),
                _SectionTitle('Performance Comparison', textColor: textColor),
                _PerformanceComparisonCard(
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 16),
                _SectionTitle('Personalized Recommendations',
                    textColor: textColor),
                _RecommendationsCard(
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 16),
                _SectionTitle('Your Action Plan', textColor: textColor),
                _ActionPlanCard(
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isDarkMode;
  final Color textColor;

  const _TabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.isDarkMode,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDarkMode ? const Color(0xFF121212) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(tabs.length, (i) {
            final selected = i == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () => onTabSelected(i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        selected ? const Color(0xFF7B61FF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF7B61FF)
                          : isDarkMode
                              ? const Color(0xFF2C2C2C)
                              : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      color: selected ? Colors.white : textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _WellnessScoreCard extends ConsumerWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _WellnessScoreCard({
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stressInsights = ref.watch(stressInsightsProvider);
    final recentEntries = ref.watch(recentStressEntriesProvider);
    
    // Calculate overall wellness score (inverse of stress - lower stress = higher wellness)
    double overallWellness = 1.0 - (stressInsights.averageScore / 10.0);
    overallWellness = overallWellness.clamp(0.0, 1.0);
    
    // Calculate stress management score (based on recent improvement)
    double stressManagementScore = 0.0;
    if (recentEntries.length >= 2) {
      final recent = recentEntries.take(3).toList();
      final older = recentEntries.skip(3).take(3).toList();
      if (older.isNotEmpty) {
        final recentAvg = recent.fold<int>(0, (sum, entry) => sum + entry.score) / recent.length;
        final olderAvg = older.fold<int>(0, (sum, entry) => sum + entry.score) / older.length;
        if (olderAvg > 0) {
          stressManagementScore = ((olderAvg - recentAvg) / olderAvg).clamp(0.0, 1.0);
        }
      }
    }
    
    // Get wellness level text
    String wellnessLevel = _getWellnessLevel(overallWellness);
    Color wellnessColor = _getWellnessColor(overallWellness);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      elevation: 1,
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Overall Wellness Score',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFF3F1FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${DateTime.now().month}/${DateTime.now().year}',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7B61FF),
                        fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CircularPercentIndicator(
                    radius: 54.0,
                    lineWidth: 8.0,
                    percent: overallWellness,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${(overallWellness * 100).round()}%',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: textColor)),
                        const SizedBox(height: 2),
                        Text(wellnessLevel,
                            style: TextStyle(
                                fontSize: 14,
                                color: wellnessColor,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    progressColor: wellnessColor,
                    backgroundColor: isDarkMode
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFF3F1FF),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ScoreItem(
                        label: 'Stress Management',
                        score: '${(stressManagementScore * 100).round()}%',
                        color: _getStressManagementColor(stressManagementScore),
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      const SizedBox(height: 12),
                      _ScoreItem(
                        label: 'Current Stress Level',
                        score: _getStressLevelText(stressInsights.overallLevel),
                        color: _getStressLevelColor(stressInsights.overallLevel),
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      const SizedBox(height: 12),
                      _ScoreItem(
                        label: 'Sleep Quality',
                        score: '70%',
                        color: const Color(0xFF7B9EFF),
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      const SizedBox(height: 12),
                      _ScoreItem(
                        label: 'Physical Activity',
                        score: '65%',
                        color: const Color(0xFFFFC107),
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWellnessLevel(double score) {
    if (score >= 0.8) {
      return 'Excellent';
    } else if (score >= 0.6) {
      return 'Good';
    } else if (score >= 0.4) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }

  Color _getWellnessColor(double score) {
    if (score >= 0.8) {
      return const Color(0xFF4ADE80); // Green
    } else if (score >= 0.6) {
      return const Color(0xFF7B9EFF); // Blue
    } else if (score >= 0.4) {
      return const Color(0xFFFFC107); // Orange
    } else {
      return const Color(0xFFFF4444); // Red
    }
  }

  Color _getStressManagementColor(double score) {
    if (score >= 0.7) {
      return const Color(0xFF4ADE80); // Green for good improvement
    } else if (score >= 0.4) {
      return const Color(0xFF7B9EFF); // Blue for moderate improvement
    } else if (score >= 0.1) {
      return const Color(0xFFFFC107); // Orange for slight improvement
    } else {
      return const Color(0xFFFF4444); // Red for no improvement
    }
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
        return const Color(0xFF4ADE80); // Green
      case StressLevel.moderate:
        return const Color(0xFF7B9EFF); // Blue
      case StressLevel.high:
        return const Color(0xFFFFC107); // Orange
      case StressLevel.severe:
        return const Color(0xFFFF4444); // Red
    }
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final String score;
  final Color color;
  final Color textColor;
  final Color subTextColor;

  const _ScoreItem({
    required this.label,
    required this.score,
    required this.color,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, color: subTextColor)),
        const SizedBox(width: 8),
        Text(score,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color textColor;

  const _SectionTitle(this.title, {Key? key, required this.textColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: textColor,
        ),
      ),
    );
  }
}

class _ActivityPatternsCard extends StatelessWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _ActivityPatternsCard({
    Key? key,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      elevation: 1,
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('Time of Day Analysis',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Spacer(),
                _ChipToggle(options: ['Week', 'Month'], selected: 0),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: _HeatmapWidget(subTextColor: subTextColor),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _InfoCard(
                  icon: Icons.access_time,
                  title: 'Peak Activity Time',
                  value: '8:00 - 11:00 AM',
                  subtitle: 'Most productive in mornings',
                  color: const Color(0xFF7B61FF),
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 12),
                _InfoCard(
                  icon: Icons.event_available,
                  title: 'Best Days',
                  value: 'Monday, Wednesday',
                  subtitle: 'Highest completion rate',
                  color: const Color(0xFF7B61FF),
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PatternInsightsCard(
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              borderColor: borderColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipToggle extends StatelessWidget {
  final List<String> options;
  final int selected;
  const _ChipToggle({required this.options, required this.selected});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (i) {
        final isSelected = i == selected;
        return Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF7B61FF)
                  : const Color(0xFFF3F1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              options[i],
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF7B61FF),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(fontSize: 12, color: subTextColor)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, color: subTextColor)),
          ],
        ),
      ),
    );
  }
}

class _PatternInsightsCard extends StatelessWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _PatternInsightsCard({
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF7B61FF), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "You're most consistent with morning activities, especially breathing exercises and stress education. Consider scheduling meditation sessions in the morning to improve completion rates. Your evening routine shows gaps that could be filled with sleep improvement activities.",
              style: TextStyle(fontSize: 13, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- HEATMAP WIDGET --------------------
class _HeatmapWidget extends StatelessWidget {
  final Color subTextColor;

  const _HeatmapWidget({required this.subTextColor});

  @override
  Widget build(BuildContext context) {
    // Mock data: 7 days x 5 time slots
    final data = [
      [2, 1, 0, 0, 0, 0, 0],
      [1, 2, 1, 0, 0, 0, 0],
      [0, 1, 2, 1, 0, 0, 0],
      [0, 0, 1, 2, 1, 0, 0],
      [0, 0, 0, 1, 2, 1, 0],
    ];
    final times = ['6', '8', '10', '12', '14'];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 32),
            ...days.map((d) => Expanded(
                child: Center(
                    child: Text(d,
                        style: TextStyle(fontSize: 11, color: subTextColor))))),
          ],
        ),
        SizedBox(
          height: 60, // fixed height for the heatmap grid
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: times
                    .map((t) => SizedBox(
                        height: 12,
                        child: Text(t,
                            style:
                                TextStyle(fontSize: 10, color: subTextColor))))
                    .toList(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  children: List.generate(data.length, (i) {
                    return SizedBox(
                      height: 12, // fixed height for each row
                      child: Row(
                        children: List.generate(data[i].length, (j) {
                          final v = data[i][j];
                          final color = v == 0
                              ? Colors.transparent
                              : Color.lerp(
                                  const Color(0xFF7B61FF).withOpacity(0.1),
                                  const Color(0xFF7B61FF),
                                  v / 2)!;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -------------------- PATTERNS TAB --------------------

// -------------------- TRENDS TAB --------------------

class _TrendsChartCard extends StatelessWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _TrendsChartCard({
    Key? key,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      elevation: 1,
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('Progress Trends',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Spacer(),
                _ChipToggle(options: ['Week', 'Month'], selected: 1),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData:
                      const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 28),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final weeks = ['W1', 'W2', 'W3', 'W4'];
                          return Text(weeks[value.toInt() % 4],
                              style: const TextStyle(fontSize: 11));
                        },
                        reservedSize: 24,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 3,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    _lineBar(
                        [60, 65, 70, 75], const Color(0xFF7B61FF)), // Breathing
                    _lineBar([40, 45, 50, 55],
                        const Color(0xFF7B9EFF)), // Meditation
                    _lineBar(
                        [50, 55, 60, 70], const Color(0xFF4ADE80)), // Physical
                    _lineBar(
                        [20, 20, 20, 20], const Color(0xFF0288D1)), // Sleep
                    _lineBar(
                        [60, 65, 70, 70], const Color(0xFFFFB74D)), // Stress Ed
                  ],
                  lineTouchData: const LineTouchData(enabled: true),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _LegendDot(color: Color(0xFF7B61FF), label: 'Breathing'),
                  _LegendDot(color: Color(0xFF7B9EFF), label: 'Meditation'),
                  _LegendDot(color: Color(0xFF4ADE80), label: 'Physical'),
                  _LegendDot(color: Color(0xFF0288D1), label: 'Sleep'),
                  _LegendDot(color: Color(0xFFFFB74D), label: 'Stress Ed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _lineBar(List<double> yVals, Color color) {
    return LineChartBarData(
      spots: List.generate(yVals.length, (i) => FlSpot(i.toDouble(), yVals[i])),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _TrendChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;
  final Color subTextColor;

  const _TrendChip({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: subTextColor,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}

// -------------------- CATEGORIES TAB --------------------

class _CategoryBreakdownCard extends StatelessWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _CategoryBreakdownCard({
    Key? key,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _CategoryCard(
          icon: Icons.spa_rounded,
          color: Color(0xFF7B9EFF),
          title: 'Breathing Exercises',
          percent: 0.75,
          strengths: [
            'Consistent deep breathing practice',
            'Morning routine established'
          ],
          improve: ['Box breathing technique', 'Evening practice consistency'],
          recent: 'Deep Breathing\n15 min • May 1, 2025',
          isDarkMode: true,
          cardColor: Color(0xFF1E1E1E),
          textColor: Colors.white,
          subTextColor: Colors.white,
          borderColor: Color(0xFF2C2C2C),
        ),
        const _CategoryCard(
          icon: Icons.self_improvement_rounded,
          color: Color(0xFF7B61FF),
          title: 'Meditation',
          percent: 0.5,
          strengths: [
            'Guided meditation completion',
            'Evening session consistency'
          ],
          improve: [
            'Morning meditation sessions',
            'Unguided meditation practice'
          ],
          recent: 'Guided Meditation\n20 min • April 30, 2025',
          isDarkMode: true,
          cardColor: Color(0xFF1E1E1E),
          textColor: Colors.white,
          subTextColor: Colors.white,
          borderColor: Color(0xFF2C2C2C),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Center(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7B61FF),
                side: const BorderSide(color: Color(0xFF7B61FF)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                backgroundColor: const Color(0xFFF3F1FF),
              ),
              child: const Text('View All Categories',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final double percent;
  final List<String> strengths;
  final List<String> improve;
  final String recent;
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _CategoryCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.percent,
    required this.strengths,
    required this.improve,
    required this.recent,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      elevation: 1,
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.13),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor)),
                const Spacer(),
                Text('${(percent * 100).toInt()}%',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.13),
              valueColor: AlwaysStoppedAnimation(color),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StrengthsAreasCard(
                    title: 'Strengths',
                    items: strengths,
                    color: color,
                    isDarkMode: isDarkMode,
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StrengthsAreasCard(
                    title: 'Areas to Improve',
                    items: improve,
                    color: color.withOpacity(0.7),
                    isDarkMode: isDarkMode,
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Recent Activity\n$recent',
                        style: TextStyle(fontSize: 13, color: textColor)),
                  ),
                  const SizedBox(width: 8),
                  const Text('Completed',
                      style: TextStyle(
                          color: Color(0xFF4ADE80),
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrengthsAreasCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _StrengthsAreasCard({
    required this.title,
    required this.items,
    required this.color,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          const SizedBox(height: 4),
          ...items.map((e) => Row(
                children: [
                  Icon(Icons.circle, size: 7, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(e,
                          style: TextStyle(fontSize: 12, color: textColor))),
                ],
              )),
        ],
      ),
    );
  }
}

class _PerformanceComparisonCard extends StatelessWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _PerformanceComparisonCard({
    Key? key,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      elevation: 1,
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('Current vs Previous Month',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Spacer(),
                _ChipToggle(options: ['May vs April'], selected: 0),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 180,
                width: 480,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    minY: 0,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 28),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final cats = [
                              'Stress Ed',
                              'Sleep',
                              'Physical',
                              'Meditation',
                              'Breathing'
                            ];
                            return Text(cats[value.toInt() % 5],
                                style: const TextStyle(fontSize: 11));
                          },
                          reservedSize: 32,
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      _barGroup(0, 80, 65),
                      _barGroup(1, 30, 20),
                      _barGroup(2, 60, 55),
                      _barGroup(3, 50, 40),
                      _barGroup(4, 70, 60),
                    ],
                    gridData:
                        const FlGridData(show: true, drawVerticalLine: false),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LegendDot(color: Color(0xFF7B61FF), label: 'May'),
                _LegendDot(color: Color(0xFF7B9EFF), label: 'April'),
              ],
            ),
            const SizedBox(height: 12),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TrendChip(
                      label: 'Improved',
                      value: 'Stress Education (+15%)',
                      color: Color(0xFF4ADE80),
                      textColor: Colors.white,
                      subTextColor: Colors.white),
                  SizedBox(width: 8),
                  _TrendChip(
                      label: 'Improved',
                      value: 'Breathing Exercises (+5%)',
                      color: Color(0xFF4ADE80),
                      textColor: Colors.white,
                      subTextColor: Colors.white),
                  SizedBox(width: 8),
                  _TrendChip(
                      label: 'Decreased',
                      value: 'Physical Activities (-5%)',
                      color: Color(0xFFFFC107),
                      textColor: Colors.white,
                      subTextColor: Colors.white),
                  SizedBox(width: 8),
                  _TrendChip(
                      label: 'Decreased',
                      value: 'Sleep Improvement (-2%)',
                      color: Color(0xFFFFC107),
                      textColor: Colors.white,
                      subTextColor: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
            toY: y1,
            color: const Color(0xFF7B61FF),
            width: 14,
            borderRadius: BorderRadius.circular(4)),
        BarChartRodData(
            toY: y2,
            color: const Color(0xFF7B9EFF),
            width: 14,
            borderRadius: BorderRadius.circular(4)),
      ],
      barsSpace: 4,
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _RecommendationsCard({
    Key? key,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      elevation: 1,
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Color(0xFF7B61FF)),
                SizedBox(width: 8),
                Text('AI-Powered Suggestions',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Based on your activity patterns and progress',
                style: TextStyle(fontSize: 13, color: subTextColor)),
            const SizedBox(height: 16),
            _RecommendationActionCard(
              icon: Icons.spa_rounded,
              title: 'Try Box Breathing',
              description:
                  'Your breathing exercises are consistent, but you haven\'t tried box breathing yet. This technique can help reduce stress and improve focus during busy workdays.',
              buttonText: 'Start Now',
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              borderColor: borderColor,
            ),
            _RecommendationActionCard(
              icon: Icons.nightlight_round,
              title: 'Focus on Sleep Routine',
              description:
                  'Your sleep improvement modules have the lowest completion rate. Try scheduling a 15-minute bedtime routine at 9:30 PM to improve sleep quality.',
              buttonText: 'Schedule',
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              borderColor: borderColor,
            ),
            _RecommendationActionCard(
              icon: Icons.self_improvement_rounded,
              title: 'Morning Meditation',
              description:
                  'You\'re most active in the mornings, but haven\'t tried morning meditation. Adding a 10-minute session at 8:00 AM could enhance your productivity throughout the day.',
              buttonText: 'Try It',
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              borderColor: borderColor,
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('View All Recommendations',
                    style: TextStyle(
                        color: Color(0xFF7B61FF), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _RecommendationActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7B61FF), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF7B61FF))),
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(fontSize: 13, color: textColor)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7B61FF),
                    side: const BorderSide(color: Color(0xFF7B61FF)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    backgroundColor: cardColor,
                  ),
                  child: Text(buttonText,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPlanCard extends StatelessWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _ActionPlanCard({
    Key? key,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      elevation: 1,
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Priority Tasks',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F1FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('May 1-7, 2025',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7B61FF),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _TaskTile(
                title: 'Complete Sleep Improvement module',
                subtitle: '15 min • Highest priority',
                isDarkMode: true,
                textColor: Colors.white,
                subTextColor: Colors.white),
            const _TaskTile(
                title: 'Try morning meditation session',
                subtitle: '10 min • Medium priority',
                isDarkMode: true,
                textColor: Colors.white,
                subTextColor: Colors.white),
            const _TaskTile(
                title: 'Practice box breathing technique',
                subtitle: '5 min • Medium priority',
                isDarkMode: true,
                textColor: Colors.white,
                subTextColor: Colors.white),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule, color: Color(0xFF7B61FF), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Based on your activity patterns, we recommend scheduling sleep improvement activities between 9:00-10:00 PM, meditation at 8:00 AM, and breathing exercises at 12:00 PM for optimal results.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF7B61FF)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDarkMode;
  final Color textColor;
  final Color subTextColor;

  const _TaskTile({
    required this.title,
    required this.subtitle,
    required this.isDarkMode,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: false,
          onChanged: (_) {
            // Handle checkbox change
          },
          activeColor: const Color(0xFF7B61FF),
          checkColor: Colors.white,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor)),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: subTextColor)),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: subTextColor),
      ],
    );
  }
}
