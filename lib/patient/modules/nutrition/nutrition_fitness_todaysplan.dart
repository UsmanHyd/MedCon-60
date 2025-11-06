import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:medcon30/providers/nutrition_provider.dart';

class TodaysPlanSection extends ConsumerWidget {
  const TodaysPlanSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
    final borderColor =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);

    final weeklyPlan = ref.watch(weeklyPlanProvider);

    // Get today's day name (monday, tuesday, etc.)
    final today = DateTime.now();
    final dayOfWeek = today.weekday;
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final todayDayName = dayNames[dayOfWeek - 1];

    if (weeklyPlan == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: subTextColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No plan available for today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate a personalized plan to get started',
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

    final todaysDietPlan = weeklyPlan.dietPlan[todayDayName];
    final todaysExercisePlan = weeklyPlan.exercisePlan[todayDayName];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meal Plan Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: todaysDietPlan != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.restaurant_menu,
                            color: const Color(0xFF4F8CFF), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Today\'s Meals',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMealRow(
                        'Breakfast',
                        todaysDietPlan.breakfast.name,
                        todaysDietPlan.breakfast.calories,
                        textColor,
                        subTextColor,
                        context,
                        isDarkMode),
                    const SizedBox(height: 8),
                    _buildMealRow(
                        'Lunch',
                        todaysDietPlan.lunch.name,
                        todaysDietPlan.lunch.calories,
                        textColor,
                        subTextColor,
                        context,
                        isDarkMode),
                    const SizedBox(height: 8),
                    _buildMealRow(
                        'Dinner',
                        todaysDietPlan.dinner.name,
                        todaysDietPlan.dinner.calories,
                        textColor,
                        subTextColor,
                        context,
                        isDarkMode),
                    if (todaysDietPlan.snacks != null) ...[
                      const SizedBox(height: 8),
                      _buildMealRow(
                          'Snacks',
                          todaysDietPlan.snacks!.name,
                          todaysDietPlan.snacks!.calories,
                          textColor,
                          subTextColor,
                          context,
                          isDarkMode),
                    ],
                  ],
                )
              : Center(
                  child: Text(
                    'No meal plan for today',
                    style: TextStyle(color: subTextColor),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        // Exercise Plan Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: todaysExercisePlan != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fitness_center,
                            color: const Color(0xFF7B61FF), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Today\'s Workouts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (todaysExercisePlan.morning != null)
                      _buildExerciseRow('Morning', todaysExercisePlan.morning!,
                          textColor, subTextColor, context, isDarkMode),
                    if (todaysExercisePlan.morning != null &&
                        todaysExercisePlan.evening != null)
                      const SizedBox(height: 8),
                    if (todaysExercisePlan.evening != null)
                      _buildExerciseRow('Evening', todaysExercisePlan.evening!,
                          textColor, subTextColor, context, isDarkMode),
                    if (todaysExercisePlan.morning == null &&
                        todaysExercisePlan.evening == null)
                      Center(
                        child: Text(
                          'Rest day - No workouts scheduled',
                          style: TextStyle(color: subTextColor),
                        ),
                      ),
                  ],
                )
              : Center(
                  child: Text(
                    'No workout plan for today',
                    style: TextStyle(color: subTextColor),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMealRow(
      String mealType,
      String name,
      int calories,
      Color textColor,
      Color subTextColor,
      BuildContext context,
      bool isDarkMode) {
    return InkWell(
      onTap: () {
        _showDetailDialog(
            context,
            '$mealType: $name',
            'This meal contains $calories calories. Select "View Plan" to see detailed ingredients.',
            isDarkMode);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealType,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '$calories kcal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: subTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(
      BuildContext context, String title, String fullDetails, bool isDarkMode) {
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fullDetails,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseRow(
      String time,
      ExerciseSession session,
      Color textColor,
      Color subTextColor,
      BuildContext context,
      bool isDarkMode) {
    return InkWell(
      onTap: () {
        final fullDetails = session.exercises.join(', ');
        _showDetailDialog(context, session.name, fullDetails, isDarkMode);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: subTextColor,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (session.exercises.isNotEmpty)
                    Text(
                      session.exercises.take(2).join(', '),
                      style: TextStyle(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              '${session.calories} kcal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: subTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
