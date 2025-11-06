import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/patient_dashboard.dart';
import 'package:medcon30/patient/modules/nutrition/plan.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:medcon30/providers/nutrition_provider.dart';
import 'nutrition_fitness_todaysplan.dart';
import 'health_info_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcon30/services/firestore_service.dart';

class NutritionFitnessScreen extends ConsumerStatefulWidget {
  const NutritionFitnessScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NutritionFitnessScreen> createState() =>
      _NutritionFitnessScreenState();
}

class _NutritionFitnessScreenState
    extends ConsumerState<NutritionFitnessScreen> {
  String? _userName;
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _loadSavedPlan();
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoadingName = false;
          _userName = 'User';
        });
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        String? name = (data['name'] as String?)?.trim();
        setState(() {
          _userName = (name != null && name.isNotEmpty) ? name : 'User';
          _isLoadingName = false;
        });
      } else {
        setState(() {
          _userName = 'User';
          _isLoadingName = false;
        });
      }
    } catch (e) {
      print('Error fetching user name: $e');
      setState(() {
        _userName = 'User';
        _isLoadingName = false;
      });
    }
  }

  Future<void> _loadSavedPlan() async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final savedPlanData = await firestoreService.getSavedWeeklyPlan();

      if (savedPlanData != null) {
        final weeklyPlanNotifier =
            ref.read(weeklyPlanNotifierProvider.notifier);
        final weeklyPlan = _parseWeeklyPlanFromSavedData(savedPlanData);
        if (weeklyPlan != null) {
          weeklyPlanNotifier.setWeeklyPlan(weeklyPlan);
        }
      }
    } catch (e) {
      print('Error loading saved plan on init: $e');
    }
  }

  WeeklyPlan? _parseWeeklyPlanFromSavedData(Map<String, dynamic> data) {
    try {
      final dietPlan = <String, DayPlan>{};
      if (data['dietPlan'] != null) {
        final dietData = data['dietPlan'] as Map<String, dynamic>;
        for (final entry in dietData.entries) {
          final dayData = entry.value as Map<String, dynamic>;
          dietPlan[entry.key] = _parseDayPlan(dayData);
        }
      }

      final exercisePlan = <String, DayExercisePlan>{};
      if (data['exercisePlan'] != null) {
        final exerciseData = data['exercisePlan'] as Map<String, dynamic>;
        for (final entry in exerciseData.entries) {
          final dayData = entry.value as Map<String, dynamic>;
          exercisePlan[entry.key] = DayExercisePlan(
            day: entry.key,
            morning: dayData['morning'] != null
                ? _parseExerciseSession(dayData['morning'])
                : null,
            evening: dayData['evening'] != null
                ? _parseExerciseSession(dayData['evening'])
                : null,
          );
        }
      }

      final summaryData = data['summary'] as Map<String, dynamic>? ?? {};
      final summary = WeeklySummary(
        totalCaloriesPerDay: summaryData['totalCaloriesPerDay'] ?? 2000,
        totalWorkoutTimePerDay:
            summaryData['totalWorkoutTimePerDay'] ?? '30 minutes',
        keyGoals: List<String>.from(summaryData['keyGoals'] ?? []),
        tips: List<String>.from(summaryData['tips'] ?? []),
      );

      return WeeklyPlan(
        id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        dietPlan: dietPlan,
        exercisePlan: exercisePlan,
        summary: summary,
        createdAt: DateTime.tryParse(
                data['createdAt'] ?? DateTime.now().toIso8601String()) ??
            DateTime.now(),
      );
    } catch (e) {
      print('Error parsing saved plan: $e');
      return null;
    }
  }

  MealPlan _parseMealPlan(Map<String, dynamic> mealData) {
    final foods = <FoodItem>[];
    if (mealData['foods'] != null) {
      for (final foodData in mealData['foods']) {
        foods.add(FoodItem(
          name: foodData['name'] ?? 'Unknown',
          quantity: (foodData['quantity'] ?? 1).toDouble(),
          unit: foodData['unit'] ?? 'serving',
          calories: foodData['calories'] ?? 0,
          nutrients: Map<String, double>.from(foodData['nutrients'] ?? {}),
        ));
      }
    }

    return MealPlan(
      name: mealData['name'] ?? 'Meal',
      foods: foods,
      calories: mealData['calories'] ?? 0,
    );
  }

  DayPlan _parseDayPlan(Map<String, dynamic> dayData) {
    return DayPlan(
      day: dayData['day'] ?? '',
      breakfast: _parseMealPlan(dayData['breakfast'] ?? {}),
      lunch: _parseMealPlan(dayData['lunch'] ?? {}),
      dinner: _parseMealPlan(dayData['dinner'] ?? {}),
      snacks:
          dayData['snacks'] != null ? _parseMealPlan(dayData['snacks']) : null,
    );
  }

  ExerciseSession _parseExerciseSession(Map<String, dynamic> sessionData) {
    return ExerciseSession(
      name: sessionData['name'] ?? 'Exercise',
      exercises: List<String>.from(sessionData['exercises'] ?? []),
      duration: sessionData['duration'] ?? '30 minutes',
      calories: sessionData['calories'] ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
    final borderColor =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFBDBDBD);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: cardColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDarkMode ? Colors.white : const Color(0xFF0288D1)),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Fitness Screen',
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF0288D1),
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoadingName)
                          Text('Loading...',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: textColor))
                        else
                          Text('Hi, $_userName!',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: textColor)),
                        const SizedBox(height: 2),
                        Text("Let's achieve your goals today",
                            style:
                                TextStyle(color: subTextColor, fontSize: 15)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Quick Actions
              Text('Quick Actions',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
              const SizedBox(height: 10),
              _QuickActionsGrid(),
              const SizedBox(height: 18),
              // Today's Plan
              Text("Today's Plan",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
              const SizedBox(height: 10),
              const TodaysPlanSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    // Get real data from nutrition provider
    final todayActivities = ref.watch(todayActivitiesProvider);
    final todayCaloriesBurned = ref.watch(todayCaloriesBurnedProvider);
    final nutritionPlans = ref.watch(nutritionProvider);
    // Calculate progress based on real data
    final totalCaloriesBurned = todayCaloriesBurned;
    final targetCalories = 500; // Daily target for calories burned
    final progressPercent =
        (totalCaloriesBurned / targetCalories).clamp(0.0, 1.0);
    // Get today's nutrition plan if available
    String nutritionStatus = 'No plan today';
    if (nutritionPlans.hasValue && nutritionPlans.value!.isNotEmpty) {
      nutritionStatus = 'Plan available';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF2B4C8C), const Color(0xFF3D2B8C)]
              : [const Color(0xFF4F8CFF), const Color(0xFF7B61FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Today\'s Progress',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: const Icon(Icons.emoji_events,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('${(progressPercent * 100).round()}%',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 32)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ProgressStat(
                  label: 'Calories Burned',
                  value: '$totalCaloriesBurned/$targetCalories'),
              _ProgressStat(
                  label: 'Activities', value: '${todayActivities.length}'),
              _ProgressStat(label: 'Nutrition', value: nutritionStatus),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProgressStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDarkMode ? 0.1 : 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.access_time,
              color: isDarkMode
                  ? const Color(0xFF7B9EFF)
                  : const Color(0xFF4F8CFF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next up in 30 mins',
                    style: TextStyle(color: Colors.green, fontSize: 13)),
                const SizedBox(height: 2),
                Text('Morning Workout',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor)),
                const SizedBox(height: 2),
                Text('30 min cardio session',
                    style: TextStyle(color: subTextColor, fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F8CFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _QuickActionCard(
          color: isDarkMode ? const Color(0xFF2C1E1E) : const Color(0xFFFFE5E5),
          icon: Icons.favorite_border,
          title: 'Health Info',
          subtitle: 'Update metrics',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const HealthInformationForm()),
            );
          },
        ),
        _QuickActionCard(
          color: isDarkMode ? const Color(0xFF1E2C1E) : const Color(0xFFE5FFF3),
          icon: Icons.restaurant_menu,
          title: 'View Plan',
          subtitle: 'View & track',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlanScreen()),
            );
          },
        ),
        _QuickActionCard(
          color: isDarkMode ? const Color(0xFF1E1E2C) : const Color(0xFFE5F0FF),
          icon: Icons.trending_up,
          title: 'Track Progress',
          subtitle: 'Monitor your journey',
          onTap: () {
            // TODO: Navigate to progress tracking screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Track Progress feature coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _QuickActionCard(
      {required this.color,
      required this.icon,
      required this.title,
      required this.subtitle,
      this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: subTextColor, size: 28),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: subTextColor, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}


class SetYourGoalsScreen extends StatefulWidget {
  const SetYourGoalsScreen({Key? key}) : super(key: key);
  @override
  State<SetYourGoalsScreen> createState() => _SetYourGoalsScreenState();
}

class _SetYourGoalsScreenState extends State<SetYourGoalsScreen> {
  int selectedGoal = 0;
  int programWeeks = 8;
  final List<String> goals = ['Weight Loss', 'Muscle Gain', 'Healthy Eating'];
  final List<IconData> goalIcons = [
    Icons.fitness_center,
    Icons.add_box,
    Icons.restaurant_menu
  ];
  final DateTime startDate = DateTime(2025, 5, 10);
  final DateTime endDate = DateTime(2025, 7, 5);
  final TextEditingController targetWeightController = TextEditingController();
  final TextEditingController calorieTargetController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
    final borderColor =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFBDBDBD);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: cardColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDarkMode ? Colors.white : const Color(0xFF0288D1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Set Your Goals',
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF0288D1),
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar and step
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor:
                        isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[300],
                    color: const Color(0xFF4F8CFF),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 10),
                Text('2/2',
                    style: TextStyle(
                        color: subTextColor, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 18),
            Text("What's your primary goal?",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                goals.length,
                (i) => _GoalOption(
                  icon: goalIcons[i],
                  label: goals[i],
                  selected: selectedGoal == i,
                  onTap: () => setState(() => selectedGoal = i),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Timeline',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text('Program Duration',
                      style: TextStyle(
                          fontWeight: FontWeight.w500, color: textColor)),
                  const Spacer(),
                  IconButton(
                    icon:
                        Icon(Icons.remove_circle_outline, color: subTextColor),
                    onPressed: () {
                      setState(() {
                        if (programWeeks > 1) programWeeks--;
                      });
                    },
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFF3F6FD),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text('$programWeeks weeks',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: textColor)),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: subTextColor),
                    onPressed: () {
                      setState(() {
                        programWeeks++;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start Date', style: TextStyle(color: subTextColor)),
                Text(_formatDate(startDate),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('End Date', style: TextStyle(color: subTextColor)),
                Text(_formatDate(endDate),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Target Metrics',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor)),
            const SizedBox(height: 10),
            Text('Target Weight (kg)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor)),
            const SizedBox(height: 6),
            TextField(
              controller: targetWeightController,
              decoration: InputDecoration(
                hintText: 'Enter target weight',
                hintStyle: TextStyle(color: subTextColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF4F8CFF)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: cardColor,
              ),
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Text('Daily Calorie Target',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor)),
            const SizedBox(height: 6),
            TextField(
              controller: calorieTargetController,
              decoration: InputDecoration(
                hintText: 'Enter daily calorie target',
                hintStyle: TextStyle(color: subTextColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF4F8CFF)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: cardColor,
              ),
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlanScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2056F7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Generate My Plan',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month];
  }
}

class _GoalOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GoalOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
    final borderColor =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFBDBDBD);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF4F8CFF) : cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF4F8CFF) : borderColor,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : subTextColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : textColor,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivities extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
    // Get real fitness activities from provider
    final recentActivities = ref.watch(recentFitnessActivitiesProvider);
    if (recentActivities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 48,
              color: subTextColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No activities yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your fitness journey by logging your first activity',
              style: TextStyle(
                fontSize: 14,
                color: subTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        ...recentActivities.take(3).map((activity) => Column(
              children: [
                _ActivityTile(
                  icon: _getActivityIcon(activity.type),
                  color: _getActivityColor(activity.type),
                  title: activity.name,
                  subtitle:
                      '${_formatDate(activity.date)} • ${activity.caloriesBurned} kcal burned',
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                if (activity != recentActivities.take(3).last)
                  const SizedBox(height: 8),
              ],
            )),
      ],
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cardio':
        return Icons.directions_run_rounded;
      case 'strength':
        return Icons.fitness_center;
      case 'flexibility':
        return Icons.self_improvement;
      case 'sports':
        return Icons.sports_basketball;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'cardio':
        return const Color(0xFF4F8CFF);
      case 'strength':
        return const Color(0xFF7B61FF);
      case 'flexibility':
        return const Color(0xFF4ADE80);
      case 'sports':
        return const Color(0xFFFF6B35);
      default:
        return const Color(0xFF7B61FF);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDate = DateTime(date.year, date.month, date.day);
    if (activityDate == today) {
      return 'Today, ${_formatTime(date)}';
    } else if (activityDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}, ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  const _ActivityTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });
  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDarkMode ? 0.1 : 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(isDarkMode ? 0.2 : 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textColor)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: subTextColor)),
            ],
          ),
        ],
      ),
    );
  }
}
