import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/nutrition_service.dart';

// Nutrition plan model
class NutritionPlan {
  final String id;
  final String name;
  final String description;
  final List<Meal> meals;
  final int totalCalories;
  final Map<String, double> macronutrients; // protein, carbs, fat
  final List<String> tags; // vegetarian, vegan, gluten-free, etc.

  NutritionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.meals,
    required this.totalCalories,
    required this.macronutrients,
    required this.tags,
  });
}

// Meal model
class Meal {
  final String name;
  final String type; // breakfast, lunch, dinner, snack
  final List<FoodItem> foods;
  final int calories;
  final String? instructions;

  Meal({
    required this.name,
    required this.type,
    required this.foods,
    required this.calories,
    this.instructions,
  });
}

// Food item model
class FoodItem {
  final String name;
  final double quantity;
  final String unit;
  final int calories;
  final Map<String, double> nutrients;

  FoodItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.nutrients,
  });
}

// Fitness activity model
class FitnessActivity {
  final String id;
  final String name;
  final String type; // cardio, strength, flexibility, etc.
  final int duration; // in minutes
  final int caloriesBurned;
  final DateTime date;
  final String? notes;

  FitnessActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.duration,
    required this.caloriesBurned,
    required this.date,
    this.notes,
  });
}

// Weekly plan models
class WeeklyPlan {
  final String id;
  final Map<String, DayPlan> dietPlan;
  final Map<String, DayExercisePlan> exercisePlan;
  final WeeklySummary summary;
  final DateTime createdAt;

  WeeklyPlan({
    required this.id,
    required this.dietPlan,
    required this.exercisePlan,
    required this.summary,
    required this.createdAt,
  });
}

class DayPlan {
  final String day;
  final MealPlan breakfast;
  final MealPlan lunch;
  final MealPlan dinner;
  final MealPlan? snacks;

  DayPlan({
    required this.day,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    this.snacks,
  });
}

class MealPlan {
  final String name;
  final List<FoodItem> foods;
  final int calories;
  final double protein; // in grams
  final double carbohydrates; // in grams
  final double fats; // in grams
  final double fiber; // in grams (optional)
  final String mealType; // Breakfast, Lunch, Dinner, Snack

  MealPlan({
    required this.name,
    required this.foods,
    required this.calories,
    this.protein = 0.0,
    this.carbohydrates = 0.0,
    this.fats = 0.0,
    this.fiber = 0.0,
    this.mealType = '',
  });
}

class DayExercisePlan {
  final String day;
  final ExerciseSession? morning;
  final ExerciseSession? evening;

  DayExercisePlan({
    required this.day,
    this.morning,
    this.evening,
  });
}

class ExerciseSession {
  final String name;
  final List<String> exercises;
  final String duration;
  final int calories;

  ExerciseSession({
    required this.name,
    required this.exercises,
    required this.duration,
    required this.calories,
  });
}

class WeeklySummary {
  final int totalCaloriesPerDay;
  final String totalWorkoutTimePerDay;
  final List<String> keyGoals;
  final List<String> tips;

  WeeklySummary({
    required this.totalCaloriesPerDay,
    required this.totalWorkoutTimePerDay,
    required this.keyGoals,
    required this.tips,
  });
}

// Nutrition state notifier
class NutritionNotifier extends StateNotifier<AsyncValue<List<NutritionPlan>>> {
  List<NutritionPlan> _nutritionPlans = [];
  List<FitnessActivity> _fitnessActivities = [];
  WeeklyPlan? _currentWeeklyPlan;

  NutritionNotifier() : super(const AsyncValue.data([])) {
    // No default plans - only use real data from API
  }

  List<NutritionPlan> get nutritionPlans => List.unmodifiable(_nutritionPlans);
  List<FitnessActivity> get fitnessActivities =>
      List.unmodifiable(_fitnessActivities);
  WeeklyPlan? get currentWeeklyPlan => _currentWeeklyPlan;

  void addNutritionPlan(NutritionPlan plan) {
    _nutritionPlans.add(plan);
    state = AsyncValue.data(_nutritionPlans);
  }

  void removeNutritionPlan(String id) {
    _nutritionPlans.removeWhere((plan) => plan.id == id);
    state = AsyncValue.data(_nutritionPlans);
  }

  void addFitnessActivity(FitnessActivity activity) {
    _fitnessActivities.add(activity);
    _fitnessActivities.sort((a, b) => b.date.compareTo(a.date));
  }

  void removeFitnessActivity(String id) {
    _fitnessActivities.removeWhere((activity) => activity.id == id);
  }

  List<FitnessActivity> getActivitiesForDate(DateTime date) {
    return _fitnessActivities
        .where((activity) =>
            activity.date.year == date.year &&
            activity.date.month == date.month &&
            activity.date.day == date.day)
        .toList();
  }

