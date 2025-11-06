import 'package:cloud_firestore/cloud_firestore.dart';

// Food categories for better organization
enum FoodCategory {
  protein,
  carbohydrates,
  fats,
  vegetables,
  fruits,
  dairy,
  grains,
  nuts,
  beverages,
  snacks,
}

// Meal types
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
  preWorkout,
  postWorkout,
}

// Fitness activity types
enum ActivityType {
  cardio,
  strength,
  flexibility,
  balance,
  sports,
  yoga,
  pilates,
  swimming,
  cycling,
  running,
  walking,
}

// Intensity levels
enum IntensityLevel {
  low,
  moderate,
  high,
  veryHigh,
}

// Food item model
class FoodItem {
  final String id;
  final String name;
  final FoodCategory category;
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fats;
  final double fiber;
  final double sugar;
  final String? description;
  final String? imageUrl;
  final List<String>? allergens;
  final bool isVegan;
  final bool isGlutenFree;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fats,
    required this.fiber,
    required this.sugar,
    this.description,
    this.imageUrl,
    this.allergens,
    this.isVegan = false,
    this.isGlutenFree = false,
  });

  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      name: data['name'] ?? '',
      category: FoodCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'],
        orElse: () => FoodCategory.snacks,
      ),
      calories: (data['calories'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      carbohydrates: (data['carbohydrates'] ?? 0).toDouble(),
      fats: (data['fats'] ?? 0).toDouble(),
      fiber: (data['fiber'] ?? 0).toDouble(),
      sugar: (data['sugar'] ?? 0).toDouble(),
      description: data['description'],
      imageUrl: data['imageUrl'],
      allergens: data['allergens'] != null 
          ? List<String>.from(data['allergens'])
          : null,
      isVegan: data['isVegan'] ?? false,
      isGlutenFree: data['isGlutenFree'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category.toString().split('.').last,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fats': fats,
      'fiber': fiber,
      'sugar': sugar,
      'description': description,
      'imageUrl': imageUrl,
      'allergens': allergens,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
    };
  }

  FoodItem copyWith({
    String? id,
    String? name,
    FoodCategory? category,
    double? calories,
    double? protein,
    double? carbohydrates,
    double? fats,
    double? fiber,
    double? sugar,
    String? description,
    String? imageUrl,
    List<String>? allergens,
    bool? isVegan,
    bool? isGlutenFree,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      fats: fats ?? this.fats,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      allergens: allergens ?? this.allergens,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
    );
  }

  // Helper methods
  double get totalMacros => protein + carbohydrates + fats;
  bool get isHighProtein => protein >= 20;
  bool get isLowCarb => carbohydrates <= 30;
  bool get isLowFat => fats <= 10;
}

// Meal model
class Meal {
  final String id;
  final String name;
  final MealType type;
  final List<FoodItem> foods;
  final String? notes;
  final DateTime? scheduledTime;
  final bool isCompleted;

  const Meal({
    required this.id,
    required this.name,
    required this.type,
    required this.foods,
    this.notes,
    this.scheduledTime,
    this.isCompleted = false,
  });

