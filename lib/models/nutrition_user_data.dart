class NutritionUserData {
  // Personal Information
  final String? age;
  final String? sex;
  final String? weight;
  final String? height;
  final String? country;
  final String? goal;
  final String? activityLevel;
  final String? medicalConditions;

  // Diet Information
  final String? dietType;
  final String? foodsToAvoid;
  final String? dailyMeals;

  // Exercise Information
  final String? fitnessLevel;
  final String? workoutPreference;
  final String? timeAvailable;
  final String? location;
  final List<String> equipment;
  final String? injuries;

  NutritionUserData({
    this.age,
    this.sex,
    this.weight,
    this.height,
    this.country,
    this.goal,
    this.activityLevel,
    this.medicalConditions,
    this.dietType,
    this.foodsToAvoid,
    this.dailyMeals,
    this.fitnessLevel,
    this.workoutPreference,
    this.timeAvailable,
    this.location,
    this.equipment = const [],
    this.injuries,
  });

  Map<String, dynamic> toMap() {
    return {
      'age': age ?? 'Not specified',
      'sex': sex ?? 'Not specified',
      'weight': weight ?? 'Not specified',
      'height': height ?? 'Not specified',
      'country': country ?? 'Not specified',
      'goal': goal ?? 'Not specified',
      'activityLevel': activityLevel ?? 'Not specified',
      'medicalConditions': medicalConditions ?? 'None',
      'dietType': dietType ?? 'Not specified',
      'foodsToAvoid': foodsToAvoid ?? 'None',
      'dailyMeals': dailyMeals ?? 'Not specified',
      'fitnessLevel': fitnessLevel ?? 'Not specified',
      'workoutPreference': workoutPreference ?? 'Not specified',
      'timeAvailable': timeAvailable ?? 'Not specified',
      'location': location ?? 'Not specified',
      'equipment': equipment.isEmpty ? 'None' : equipment.join(', '),
      'injuries': injuries ?? 'None',
    };
  }

  NutritionUserData copyWith({
    String? age,
    String? sex,
    String? weight,
    String? height,
    String? country,
    String? goal,
    String? activityLevel,
    String? medicalConditions,
    String? dietType,
    String? foodsToAvoid,
    String? dailyMeals,
    String? fitnessLevel,
    String? workoutPreference,
    String? timeAvailable,
    String? location,
    List<String>? equipment,
    String? injuries,
  }) {
    return NutritionUserData(
      age: age ?? this.age,
      sex: sex ?? this.sex,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      country: country ?? this.country,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      dietType: dietType ?? this.dietType,
      foodsToAvoid: foodsToAvoid ?? this.foodsToAvoid,
      dailyMeals: dailyMeals ?? this.dailyMeals,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      workoutPreference: workoutPreference ?? this.workoutPreference,
      timeAvailable: timeAvailable ?? this.timeAvailable,
      location: location ?? this.location,
      equipment: equipment ?? this.equipment,
      injuries: injuries ?? this.injuries,
    );
  }
}
