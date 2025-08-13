import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:medcon30/providers/nutrition_provider.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  int selectedDay = 0;
  final List<String> days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  final List<String> dates = ['10', '11', '12', '13', '14', '15', '16'];

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor =
        isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF8F9BB3);
    final borderColor =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFE3E7ED);

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
          'Your Personalized Plan',
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF222B45),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2056F7),
        onPressed: () {},
        child: const Icon(Icons.play_arrow, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Week of May 10 - May 16',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor)),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                itemBuilder: (context, i) {
                  final isSelected = i == selectedDay;
                  return GestureDetector(
                    onTap: () => setState(() => selectedDay = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 52,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2056F7) : cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2056F7)
                                : borderColor,
                            width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(days[i],
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : subTextColor)),
                          const SizedBox(height: 2),
                          Text(dates[i],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : textColor,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
            Text('Meal Plan',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor)),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final nutritionPlans = ref.watch(nutritionProvider);

                if (nutritionPlans.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (nutritionPlans.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      'Error loading meal plan',
                      style: TextStyle(color: subTextColor),
                    ),
                  );
                }

                if (!nutritionPlans.hasValue || nutritionPlans.value!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      'No meal plan available',
                      style: TextStyle(color: subTextColor),
                    ),
                  );
                }

                // Get the first available nutrition plan
                final selectedPlan = nutritionPlans.value!.first;
                final meals = selectedPlan.meals;

                if (meals.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      'No meals in this plan',
                      style: TextStyle(color: subTextColor),
                    ),
                  );
                }

                return Column(
                  children: [
                    ...meals.map((meal) => Column(
                          children: [
                            _MealCard(
                              icon: _getMealIcon(meal.type),
                              title: meal.name,
                              subtitle: meal.foods
                                  .map((food) =>
                                      '${food.name} (${food.quantity} ${food.unit})')
                                  .join(', '),
                              time: _getMealTime(meal.type),
                              calories: '${meal.calories} kcal',
                              cardColor: cardColor,
                              textColor: textColor,
                              subTextColor: subTextColor,
                              borderColor: borderColor,
                            ),
                            if (meal != meals.last) const SizedBox(height: 12),
                          ],
                        )),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            Text('Workout Plan',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor)),
            const SizedBox(height: 12),
            _MealCard(
              icon: Icons.directions_run,
              title: 'Cardio',
              subtitle: '30 min jogging or brisk walking',
              time: '6:00 AM',
              calories: '300 kcal',
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              borderColor: borderColor,
            ),
            const SizedBox(height: 12),
            _MealCard(
              icon: Icons.fitness_center,
              title: 'Strength Training',
              subtitle: 'Upper body workout - 3 sets of 12 reps',
              time: '5:30 PM',
              calories: '250 kcal',
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              borderColor: borderColor,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  IconData _getMealIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }

  String _getMealTime(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return '7:30 AM';
      case 'lunch':
        return '12:30 PM';
      case 'dinner':
        return '7:00 PM';
      case 'snack':
        return '3:00 PM';
      default:
        return '12:00 PM';
    }
  }
}

class _MealCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final String calories;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _MealCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.calories,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color:
                  const Color(0xFF2056F7).withOpacity(isDarkMode ? 0.2 : 0.08),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: const Color(0xFF2056F7), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor)),
                    Text(time,
                        style: TextStyle(color: subTextColor, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: textColor, fontSize: 13)),
                const SizedBox(height: 4),
                Text(calories,
                    style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF4C4C4C)
                      : const Color(0xFFBFC8D9),
                  width: 2),
              borderRadius: BorderRadius.circular(5),
              color: cardColor,
            ),
            child: Checkbox(
              value: false,
              onChanged: (_) {},
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              side: const BorderSide(color: Colors.transparent, width: 0),
              activeColor: const Color(0xFF2056F7),
              checkColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
