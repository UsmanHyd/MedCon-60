import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:medcon30/models/app_history.dart';
import 'package:medcon30/providers/app_history_provider.dart';
import 'package:intl/intl.dart';

class AppHistoryScreen extends ConsumerStatefulWidget {
  const AppHistoryScreen({super.key});

  @override
  ConsumerState<AppHistoryScreen> createState() => _AppHistoryScreenState();
}

class _AppHistoryScreenState extends ConsumerState<AppHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Disease Detection',
    'Vaccine Reminder',
    'Stress Monitoring',
    'Heart Disease Detection',
    'Nutrition & Fitness',
    'SOS Message',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final appHistoryState = ref.watch(appHistoryProvider);

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('App History'),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(appHistoryProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0288D1),
          unselectedLabelColor:
              isDarkMode ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: const Color(0xFF0288D1),
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Activities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(isDarkMode, appHistoryState),
          _buildActivitiesTab(isDarkMode, appHistoryState),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(
      bool isDarkMode, AsyncValue<List<AppHistoryActivity>> appHistoryState) {
    return appHistoryState.when(
      data: (activities) {
        final summary = AppHistorySummary.fromActivities(activities);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(
                isDarkMode,
                'Total Activities',
                '${summary.totalActivities}',
                Icons.history,
                const Color(0xFF0288D1),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      isDarkMode,
                      'This Week',
                      '${summary.thisWeekActivities}',
                      Icons.calendar_today,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      isDarkMode,
                      'This Month',
                      '${summary.thisMonthActivities}',
                      Icons.calendar_month,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Most Used Features',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureUsageChart(isDarkMode, summary.activitiesByType),
              const SizedBox(height: 24),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildRecentActivitiesList(
                  isDarkMode, activities.take(5).toList()),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildActivitiesTab(
      bool isDarkMode, AsyncValue<List<AppHistoryActivity>> appHistoryState) {
    return Column(
      children: [
        // Filter dropdown
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              isExpanded: true,
              dropdownColor:
                  isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              items: _filterOptions.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedFilter = newValue;
                  });
                }
              },
            ),
          ),
        ),

        // Activities list
        Expanded(
          child: appHistoryState.when(
            data: (activities) {
              final filteredActivities = _filterActivities(activities);

              if (filteredActivities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No activities found',
                        style: TextStyle(
                          fontSize: 18,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredActivities.length,
                itemBuilder: (context, index) {
                  final activity = filteredActivities[index];
                  return _buildActivityCard(isDarkMode, activity);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error',
                  style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      bool isDarkMode, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureUsageChart(
      bool isDarkMode, Map<ActivityType, int> activitiesByType) {
    if (activitiesByType.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No feature usage data available',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    final sortedEntries = activitiesByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: sortedEntries.take(5).map((entry) {
          final type = entry.key;
          final count = entry.value;
          final maxCount = sortedEntries.first.value.toDouble();
          final percentage = maxCount > 0 ? count / maxCount : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _getActivityTypeDisplayName(type),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor:
                        isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getActivityTypeColor(type),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivitiesList(
      bool isDarkMode, List<AppHistoryActivity> activities) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No recent activities',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) => Divider(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          height: 1,
        ),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityCard(isDarkMode, activity);
        },
      ),
    );
  }

  Widget _buildActivityCard(bool isDarkMode, AppHistoryActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getActivityTypeColor(activity.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getActivityTypeIcon(activity.type),
                  color: _getActivityTypeColor(activity.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      activity.typeDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: activity.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activity.statusDisplayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: activity.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            activity.description,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          if (activity.resultSummary != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Result: ${activity.resultSummary}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                activity.timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                activity.formattedTimestamp,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<AppHistoryActivity> _filterActivities(
      List<AppHistoryActivity> activities) {
    if (_selectedFilter == 'All') {
      return activities;
    }

    final filterMap = {
      'Disease Detection': ActivityType.diseaseDetection,
      'Vaccine Reminder': ActivityType.vaccineReminder,
      'Stress Monitoring': ActivityType.stressMonitoring,
      'Heart Disease Detection': ActivityType.heartDiseaseDetection,
      'Nutrition & Fitness': ActivityType.nutritionFitness,
      'SOS Message': ActivityType.sosMessage,
    };

    final selectedType = filterMap[_selectedFilter];
    if (selectedType == null) return activities;

    return activities
        .where((activity) => activity.type == selectedType)
        .toList();
  }

  Color _getActivityTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.diseaseDetection:
        return const Color(0xFF4CAF50);
      case ActivityType.vaccineReminder:
        return const Color(0xFF2196F3);
      case ActivityType.stressMonitoring:
        return const Color(0xFFFF9800);
      case ActivityType.heartDiseaseDetection:
        return const Color(0xFFE91E63);
      case ActivityType.nutritionFitness:
        return const Color(0xFF9C27B0);
      case ActivityType.sosMessage:
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF607D8B); // Default color for other types
    }
  }

  IconData _getActivityTypeIcon(ActivityType type) {
    switch (type) {
      case ActivityType.diseaseDetection:
        return Icons.local_hospital;
      case ActivityType.vaccineReminder:
        return Icons.vaccines;
      case ActivityType.stressMonitoring:
        return Icons.accessibility_new;
      case ActivityType.heartDiseaseDetection:
        return Icons.favorite;
      case ActivityType.nutritionFitness:
        return Icons.fitness_center;
      case ActivityType.sosMessage:
        return Icons.warning_amber_rounded;
      default:
        return Icons.info; // Default icon for other types
    }
  }

  String _getActivityTypeDisplayName(ActivityType type) {
    switch (type) {
      case ActivityType.diseaseDetection:
        return 'Disease Detection';
      case ActivityType.vaccineReminder:
        return 'Vaccine Reminder';
      case ActivityType.stressMonitoring:
        return 'Stress Monitoring';
      case ActivityType.heartDiseaseDetection:
        return 'Heart Disease Detection';
      case ActivityType.nutritionFitness:
        return 'Nutrition & Fitness';
      case ActivityType.sosMessage:
        return 'SOS Message';
      default:
        return 'Other Activity'; // Default name for other types
    }
  }
}
