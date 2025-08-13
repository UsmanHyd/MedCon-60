import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'stress_detailed_insights.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:medcon30/providers/stress_provider.dart';

class StressTrackScreen extends ConsumerWidget {
  const StressTrackScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor =
        isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF757575);
    final shadowColor = isDarkMode
        ? Colors.black.withOpacity(0.2)
        : Colors.grey.withOpacity(0.08);

    // Get stress data from provider
    final stressInsights = ref.watch(stressInsightsProvider);
    final recentEntries = ref.watch(recentStressEntriesProvider);
    final stressTrend = ref.watch(stressTrendProvider);

    // Calculate progress percentage based on stress level (lower is better)
    double progressPercent = 1.0 - (stressInsights.averageScore / 10.0);
    progressPercent = progressPercent.clamp(0.0, 1.0);

    // Calculate streak (consecutive days with entries)
    int streak = _calculateStreak(recentEntries);

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Progress
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircularPercentIndicator(
                        radius: 40.0,
                        lineWidth: 8.0,
                        percent: progressPercent,
                        center: Text('${(progressPercent * 100).round()}%',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: textColor)),
                        progressColor: const Color(0xFF7B61FF),
                        backgroundColor: isDarkMode
                            ? const Color(0xFF2C2C2C)
                            : const Color(0xFFF3F1FF),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Overall Progress',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _StatColumn(
                                  label: 'Entries',
                                  value: '${stressInsights.totalEntries}',
                                  textColor: textColor,
                                  subTextColor: subTextColor),
                              const SizedBox(width: 16),
                              _StatColumn(
                                  label: 'Streak',
                                  value: '$streak days',
                                  textColor: textColor,
                                  subTextColor: subTextColor),
                              const SizedBox(width: 16),
                              _StatColumn(
                                  label: 'Level',
                                  value: _getStressLevelText(stressInsights.overallLevel),
                                  textColor: textColor,
                                  subTextColor: subTextColor),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Weekly Activity
              Text('Weekly Activity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: cardColor,
                child: SizedBox(
                  height: 180,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final weeklyData = _getWeeklyData(recentEntries);
                        
                        return BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 10,
                            minY: 0,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 11,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final days = weeklyData.keys.toList();
                                    if (value.toInt() < days.length) {
                                      return Text(
                                        days[value.toInt()],
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 11,
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: 2,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: isDarkMode
                                      ? const Color(0xFF2C2C2C)
                                      : const Color(0xFFE5E7EB),
                                  strokeWidth: 1,
                                );
                              },
                              drawVerticalLine: false,
                            ),
                            barGroups: weeklyData.values.toList().asMap().entries.map((entry) {
                              final index = entry.key;
                              final score = entry.value;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: score.toDouble(),
                                    color: _getStressColor(score),
                                    width: 20,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Category Progress
              Text('Category Progress',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
              const SizedBox(height: 8),
              _CategoryProgress(
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor),
              const SizedBox(height: 16),
              // Recent Activity
              Text('Recent Activity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
              const SizedBox(height: 8),
              _RecentActivity(
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor),
              const SizedBox(height: 16),
              // Achievements
              Text('Achievements',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
              const SizedBox(height: 8),
              _Achievements(
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor),
              const SizedBox(height: 16),
              // Insights
              Text('Insights',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
              const SizedBox(height: 8),
              _Insights(
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to calculate streak
  int _calculateStreak(List<StressData> entries) {
    if (entries.isEmpty) return 0;

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    int streak = 1;
    DateTime currentDate = entries.first.timestamp;

    for (var entry in entries) {
      if (entry.timestamp.isAfter(currentDate.subtract(const Duration(days: 1)))) {
        streak++;
        currentDate = entry.timestamp;
      } else {
        break;
      }
    }
    return streak;
  }

  // Helper to get weekly data for the chart
  Map<String, int> _getWeeklyData(List<StressData> entries) {
    final Map<String, int> weeklyScores = {};
    final DateTime now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final entriesForDay = entries.where((entry) => 
        entry.timestamp.year == date.year && 
        entry.timestamp.month == date.month && 
        entry.timestamp.day == date.day
      ).toList();
      
      if (entriesForDay.isNotEmpty) {
        weeklyScores[date.toString().split(' ')[0]] = entriesForDay.first.score;
      } else {
        weeklyScores[date.toString().split(' ')[0]] = 0; // No entry for the day
      }
    }
    return weeklyScores;
  }

  // Helper to get stress color based on score
  Color _getStressColor(int score) {
    if (score <= 3) {
      return const Color(0xFF4ADE80); // Green for low stress
    } else if (score <= 6) {
      return const Color(0xFFF59E0B); // Orange for moderate stress
    } else if (score <= 8) {
      return const Color(0xFFEF4444); // Red for high stress
    } else {
      return const Color(0xFF7B61FF); // Default color for very high
    }
  }

  // Helper to get stress level text
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
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color subTextColor;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: subTextColor)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
      ],
    );
  }
}

class _CategoryProgress extends StatelessWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _CategoryProgress({
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CategoryTile(
          icon: Icons.spa_rounded,
          color: const Color(0xFF7B61FF),
          title: 'Breathing Exercises',
          percent: 0.75,
          lastSession: 'Deep Breathing, 15 min (May 1, 2025)',
          isDarkMode: isDarkMode,
          cardColor: cardColor,
          textColor: textColor,
          subTextColor: subTextColor,
        ),
        _CategoryTile(
          icon: Icons.self_improvement_rounded,
          color: const Color(0xFF7B9EFF),
          title: 'Meditation',
          percent: 0.5,
          lastSession: 'Guided Meditation, 20 min (Apr 30, 2025)',
          isDarkMode: isDarkMode,
          cardColor: cardColor,
          textColor: textColor,
          subTextColor: subTextColor,
        ),
        _CategoryTile(
          icon: Icons.directions_run_rounded,
          color: const Color(0xFF4ADE80),
          title: 'Physical Activities',
          percent: 0.6,
          lastSession: 'Stretching, 10 min (Apr 29, 2025)',
          isDarkMode: isDarkMode,
          cardColor: cardColor,
          textColor: textColor,
          subTextColor: subTextColor,
        ),
        _CategoryTile(
          icon: Icons.nightlight_round,
          color: const Color(0xFF7B61FF),
          title: 'Sleep Improvement',
          percent: 0.2,
          lastSession: 'Bedtime Routine, 15 min (Apr 28, 2025)',
          isDarkMode: isDarkMode,
          cardColor: cardColor,
          textColor: textColor,
          subTextColor: subTextColor,
        ),
        _CategoryTile(
          icon: Icons.psychology_rounded,
          color: const Color(0xFF7B9EFF),
          title: 'Stress Education',
          percent: 0.8,
          lastSession: 'Understanding Stress, 25 min (May 1, 2025)',
          isDarkMode: isDarkMode,
          cardColor: cardColor,
          textColor: textColor,
          subTextColor: subTextColor,
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final double percent;
  final String lastSession;
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _CategoryTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.percent,
    required this.lastSession,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor)),
                      const Spacer(),
                      Text('${(percent * 100).toInt()}%',
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearPercentIndicator(
                    lineHeight: 6.0,
                    percent: percent,
                    progressColor: color,
                    backgroundColor: isDarkMode
                        ? const Color(0xFF2C2C2C)
                        : color.withOpacity(0.1),
                    barRadius: const Radius.circular(8),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 4),
                  Text('Last session: $lastSession',
                      style: TextStyle(fontSize: 12, color: subTextColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _RecentActivity({
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _ActivityTile(
              icon: Icons.spa_rounded,
              color: const Color(0xFF7B61FF),
              title: 'Deep Breathing',
              subtitle: '15 minutes session',
              time: 'Today 10:30 AM',
              status: 'Completed',
              statusColor: const Color(0xFF4ADE80),
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            _ActivityTile(
              icon: Icons.psychology_rounded,
              color: const Color(0xFF7B9EFF),
              title: 'Understanding Stress',
              subtitle: '25 minutes session',
              time: 'Today 8:15 AM',
              status: 'Completed',
              statusColor: const Color(0xFF4ADE80),
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            _ActivityTile(
              icon: Icons.self_improvement_rounded,
              color: const Color(0xFF7B61FF),
              title: 'Guided Meditation',
              subtitle: '20 minutes session',
              time: 'Yesterday 9:45 PM',
              status: 'Completed',
              statusColor: const Color(0xFF4ADE80),
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            _ActivityTile(
              icon: Icons.directions_run_rounded,
              color: const Color(0xFF4ADE80),
              title: 'Stretching',
              subtitle: '10 minutes session',
              time: 'Apr 29 7:30 AM',
              status: 'Partial',
              statusColor: const Color(0xFF7B9EFF),
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {},
              child: const Text('View All Activity',
                  style: TextStyle(color: Color(0xFF7B61FF))),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final String status;
  final Color statusColor;
  final Color textColor;
  final Color subTextColor;

  const _ActivityTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.status,
    required this.statusColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color)),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(color: subTextColor)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: TextStyle(fontSize: 12, color: subTextColor)),
          const SizedBox(height: 2),
          Text(status,
              style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.bold)),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
    );
  }
}

class _Achievements extends StatelessWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _Achievements({
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _AchievementTile(
              icon: Icons.emoji_events_rounded,
              color: const Color(0xFF7B61FF),
              title: '8-Day Streak',
              subtitle: 'Keep going! You\'re building a great habit.',
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            _AchievementTile(
              icon: Icons.emoji_events_rounded,
              color: const Color(0xFF7B9EFF),
              title: 'Stress Expert',
              subtitle: 'Completed 80% of Stress Education modules.',
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            _AchievementTile(
              icon: Icons.emoji_events_rounded,
              color: const Color(0xFF4ADE80),
              title: 'Breathing Master',
              subtitle: 'Completed 75% of Breathing Exercises.',
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {},
              child: const Text('View All Achievements',
                  style: TextStyle(color: Color(0xFF7B61FF))),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color subTextColor;

  const _AchievementTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color)),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(color: subTextColor)),
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
    );
  }
}

class _Insights extends StatelessWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _Insights({
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Progress',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor)),
            const SizedBox(height: 12),
            Text(
              'You\'ve made great progress in managing your stress levels. Your consistency in practicing breathing exercises and meditation has shown positive results.',
              style: TextStyle(fontSize: 14, color: subTextColor),
            ),
            const SizedBox(height: 16),
            Text('Recommendations',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor)),
            const SizedBox(height: 12),
            Text(
              'Try to maintain your current routine and consider adding more physical activities to your schedule.',
              style: TextStyle(fontSize: 14, color: subTextColor),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StressDetailedInsightsScreen(),
                  ),
                );
              },
              child: const Text('View Detailed Insights',
                  style: TextStyle(color: Color(0xFF7B61FF))),
            ),
          ],
        ),
      ),
    );
  }
}
