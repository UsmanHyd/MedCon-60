import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:medcon30/providers/nutrition_provider.dart';
import 'package:medcon30/services/firestore_service.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  int selectedDay = 0;
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  bool _hasAttemptedLoad = false;
  bool _isSavedPlan = false;

  @override
  void initState() {
    super.initState();
    // Load saved plan when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedPlan();
    });
  }

  Future<void> _loadSavedPlan() async {
    if (_hasAttemptedLoad) return;
    _hasAttemptedLoad = true;

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final savedPlanData = await firestoreService.getSavedWeeklyPlan();

      if (savedPlanData != null && mounted) {
        // Parse and set the saved plan
        final weeklyPlanNotifier =
            ref.read(weeklyPlanNotifierProvider.notifier);
        final weeklyPlan = _parseWeeklyPlanFromSavedData(savedPlanData);
        if (weeklyPlan != null) {
          weeklyPlanNotifier.setWeeklyPlan(weeklyPlan);
          setState(() {
            _isSavedPlan = true;
          });
        }
      }
    } catch (e) {
      print('Error loading saved plan: $e');
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

  MealPlan _parseMealPlan(Map<String, dynamic> mealData, String defaultMealType) {
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

    // Try to get nutritional values with multiple key variations
    double getNutritionValue(String key, double defaultValue) {
      // Try exact key
      if (mealData.containsKey(key)) {
        final value = mealData[key];
        if (value is num) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      // Try capitalized version
      final capitalizedKey = key[0].toUpperCase() + key.substring(1);
      if (mealData.containsKey(capitalizedKey)) {
        final value = mealData[capitalizedKey];
        if (value is num) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return defaultValue;
    }

    var protein = getNutritionValue('protein', 0.0);
    var carbohydrates = getNutritionValue('carbohydrates', getNutritionValue('carbs', 0.0));
    var fats = getNutritionValue('fats', getNutritionValue('fat', 0.0));
    var fiber = getNutritionValue('fiber', 0.0);

    // If values are still 0 and we have calories, estimate from calories
    final totalCalories = mealData['calories'] ?? 0;
    if (totalCalories > 0 && protein == 0 && carbohydrates == 0 && fats == 0) {
      // Estimate based on typical meal composition
      protein = (totalCalories * 0.25 / 4).roundToDouble(); // 25% from protein (4 cal/g)
      carbohydrates = (totalCalories * 0.45 / 4).roundToDouble(); // 45% from carbs (4 cal/g)
      fats = (totalCalories * 0.30 / 9).roundToDouble(); // 30% from fats (9 cal/g)
      fiber = (totalCalories * 0.05 / 4).roundToDouble(); // Rough estimate for fiber
    }

    return MealPlan(
      name: mealData['name'] ?? 'Meal',
      foods: foods,
      calories: totalCalories,
      protein: protein,
      carbohydrates: carbohydrates,
      fats: fats,
      fiber: fiber,
      mealType: mealData['mealType']?.toString() ?? 
                mealData['meal_type']?.toString() ?? 
                mealData['MealType']?.toString() ?? 
                defaultMealType,
    );
  }

  DayPlan _parseDayPlan(Map<String, dynamic> dayData) {
    return DayPlan(
      day: dayData['day'] ?? '',
      breakfast: _parseMealPlan(dayData['breakfast'] ?? {}, 'Breakfast'),
      lunch: _parseMealPlan(dayData['lunch'] ?? {}, 'Lunch'),
      dinner: _parseMealPlan(dayData['dinner'] ?? {}, 'Dinner'),
      snacks:
          dayData['snacks'] != null ? _parseMealPlan(dayData['snacks'], 'Snack') : null,
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
      floatingActionButton: (!_isSavedPlan)
          ? Consumer(
              builder: (context, ref, child) {
                final weeklyPlan = ref.watch(weeklyPlanProvider);
                return FloatingActionButton.extended(
                  onPressed: weeklyPlan != null
                      ? () => _savePlan(context, ref, weeklyPlan)
                      : null,
                  backgroundColor: weeklyPlan != null
                      ? const Color(0xFF2056F7)
                      : Colors.grey,
                  label: const Text('Save Plan',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  icon: const Icon(Icons.save, color: Colors.white),
                );
              },
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Plan',
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
                      width: 70,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2056F7) : cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2056F7)
                                : borderColor,
                            width: 2),
                      ),
                      child: Center(
                        child: Text(days[i],
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isSelected ? Colors.white : textColor)),
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
                final weeklyPlan = ref.watch(weeklyPlanProvider);
                final nutritionState = ref.watch(nutritionProvider);

                print(
                    '🔍 Plan screen - weeklyPlan: ${weeklyPlan != null ? "exists" : "null"}');
                if (weeklyPlan != null) {
                  print(
                      '📅 Available diet plan days: ${weeklyPlan.dietPlan.keys.join(', ')}');
                  print(
                      '🏃 Available exercise plan days: ${weeklyPlan.exercisePlan.keys.join(', ')}');
                }

                if (nutritionState.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (nutritionState.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      'Error loading meal plan: ${nutritionState.error}',
                      style: TextStyle(color: subTextColor),
                    ),
                  );
                }

                if (weeklyPlan == null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 48,
                          color: subTextColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No weekly plan available',
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

                // Get the selected day's plan
                final selectedDayName = _getDayName(selectedDay);
                final dayPlan = weeklyPlan.dietPlan[selectedDayName];

                if (dayPlan == null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'No plan available for ${days[selectedDay]}',
                          style: TextStyle(color: subTextColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Looking for: $selectedDayName',
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                        Text(
                          'Available days: ${weeklyPlan.dietPlan.keys.join(', ')}',
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                // Create a list of meals with their times and sort by time
                final meals = <_MealItem>[
                  _MealItem(
                    meal: dayPlan.breakfast,
                      icon: Icons.breakfast_dining,
                      time: '7:30 AM',
                    timeValue: 730, // For sorting
                  ),
                  _MealItem(
                    meal: dayPlan.lunch,
                      icon: Icons.lunch_dining,
                      time: '12:30 PM',
                    timeValue: 1230,
                  ),
                  _MealItem(
                    meal: dayPlan.dinner,
                      icon: Icons.dinner_dining,
                      time: '7:00 PM',
                    timeValue: 1900,
                  ),
                  if (dayPlan.snacks != null)
                    _MealItem(
                      meal: dayPlan.snacks!,
                        icon: Icons.cake,
                      time: '3:00 PM',
                      timeValue: 1500,
                    ),
                ];
                
                // Sort meals by time
                meals.sort((a, b) => a.timeValue.compareTo(b.timeValue));

                return Column(
                  children: meals.map((mealItem) {
                    final index = meals.indexOf(mealItem);
                    return Column(
                      children: [
                        if (index > 0) const SizedBox(height: 12),
                        _MealCard(
                          icon: mealItem.icon,
                          title: mealItem.meal.name,
                          subtitle: mealItem.meal.foods
                            .map((food) =>
                                '${food.name} (${food.quantity} ${food.unit})')
                            .join(', '),
                          time: mealItem.time,
                          calories: '${mealItem.meal.calories} kcal',
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        borderColor: borderColor,
                        onTap: () {
                            _showMealDetailDialog(context, mealItem.meal, isDarkMode);
                        },
                      ),
                  ],
                    );
                  }).toList(),
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
            Consumer(
              builder: (context, ref, child) {
                final weeklyPlan = ref.watch(weeklyPlanProvider);

                if (weeklyPlan == null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 48,
                          color: subTextColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No workout plan available',
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

                // Get the selected day's exercise plan
                final selectedDayName = _getDayName(selectedDay);
                final dayExercisePlan =
                    weeklyPlan.exercisePlan[selectedDayName];

                if (dayExercisePlan == null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'No workout plan available for ${days[selectedDay]}',
                          style: TextStyle(color: subTextColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Looking for: $selectedDayName',
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                        Text(
                          'Available days: ${weeklyPlan.exercisePlan.keys.join(', ')}',
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    if (dayExercisePlan.morning != null) ...[
                      _WorkoutCard(
                        icon: Icons.wb_sunny,
                        title: dayExercisePlan.morning!.name,
                        exercises: dayExercisePlan.morning!.exercises,
                        time: '6:00 AM',
                        calories: '${dayExercisePlan.morning!.calories} kcal',
                        duration: dayExercisePlan.morning!.duration,
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          _showWorkoutDetailDialog(
                              context,
                              dayExercisePlan.morning!,
                              isDarkMode);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (dayExercisePlan.evening != null) ...[
                      _WorkoutCard(
                        icon: Icons.fitness_center,
                        title: dayExercisePlan.evening!.name,
                        exercises: dayExercisePlan.evening!.exercises,
                        time: '5:30 PM',
                        calories: '${dayExercisePlan.evening!.calories} kcal',
                        duration: dayExercisePlan.evening!.duration,
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          _showWorkoutDetailDialog(
                              context,
                              dayExercisePlan.evening!,
                              isDarkMode);
                        },
                      ),
                    ],
                    if (dayExercisePlan.morning == null &&
                        dayExercisePlan.evening == null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          'Rest day - No workouts scheduled',
                          style: TextStyle(color: subTextColor),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getDayName(int dayIndex) {
    // Map the selected day index to the correct day name for the API
    const dayMapping = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return dayMapping[dayIndex];
  }

  void _savePlan(BuildContext context, WidgetRef ref, WeeklyPlan plan) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Convert WeeklyPlan to Map for saving
      final planData = {
        'id': plan.id,
        'dietPlan': _convertDietPlanToMap(plan.dietPlan),
        'exercisePlan': _convertExercisePlanToMap(plan.exercisePlan),
        'summary': {
          'totalCaloriesPerDay': plan.summary.totalCaloriesPerDay,
          'totalWorkoutTimePerDay': plan.summary.totalWorkoutTimePerDay,
          'keyGoals': plan.summary.keyGoals,
          'tips': plan.summary.tips,
        },
        'createdAt': plan.createdAt.toIso8601String(),
      };

      // Save to Firestore
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.saveWeeklyPlan(planData);

      // Close loading dialog and show success message
      if (mounted && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog and show error
      if (mounted && context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save plan: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Map<String, dynamic> _convertDietPlanToMap(Map<String, DayPlan> dietPlan) {
    final result = <String, dynamic>{};
    for (final entry in dietPlan.entries) {
      final dayPlan = entry.value;
      result[entry.key] = {
        'day': dayPlan.day,
        'breakfast': {
          'name': dayPlan.breakfast.name,
          'foods': dayPlan.breakfast.foods
              .map((f) => {
                    'name': f.name,
                    'quantity': f.quantity,
                    'unit': f.unit,
                    'calories': f.calories,
                    'nutrients': f.nutrients,
                  })
              .toList(),
          'calories': dayPlan.breakfast.calories,
          'protein': dayPlan.breakfast.protein,
          'carbohydrates': dayPlan.breakfast.carbohydrates,
          'fats': dayPlan.breakfast.fats,
          'fiber': dayPlan.breakfast.fiber,
          'mealType': dayPlan.breakfast.mealType,
        },
        'lunch': {
          'name': dayPlan.lunch.name,
          'foods': dayPlan.lunch.foods
              .map((f) => {
                    'name': f.name,
                    'quantity': f.quantity,
                    'unit': f.unit,
                    'calories': f.calories,
                    'nutrients': f.nutrients,
                  })
              .toList(),
          'calories': dayPlan.lunch.calories,
          'protein': dayPlan.lunch.protein,
          'carbohydrates': dayPlan.lunch.carbohydrates,
          'fats': dayPlan.lunch.fats,
          'fiber': dayPlan.lunch.fiber,
          'mealType': dayPlan.lunch.mealType,
        },
        'dinner': {
          'name': dayPlan.dinner.name,
          'foods': dayPlan.dinner.foods
              .map((f) => {
                    'name': f.name,
                    'quantity': f.quantity,
                    'unit': f.unit,
                    'calories': f.calories,
                    'nutrients': f.nutrients,
                  })
              .toList(),
          'calories': dayPlan.dinner.calories,
          'protein': dayPlan.dinner.protein,
          'carbohydrates': dayPlan.dinner.carbohydrates,
          'fats': dayPlan.dinner.fats,
          'fiber': dayPlan.dinner.fiber,
          'mealType': dayPlan.dinner.mealType,
        },
        if (dayPlan.snacks != null)
          'snacks': {
            'name': dayPlan.snacks!.name,
            'foods': dayPlan.snacks!.foods
                .map((f) => {
                      'name': f.name,
                      'quantity': f.quantity,
                      'unit': f.unit,
                      'calories': f.calories,
                      'nutrients': f.nutrients,
                    })
                .toList(),
            'calories': dayPlan.snacks!.calories,
            'protein': dayPlan.snacks!.protein,
            'carbohydrates': dayPlan.snacks!.carbohydrates,
            'fats': dayPlan.snacks!.fats,
            'fiber': dayPlan.snacks!.fiber,
            'mealType': dayPlan.snacks!.mealType,
          },
      };
    }
    return result;
  }

  Map<String, dynamic> _convertExercisePlanToMap(
      Map<String, DayExercisePlan> exercisePlan) {
    final result = <String, dynamic>{};
    for (final entry in exercisePlan.entries) {
      final dayPlan = entry.value;
      result[entry.key] = {
        'day': dayPlan.day,
        if (dayPlan.morning != null)
          'morning': {
            'name': dayPlan.morning!.name,
            'exercises': dayPlan.morning!.exercises,
            'duration': dayPlan.morning!.duration,
            'calories': dayPlan.morning!.calories,
          },
        if (dayPlan.evening != null)
          'evening': {
            'name': dayPlan.evening!.name,
            'exercises': dayPlan.evening!.exercises,
            'duration': dayPlan.evening!.duration,
            'calories': dayPlan.evening!.calories,
          },
      };
    }
    return result;
  }
}

// Exercise data model
class _ExerciseData {
  final String name;
  final String? sets;
  final String? reps;

  _ExerciseData({
    required this.name,
    this.sets,
    this.reps,
  });
}

// Helper function to parse exercise string
List<_ExerciseData> _parseExercises(List<String> exerciseStrings) {
  final exercises = <_ExerciseData>[];
  
  for (final exerciseStr in exerciseStrings) {
    // Try to parse patterns like:
    // "Squats (3 sets of 10 reps)"
    // "Push-ups (3 sets of as many reps as possible)"
    // "Dumbbell Rows (3 sets x 12 reps)"
    // "Jumping Jacks, Arm Circles" (simple exercises without details)
    
    final trimmed = exerciseStr.trim();
    if (trimmed.isEmpty) continue;
    
    // Check for parentheses pattern: "Exercise (X sets of Y reps)"
    final parenMatch = RegExp(r'^(.+?)\s*\((.+?)\)$').firstMatch(trimmed);
    if (parenMatch != null) {
      final name = parenMatch.group(1)?.trim() ?? '';
      final details = parenMatch.group(2)?.trim() ?? '';
      
      // Try to extract sets and reps
      String? sets;
      String? reps;
      
      // Pattern: "3 sets of 10 reps" or "3 sets of as many reps as possible"
      final setsRepsMatch = RegExp(r'(\d+)\s*sets?\s*(?:of|x)?\s*(.+?)?\s*(?:reps?)?', caseSensitive: false).firstMatch(details);
      if (setsRepsMatch != null) {
        sets = setsRepsMatch.group(1);
        final repsPart = setsRepsMatch.group(2)?.trim();
        if (repsPart != null && repsPart.isNotEmpty) {
          // Check if it's a number or text like "as many as possible"
          if (RegExp(r'^\d+$').hasMatch(repsPart)) {
            reps = repsPart;
          } else {
            reps = repsPart; // Keep full text like "as many as possible"
          }
        }
      }
      
      exercises.add(_ExerciseData(
        name: name,
        sets: sets,
        reps: reps,
      ));
    } else {
      // Simple exercise name without details
      exercises.add(_ExerciseData(name: trimmed));
    }
  }
  
  return exercises;
}

// Helper class for meal items with time for sorting
class _MealItem {
  final MealPlan meal;
  final IconData icon;
  final String time;
  final int timeValue;

  _MealItem({
    required this.meal,
    required this.icon,
    required this.time,
    required this.timeValue,
  });
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
  final VoidCallback? onTap;

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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2056F7).withOpacity(isDarkMode ? 0.3 : 0.15),
                    const Color(0xFF2056F7).withOpacity(isDarkMode ? 0.2 : 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: const Color(0xFF2056F7), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2056F7).withOpacity(isDarkMode ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            color: const Color(0xFF2056F7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                          color: subTextColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: const Color(0xFFFF6B35),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        calories,
                        style: TextStyle(
                          color: const Color(0xFFFF6B35),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF4C4C4C)
                        : const Color(0xFFBFC8D9),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
                color: cardColor,
              ),
              child: Checkbox(
                value: false,
                onChanged: (_) {},
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: Colors.transparent, width: 0),
                activeColor: const Color(0xFF2056F7),
                checkColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showMealDetailDialog(
    BuildContext context, MealPlan meal, bool isDarkMode) {
  final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  final textColor = isDarkMode ? Colors.white : Colors.black;
  final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF8F9BB3);
  final borderColor = isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFE3E7ED);
  final bgColor = isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);

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
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    meal.name,
                    style: TextStyle(
                      fontSize: 20,
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
            const SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    // Left half: Meal details
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meal Contents',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.builder(
                                itemCount: meal.foods.length,
                                itemBuilder: (context, index) {
                                  final food = meal.foods[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(top: 6, right: 12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2056F7),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                food.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${food.quantity} ${food.unit} • ${food.calories} kcal',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: subTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right half: Health details table
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nutrition Facts',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildNutritionTableRow('Field', 'Value', textColor, subTextColor, isHeader: true),
                                    Divider(height: 1, color: borderColor),
                                    _buildNutritionTableRow('Protein (g)', _formatNutritionValue(meal.protein), textColor, subTextColor),
                                    Divider(height: 1, color: borderColor),
                                    _buildNutritionTableRow('Carbohydrates (g)', _formatNutritionValue(meal.carbohydrates), textColor, subTextColor),
                                    Divider(height: 1, color: borderColor),
                                    _buildNutritionTableRow('Fats (g)', _formatNutritionValue(meal.fats), textColor, subTextColor),
                                    Divider(height: 1, color: borderColor),
                                    _buildNutritionTableRow('Fiber (g)', _formatNutritionValue(meal.fiber), textColor, subTextColor),
                                    Divider(height: 1, color: borderColor),
                                    _buildNutritionTableRow('Meal Type', meal.mealType.isNotEmpty ? meal.mealType : 'N/A', textColor, subTextColor),
                                    Divider(height: 2, thickness: 2, color: borderColor),
                                    _buildNutritionTableRow('Total Calories', '${meal.calories} kcal', textColor, textColor, isHeader: true, isTotal: true),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

String _formatNutritionValue(double value) {
  if (value <= 0.0) {
    return 'N/A';
  }
  // Show as integer if whole number, otherwise show one decimal
  if (value == value.toInt()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

Widget _buildNutritionTableRow(String field, String value, Color textColor, Color subTextColor, {bool isHeader = false, bool isTotal = false}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: isTotal ? 12 : 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            field,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.bold : (isHeader ? FontWeight.bold : FontWeight.w500),
              color: isTotal ? textColor : (isHeader ? textColor : subTextColor),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : (isHeader ? FontWeight.bold : FontWeight.w600),
            color: isTotal ? const Color(0xFF2056F7) : textColor,
          ),
        ),
      ],
    ),
  );
}

class _WorkoutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> exercises;
  final String time;
  final String calories;
  final String duration;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;
  final bool isDarkMode;
  final VoidCallback? onTap;

  const _WorkoutCard({
    required this.icon,
    required this.title,
    required this.exercises,
    required this.time,
    required this.calories,
    required this.duration,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
    required this.isDarkMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final parsedExercises = _parseExercises(exercises);
    final previewExercises = parsedExercises.take(2).toList();
    final hasMore = parsedExercises.length > 2;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(isDarkMode ? 0.3 : 0.15),
                    const Color(0xFF10B981).withOpacity(isDarkMode ? 0.2 : 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: const Color(0xFF10B981), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(isDarkMode ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            color: const Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...previewExercises.map((exercise) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(top: 6, right: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: exercise.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (exercise.sets != null || exercise.reps != null) ...[
                                          const TextSpan(text: ' • '),
                                          TextSpan(
                                            text: exercise.sets != null && exercise.reps != null
                                                ? '${exercise.sets} sets × ${exercise.reps} reps'
                                                : exercise.sets != null
                                                    ? '${exercise.sets} sets'
                                                    : '${exercise.reps} reps',
                                            style: TextStyle(
                                              color: subTextColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (hasMore)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+ ${parsedExercises.length - 2} more exercises',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: const Color(0xFFFF6B35),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        calories,
                        style: TextStyle(
                          color: const Color(0xFFFF6B35),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: subTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF4C4C4C)
                      : const Color(0xFFBFC8D9),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
                color: cardColor,
              ),
              child: Checkbox(
                value: false,
                onChanged: (_) {},
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: Colors.transparent, width: 0),
                activeColor: const Color(0xFF10B981),
                checkColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showWorkoutDetailDialog(
    BuildContext context, ExerciseSession session, bool isDarkMode) {
  final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  final textColor = isDarkMode ? Colors.white : Colors.black;
  final borderColor = isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFE3E7ED);
  final bgColor = isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);

  final parsedExercises = _parseExercises(session.exercises);

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
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    session.name,
                    style: TextStyle(
                      fontSize: 20,
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
            const SizedBox(height: 16),
            Row(
              children: [
            Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: const Color(0xFFFF6B35),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${session.calories} kcal',
                style: TextStyle(
                          color: const Color(0xFFFF6B35),
                          fontWeight: FontWeight.w600,
                  fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        session.duration,
                        style: TextStyle(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Exercises',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                  color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: parsedExercises.length,
                itemBuilder: (context, index) {
                  final exercise = parsedExercises[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                exercise.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                ),
              ),
            ),
          ],
        ),
                        if (exercise.sets != null || exercise.reps != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (exercise.sets != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2056F7).withOpacity(isDarkMode ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${exercise.sets} sets',
                                    style: TextStyle(
                                      color: const Color(0xFF2056F7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (exercise.reps != null) const SizedBox(width: 8),
                              ],
                              if (exercise.reps != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(isDarkMode ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${exercise.reps} reps',
                                    style: TextStyle(
                                      color: const Color(0xFF10B981),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

