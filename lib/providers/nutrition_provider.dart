import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// Nutrition state notifier
class NutritionNotifier extends StateNotifier<AsyncValue<List<NutritionPlan>>> {
  List<NutritionPlan> _nutritionPlans = [];
  List<FitnessActivity> _fitnessActivities = [];

  NutritionNotifier() : super(const AsyncValue.data([])) {
    _loadDefaultPlans();
  }

  List<NutritionPlan> get nutritionPlans => List.unmodifiable(_nutritionPlans);
  List<FitnessActivity> get fitnessActivities => List.unmodifiable(_fitnessActivities);

  void _loadDefaultPlans() {
    _nutritionPlans = [
      NutritionPlan(
        id: '1',
        name: 'Balanced Diet Plan',
        description: 'A well-rounded nutrition plan for general health and wellness.',
        meals: [
          Meal(
            name: 'Healthy Breakfast',
            type: 'breakfast',
            foods: [
              FoodItem(
                name: 'Oatmeal',
                quantity: 1,
                unit: 'cup',
                calories: 150,
                nutrients: {'protein': 6, 'carbs': 27, 'fat': 3},
              ),
              FoodItem(
                name: 'Banana',
                quantity: 1,
                unit: 'medium',
                calories: 105,
                nutrients: {'protein': 1, 'carbs': 27, 'fat': 0},
              ),
            ],
            calories: 255,
          ),
        ],
        totalCalories: 2000,
        macronutrients: {'protein': 150, 'carbs': 200, 'fat': 67},
        tags: ['balanced', 'healthy'],
      ),
      NutritionPlan(
        id: '2',
        name: 'Vegetarian Plan',
        description: 'Plant-based nutrition plan rich in protein and nutrients.',
        meals: [
          Meal(
            name: 'Protein Bowl',
            type: 'lunch',
            foods: [
              FoodItem(
                name: 'Quinoa',
                quantity: 1,
                unit: 'cup',
                calories: 222,
                nutrients: {'protein': 8, 'carbs': 39, 'fat': 4},
              ),
              FoodItem(
                name: 'Chickpeas',
                quantity: 0.5,
                unit: 'cup',
                calories: 134,
                nutrients: {'protein': 7, 'carbs': 22, 'fat': 2},
              ),
            ],
            calories: 356,
          ),
        ],
        totalCalories: 1800,
        macronutrients: {'protein': 120, 'carbs': 180, 'fat': 60},
        tags: ['vegetarian', 'high-protein'],
      ),
    ];
    
    state = AsyncValue.data(_nutritionPlans);
  }

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
}

// Providers
final nutritionProvider = StateNotifierProvider<NutritionNotifier, AsyncValue<List<NutritionPlan>>>(
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
final availableFitnessActivitiesProvider = Provider<List<Map<String, dynamic>>>((ref) {
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