  factory Meal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Meal(
      id: doc.id,
      name: data['name'] ?? '',
      type: MealType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => MealType.snack,
      ),
      foods: data['foods'] != null 
          ? (data['foods'] as List).map((f) => FoodItem.fromFirestore(f)).toList()
          : [],
      notes: data['notes'],
      scheduledTime: data['scheduledTime'] != null 
          ? (data['scheduledTime'] as Timestamp).toDate()
          : null,
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.toString().split('.').last,
      'foods': foods.map((f) => f.toFirestore()).toList(),
      'notes': notes,
      'scheduledTime': scheduledTime != null 
          ? Timestamp.fromDate(scheduledTime!)
          : null,
      'isCompleted': isCompleted,
    };
  }

  Meal copyWith({
    String? id,
    String? name,
    MealType? type,
    List<FoodItem>? foods,
    String? notes,
    DateTime? scheduledTime,
    bool? isCompleted,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      foods: foods ?? this.foods,
      notes: notes ?? this.notes,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Helper methods
  double get totalCalories => foods.fold(0, (sum, food) => sum + food.calories);
  double get totalProtein => foods.fold(0, (sum, food) => sum + food.protein);
  double get totalCarbohydrates => foods.fold(0, (sum, food) => sum + food.carbohydrates);
  double get totalFats => foods.fold(0, (sum, food) => sum + food.fats);
  double get totalFiber => foods.fold(0, (sum, food) => sum + food.fiber);
  double get totalSugar => foods.fold(0, (sum, food) => sum + food.sugar);
}

// Fitness activity model
class FitnessActivity {
  final String id;
  final String name;
  final ActivityType type;
  final IntensityLevel intensity;
  final int durationMinutes;
  final double caloriesBurned;
  final DateTime date;
  final String? notes;
  final Map<String, dynamic>? metrics; // For tracking specific metrics like distance, reps, etc.

  const FitnessActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.intensity,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.date,
    this.notes,
    this.metrics,
  });

  factory FitnessActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FitnessActivity(
      id: doc.id,
      name: data['name'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ActivityType.walking,
      ),
      intensity: IntensityLevel.values.firstWhere(
        (e) => e.toString().split('.').last == data['intensity'],
        orElse: () => IntensityLevel.moderate,
      ),
      durationMinutes: data['durationMinutes'] ?? 0,
      caloriesBurned: (data['caloriesBurned'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
      metrics: data['metrics'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.toString().split('.').last,
      'intensity': intensity.toString().split('.').last,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'metrics': metrics,
    };
  }

  FitnessActivity copyWith({
    String? id,
    String? name,
    ActivityType? type,
    IntensityLevel? intensity,
    int? durationMinutes,
    double? caloriesBurned,
    DateTime? date,
    String? notes,
    Map<String, dynamic>? metrics,
  }) {
    return FitnessActivity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      intensity: intensity ?? this.intensity,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      metrics: metrics ?? this.metrics,
    );
  }

  // Helper methods
  bool get isHighIntensity => intensity == IntensityLevel.high || intensity == IntensityLevel.veryHigh;
  bool get isCardio => type == ActivityType.cardio || type == ActivityType.running || type == ActivityType.swimming;
  bool get isStrength => type == ActivityType.strength;
  double get caloriesPerMinute => caloriesBurned / durationMinutes;
}

// Nutrition plan model
class NutritionPlan {
  final String id;
  final String name;
  final String description;
  final List<Meal> meals;
  final int targetCalories;
  final double targetProtein;
  final double targetCarbohydrates;
  final double targetFats;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const NutritionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.meals,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbohydrates,
    required this.targetFats,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory NutritionPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NutritionPlan(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      meals: data['meals'] != null 
          ? (data['meals'] as List).map((m) => Meal.fromFirestore(m)).toList()
          : [],
      targetCalories: data['targetCalories'] ?? 2000,
      targetProtein: (data['targetProtein'] ?? 150).toDouble(),
      targetCarbohydrates: (data['targetCarbohydrates'] ?? 250).toDouble(),
      targetFats: (data['targetFats'] ?? 67).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null 
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'meals': meals.map((m) => m.toFirestore()).toList(),
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarbohydrates': targetCarbohydrates,
      'targetFats': targetFats,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  NutritionPlan copyWith({
    String? id,
    String? name,
    String? description,
    List<Meal>? meals,
    int? targetCalories,
    double? targetProtein,
    double? targetCarbohydrates,
    double? targetFats,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NutritionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      meals: meals ?? this.meals,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbohydrates: targetCarbohydrates ?? this.targetCarbohydrates,
      targetFats: targetFats ?? this.targetFats,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  double get totalCalories => meals.fold(0, (sum, meal) => sum + meal.totalCalories);
  double get totalProtein => meals.fold(0, (sum, meal) => sum + meal.totalProtein);
  double get totalCarbohydrates => meals.fold(0, (sum, meal) => sum + meal.totalCarbohydrates);
  double get totalFats => meals.fold(0, (sum, meal) => sum + meal.totalFats);
  
  double get caloriesProgress => (totalCalories / targetCalories) * 100;
  double get proteinProgress => (totalProtein / targetProtein) * 100;
  double get carbsProgress => (totalCarbohydrates / targetCarbohydrates) * 100;
  double get fatsProgress => (totalFats / targetFats) * 100;
  
  bool get isOnTrack => caloriesProgress >= 80 && caloriesProgress <= 120;
  bool get isOverTarget => caloriesProgress > 120;
  bool get isUnderTarget => caloriesProgress < 80;
  
  List<Meal> get mealsByType {
    final Map<MealType, List<Meal>> grouped = {};
    for (final mealType in MealType.values) {
      grouped[mealType] = meals.where((m) => m.type == mealType).toList();
    }
    return grouped.values.expand((meals) => meals).toList();
  }
  
  Meal? getMealByType(MealType type) {
    try {
      return meals.firstWhere((m) => m.type == type);
    } catch (e) {
      return null;
    }
  }
}