  int getTotalCaloriesBurnedForDate(DateTime date) {
    return getActivitiesForDate(date)
        .fold(0, (sum, activity) => sum + activity.caloriesBurned);
  }

  List<FitnessActivity> getRecentActivities(int count) {
    return _fitnessActivities.take(count).toList();
  }

  Map<String, int> getActivityTypeStats() {
    final stats = <String, int>{};
    for (final activity in _fitnessActivities) {
      stats[activity.type] = (stats[activity.type] ?? 0) + 1;
    }
    return stats;
  }

  // Generate weekly plan using API
  Future<void> generateWeeklyPlan(Map<String, dynamic> userData,
      WeeklyPlanNotifier weeklyPlanNotifier) async {
    try {
      print('🚀 Starting plan generation...');
      state = const AsyncValue.loading();

      final result = await NutritionService.generateWeeklyPlan(userData);
      print('📡 API response received: ${result['success']}');
      print('🔍 Full API response keys: ${result.keys.toList()}');
      print('🔍 Has data field: ${result.containsKey('data')}');
      if (result.containsKey('data')) {
        print('🔍 Data field value: ${result['data']}');
      }

      if (result['success'] == true) {
        // Check if we have raw_response (when JSON parsing failed on server)
        if (result.containsKey('raw_response')) {
          print(
              '⚠️ Received raw response from Gemini - JSON parsing failed on server');
          print('📝 Raw response: ${result['raw_response']}');
          // Try to parse the raw response as JSON
          try {
            final rawData = json.decode(result['raw_response']);
            print('✅ Successfully parsed raw response as JSON');
            final weeklyPlan = _parseWeeklyPlanFromApi(rawData);
            _currentWeeklyPlan = weeklyPlan;
            weeklyPlanNotifier.setWeeklyPlan(weeklyPlan);
            print('✅ Weekly plan set successfully from raw response');
            state = AsyncValue.data(_nutritionPlans);
          } catch (e) {
            print('❌ Failed to parse raw response as JSON: $e');
            state = AsyncValue.error(
              'Failed to parse plan data from server',
              StackTrace.current,
            );
          }
        } else {
          // Check if data is in 'data' field or directly in result
          final planData = result['data'] ?? result;
          print('📋 Parsing weekly plan from API response...');
          print('🔍 Raw API data keys: ${planData.keys.toList()}');

          final weeklyPlan = _parseWeeklyPlanFromApi(planData);
          print(
              '📅 Parsed plan - Diet days: ${weeklyPlan.dietPlan.keys.join(', ')}');
          print(
              '🏃 Parsed plan - Exercise days: ${weeklyPlan.exercisePlan.keys.join(', ')}');

          _currentWeeklyPlan = weeklyPlan;
          weeklyPlanNotifier.setWeeklyPlan(weeklyPlan);
          print('✅ Weekly plan set successfully in notifier');
          state = AsyncValue.data(_nutritionPlans);
        }
      } else {
        print('❌ API call failed: ${result['error']}');
        state = AsyncValue.error(
          result['error'] ?? 'Failed to generate plan',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      print('💥 Exception in generateWeeklyPlan: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  WeeklyPlan _parseWeeklyPlanFromApi(Map<String, dynamic> data) {
    final dietPlan = <String, DayPlan>{};
    final exercisePlan = <String, DayExercisePlan>{};

    // Parse diet plan
    if (data['diet_plan'] != null) {
      final dietData = data['diet_plan'] as Map<String, dynamic>;
      for (final entry in dietData.entries) {
        final dayData = entry.value;
        
        // Check if dayData is actually a Map
        if (dayData == null || dayData is! Map<String, dynamic>) {
          print('⚠️ Invalid day data for ${entry.key}: $dayData');
          continue;
        }
        
        // Safely parse meals - handle null values
        MealPlan? breakfast;
        MealPlan? lunch;
        MealPlan? dinner;
        MealPlan? snacks;
        
        if (dayData['breakfast'] != null && dayData['breakfast'] is Map) {
          breakfast = _parseMealPlan(dayData['breakfast'] as Map<String, dynamic>, 'Breakfast');
        } else {
          breakfast = _createEmptyMealPlan('Breakfast');
        }
        
        if (dayData['lunch'] != null && dayData['lunch'] is Map) {
          lunch = _parseMealPlan(dayData['lunch'] as Map<String, dynamic>, 'Lunch');
        } else {
          lunch = _createEmptyMealPlan('Lunch');
        }
        
        if (dayData['dinner'] != null && dayData['dinner'] is Map) {
          dinner = _parseMealPlan(dayData['dinner'] as Map<String, dynamic>, 'Dinner');
        } else {
          dinner = _createEmptyMealPlan('Dinner');
        }
        
        if (dayData['snacks'] != null && dayData['snacks'] is Map) {
          snacks = _parseMealPlan(dayData['snacks'] as Map<String, dynamic>, 'Snack');
        }
        
        dietPlan[entry.key] = DayPlan(
          day: entry.key,
          breakfast: breakfast,
          lunch: lunch,
          dinner: dinner,
          snacks: snacks,
        );
      }
    }

    // Parse exercise plan
    if (data['exercise_plan'] != null) {
      final exerciseData = data['exercise_plan'] as Map<String, dynamic>;
      for (final entry in exerciseData.entries) {
        final dayData = entry.value;
        
        // Check if dayData is actually a Map
        if (dayData == null || dayData is! Map<String, dynamic>) {
          print('⚠️ Invalid exercise day data for ${entry.key}: $dayData');
          continue;
        }
        
        ExerciseSession? morning;
        ExerciseSession? evening;
        
        if (dayData['morning'] != null && dayData['morning'] is Map) {
          try {
            morning = _parseExerciseSession(dayData['morning'] as Map<String, dynamic>);
          } catch (e) {
            print('⚠️ Error parsing morning exercise: $e');
          }
        }
        
        if (dayData['evening'] != null && dayData['evening'] is Map) {
          try {
            evening = _parseExerciseSession(dayData['evening'] as Map<String, dynamic>);
          } catch (e) {
            print('⚠️ Error parsing evening exercise: $e');
          }
        }
        
        exercisePlan[entry.key] = DayExercisePlan(
          day: entry.key,
          morning: morning,
          evening: evening,
        );
      }
    }

    // Parse summary
    final summaryData = data['weekly_summary'] as Map<String, dynamic>? ?? {};
    final summary = WeeklySummary(
      totalCaloriesPerDay: summaryData['total_calories_per_day'] ?? 2000,
      totalWorkoutTimePerDay:
          summaryData['total_workout_time_per_day'] ?? '30 minutes',
      keyGoals: List<String>.from(summaryData['key_goals'] ?? []),
      tips: List<String>.from(summaryData['tips'] ?? []),
    );

    return WeeklyPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dietPlan: dietPlan,
      exercisePlan: exercisePlan,
      summary: summary,
      createdAt: DateTime.now(),
    );
  }

  MealPlan _parseMealPlan(Map<String, dynamic> mealData, String defaultMealType) {
    if (mealData.isEmpty) {
      return _createEmptyMealPlan(defaultMealType);
    }
    
    // Debug: Print available keys
    print('🔍 Meal data keys: ${mealData.keys.toList()}');
    
    final foods = <FoodItem>[];
    if (mealData['foods'] != null && mealData['foods'] is List) {
      final foodsList = mealData['foods'] as List;
      for (final foodData in foodsList) {
        if (foodData is Map) {
          try {
            foods.add(FoodItem(
              name: foodData['name']?.toString() ?? 'Unknown',
              quantity: (foodData['quantity'] ?? 1).toDouble(),
              unit: foodData['unit']?.toString() ?? 'serving',
              calories: (foodData['calories'] ?? 0) as int,
              nutrients: foodData['nutrients'] is Map
                  ? Map<String, double>.from(
                      (foodData['nutrients'] as Map).map(
                        (k, v) => MapEntry(k.toString(), (v ?? 0).toDouble()),
                      ),
                    )
                  : {},
            ));
          } catch (e) {
            print('⚠️ Error parsing food item: $e');
          }
        }
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
      // Try all caps
      final upperKey = key.toUpperCase();
      if (mealData.containsKey(upperKey)) {
        final value = mealData[upperKey];
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
    final totalCalories = (mealData['calories'] ?? 0) as int;
    if (totalCalories > 0 && protein == 0 && carbohydrates == 0 && fats == 0) {
      print('⚠️ No nutritional values found, estimating from calories...');
      // Estimate based on typical meal composition: 30% protein, 40% carbs, 30% fats
      // Protein: 4 cal/g, Carbs: 4 cal/g, Fats: 9 cal/g
      protein = (totalCalories * 0.25 / 4).roundToDouble(); // 25% from protein
      carbohydrates = (totalCalories * 0.45 / 4).roundToDouble(); // 45% from carbs
      fats = (totalCalories * 0.30 / 9).roundToDouble(); // 30% from fats
      fiber = (totalCalories * 0.05 / 4).roundToDouble(); // Rough estimate for fiber
      print('📊 Estimated values: protein=$protein, carbs=$carbohydrates, fats=$fats');
    } else {
      print('📊 Parsed values: protein=$protein, carbs=$carbohydrates, fats=$fats, fiber=$fiber');
    }

    return MealPlan(
      name: mealData['name']?.toString() ?? 'Meal',
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

  MealPlan _createEmptyMealPlan(String mealName) {
    return MealPlan(
      name: mealName,
      foods: [],
      calories: 0,
      protein: 0.0,
      carbohydrates: 0.0,
      fats: 0.0,
      fiber: 0.0,
      mealType: mealName,
    );
  }

  ExerciseSession _parseExerciseSession(Map<String, dynamic> sessionData) {
    if (sessionData.isEmpty) {
      return ExerciseSession(
        name: 'Exercise',
        exercises: [],
        duration: '30 minutes',
        calories: 0,
      );
    }
    
    List<String> exercises = [];
    if (sessionData['exercises'] != null) {
      if (sessionData['exercises'] is List) {
        exercises = (sessionData['exercises'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }
    
    return ExerciseSession(
      name: sessionData['name']?.toString() ?? 'Exercise',
      exercises: exercises,
      duration: sessionData['duration']?.toString() ?? '30 minutes',
      calories: (sessionData['calories'] ?? 0) as int,
    );
  }
}

// Providers
final nutritionProvider =
    StateNotifierProvider<NutritionNotifier, AsyncValue<List<NutritionPlan>>>(
  (ref) => NutritionNotifier(),
);

final fitnessActivitiesProvider = Provider<List<FitnessActivity>>((ref) {
  final nutritionNotifier = ref.watch(nutritionProvider.notifier);
  return nutritionNotifier.fitnessActivities;
});

final recentFitnessActivitiesProvider = Provider<List<FitnessActivity>>((ref) {
  final nutritionNotifier = ref.watch(nutritionProvider.notifier);
  return nutritionNotifier.getRecentActivities(5);
});

final activityTypeStatsProvider = Provider<Map<String, int>>((ref) {
  final nutritionNotifier = ref.watch(nutritionProvider.notifier);
  return nutritionNotifier.getActivityTypeStats();
});

// Predefined fitness activities for UI
final availableFitnessActivitiesProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {'name': 'Walking', 'type': 'cardio', 'caloriesPerMinute': 4},
    {'name': 'Running', 'type': 'cardio', 'caloriesPerMinute': 10},
    {'name': 'Cycling', 'type': 'cardio', 'caloriesPerMinute': 8},
    {'name': 'Swimming', 'type': 'cardio', 'caloriesPerMinute': 9},
    {'name': 'Weight Training', 'type': 'strength', 'caloriesPerMinute': 6},
    {'name': 'Yoga', 'type': 'flexibility', 'caloriesPerMinute': 3},
    {'name': 'Pilates', 'type': 'flexibility', 'caloriesPerMinute': 4},
    {'name': 'Dancing', 'type': 'cardio', 'caloriesPerMinute': 7},
    {'name': 'Hiking', 'type': 'cardio', 'caloriesPerMinute': 6},
    {'name': 'Basketball', 'type': 'cardio', 'caloriesPerMinute': 8},
  ];
});

// Convenience provider for today's activities
final todayActivitiesProvider = Provider<List<FitnessActivity>>((ref) {
  final nutritionNotifier = ref.watch(nutritionProvider.notifier);
  return nutritionNotifier.getActivitiesForDate(DateTime.now());
});

final todayCaloriesBurnedProvider = Provider<int>((ref) {
  final nutritionNotifier = ref.watch(nutritionProvider.notifier);
  return nutritionNotifier.getTotalCaloriesBurnedForDate(DateTime.now());
});

// Weekly plan notifier
class WeeklyPlanNotifier extends StateNotifier<WeeklyPlan?> {
  WeeklyPlanNotifier() : super(null);

  void setWeeklyPlan(WeeklyPlan? plan) {
    print(
        '🔄 WeeklyPlanNotifier.setWeeklyPlan called with: ${plan != null ? "plan" : "null"}');
    if (plan != null) {
      print(
          '📅 Setting plan with ${plan.dietPlan.length} diet days and ${plan.exercisePlan.length} exercise days');
    }
    state = plan;
    print('✅ WeeklyPlanNotifier state updated');
  }

  void clearWeeklyPlan() {
    print('🗑️ WeeklyPlanNotifier.clearWeeklyPlan called');
    state = null;
  }
}

// Weekly plan provider
final weeklyPlanNotifierProvider =
    StateNotifierProvider<WeeklyPlanNotifier, WeeklyPlan?>((ref) {
  return WeeklyPlanNotifier();
});

final weeklyPlanProvider = Provider<WeeklyPlan?>((ref) {
  final plan = ref.watch(weeklyPlanNotifierProvider);
  print(
      '🔍 weeklyPlanProvider called - plan: ${plan != null ? "exists" : "null"}');
  return plan;
});
