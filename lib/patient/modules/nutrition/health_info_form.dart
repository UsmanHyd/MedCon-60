import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';
import 'package:medcon30/models/nutrition_user_data.dart';
import 'package:medcon30/providers/nutrition_provider.dart';
import 'package:medcon30/services/firestore_service.dart';
import 'package:medcon30/services/app_history_service.dart';
import 'plan.dart';


class HealthInformationForm extends ConsumerStatefulWidget {
  const HealthInformationForm({Key? key}) : super(key: key);

  @override
  ConsumerState<HealthInformationForm> createState() => _HealthInformationFormState();
}

class _HealthInformationFormState extends ConsumerState<HealthInformationForm> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0 = Personal, 1 = Dietary, 2 = Exercise
  
  // Step 1: Personal Information
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _medicalConditionsController = TextEditingController();
  String? _selectedSex;
  String? _selectedGoal;
  
  // Step 2: Dietary Information
  String? _selectedDietType;
  final TextEditingController _foodsToAvoidController = TextEditingController();
  String? _selectedDailyMeals;
  
  // Step 3: Exercise Information
  String? _selectedFitnessLevel;
  String? _selectedWorkoutPreference;
  String? _selectedTimeAvailable;
  String? _selectedLocation;
  final TextEditingController _injuriesController = TextEditingController();
  final List<String> _selectedEquipment = [];
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _countryController.dispose();
    _medicalConditionsController.dispose();
    _foodsToAvoidController.dispose();
    _injuriesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _submitToGemini();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _submitToGemini() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userData = NutritionUserData(
        age: _ageController.text.trim(),
        sex: _selectedSex,
        weight: _weightController.text.trim(),
        height: _heightController.text.trim(),
        country: _countryController.text.trim(),
        goal: _selectedGoal,
        activityLevel: null, // Removed from UI
        medicalConditions: _medicalConditionsController.text.trim().isEmpty 
            ? null 
            : _medicalConditionsController.text.trim(),
        dietType: _selectedDietType,
        foodsToAvoid: _foodsToAvoidController.text.trim().isEmpty 
            ? null 
            : _foodsToAvoidController.text.trim(),
        dailyMeals: _selectedDailyMeals,
        fitnessLevel: _selectedFitnessLevel,
        workoutPreference: _selectedWorkoutPreference,
        timeAvailable: _selectedTimeAvailable,
        location: _selectedLocation,
        equipment: _selectedEquipment,
        injuries: _injuriesController.text.trim().isEmpty 
            ? null 
            : _injuriesController.text.trim(),
      );

      // Show improved loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final isDarkMode =
              provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
          final bgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
          final textColor = isDarkMode ? Colors.white : Colors.black;
          final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
          return PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F8CFF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F8CFF)),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Creating Your Plan',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Our AI is analyzing your information and creating a personalized nutrition and fitness plan just for you...',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF4F8CFF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      // Submit to Gemini via provider
      final nutritionNotifier = ref.read(nutritionProvider.notifier);
      final weeklyPlanNotifier = ref.read(weeklyPlanNotifierProvider.notifier);
      final firestoreService = ref.read(firestoreServiceProvider);
      
      await nutritionNotifier.generateWeeklyPlan(
        userData.toMap(),
        weeklyPlanNotifier,
      );

      // Auto-save the new plan to replace the old one
      // Wait a bit for the plan to be set in the provider
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        final weeklyPlan = ref.read(weeklyPlanProvider);
        if (weeklyPlan != null) {
          // Convert WeeklyPlan to Map for saving (using same structure as plan.dart)
          final dietPlanMap = <String, dynamic>{};
          for (final entry in weeklyPlan.dietPlan.entries) {
            final dayPlan = entry.value;
            dietPlanMap[entry.key] = {
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
                },
            };
          }

          final exercisePlanMap = <String, dynamic>{};
          for (final entry in weeklyPlan.exercisePlan.entries) {
            final dayExercisePlan = entry.value;
            exercisePlanMap[entry.key] = {
              'day': dayExercisePlan.day,
              if (dayExercisePlan.morning != null)
                'morning': {
                  'name': dayExercisePlan.morning!.name,
                  'exercises': dayExercisePlan.morning!.exercises,
                  'duration': dayExercisePlan.morning!.duration,
                  'calories': dayExercisePlan.morning!.calories,
                },
              if (dayExercisePlan.evening != null)
                'evening': {
                  'name': dayExercisePlan.evening!.name,
                  'exercises': dayExercisePlan.evening!.exercises,
                  'duration': dayExercisePlan.evening!.duration,
                  'calories': dayExercisePlan.evening!.calories,
                },
            };
          }

          final planData = {
            'id': weeklyPlan.id,
            'dietPlan': dietPlanMap,
            'exercisePlan': exercisePlanMap,
            'summary': {
              'totalCaloriesPerDay': weeklyPlan.summary.totalCaloriesPerDay,
              'totalWorkoutTimePerDay': weeklyPlan.summary.totalWorkoutTimePerDay,
              'keyGoals': weeklyPlan.summary.keyGoals,
              'tips': weeklyPlan.summary.tips,
            },
            'createdAt': weeklyPlan.createdAt.toIso8601String(),
          };
          await firestoreService.saveWeeklyPlan(planData);
          print('✅ New plan automatically saved, replacing old plan');
          
          // Track fitness plan creation in app history
          try {
            await AppHistoryService().trackNutritionFitness(
              activityType: 'Weekly Plan Created',
              description: 'Created personalized nutrition and fitness plan',
              details: {
                'total_calories_per_day': weeklyPlan.summary.totalCaloriesPerDay,
                'total_workout_time_per_day': weeklyPlan.summary.totalWorkoutTimePerDay,
                'key_goals': weeklyPlan.summary.keyGoals,
              },
            );
          } catch (e) {
            print('⚠️ Error tracking fitness plan in app history: $e');
            // Don't fail the operation if tracking fails
          }
        }
      } catch (saveError) {
        print('⚠️ Failed to auto-save plan: $saveError');
        // Don't fail the whole operation if save fails
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Navigate to plan screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PlanScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Health Information',
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF0288D1),
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / 3,
                        backgroundColor: isDarkMode 
                            ? const Color(0xFF2C2C2C) 
                            : Colors.grey[300],
                        color: const Color(0xFF4F8CFF),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_currentStep + 1}/3',
                      style: TextStyle(
                        color: subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Page view for steps
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPersonalInfoStep(isDarkMode, cardColor, textColor, subTextColor, borderColor),
                _buildDietaryInfoStep(isDarkMode, cardColor, textColor, subTextColor, borderColor),
                _buildExerciseInfoStep(isDarkMode, cardColor, textColor, subTextColor, borderColor),
              ],
            ),
          ),
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(
                top: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: borderColor),
                      ),
                      child: Text(
                        'Previous',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2056F7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _currentStep == 2 ? 'Generate Plan' : 'Next',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep(bool isDarkMode, Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            'Age',
            _ageController,
            'Enter your age',
            TextInputType.number,
            cardColor,
            textColor,
            subTextColor,
            borderColor,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Sex',
            _selectedSex,
            ['Male', 'Female', 'Other'],
            (value) => setState(() => _selectedSex = value),
            cardColor,
            textColor,
            subTextColor,
            borderColor,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Weight (kg)',
                  _weightController,
                  'Weight',
                  TextInputType.number,
                  cardColor,
                  textColor,
                  subTextColor,
                  borderColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  'Height (cm)',
                  _heightController,
                  'Height',
                  TextInputType.number,
                  cardColor,
                  textColor,
                  subTextColor,
                  borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Country',
            _countryController,
            'Enter your country',
            TextInputType.text,
            cardColor,
            textColor,
            subTextColor,
            borderColor,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Goal',
            _selectedGoal,
            ['Weight Loss', 'Muscle Gain', 'Healthy Eating', 'General Fitness'],
            (value) => setState(() => _selectedGoal = value),
            cardColor,
            textColor,
            subTextColor,
            borderColor,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Medical Conditions',
            _medicalConditionsController,
            'List any medical conditions or allergies',
            TextInputType.multiline,
            cardColor,
            textColor,
            subTextColor,
            borderColor,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryInfoStep(bool isDarkMode, Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dietary Information',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildDropdown(
            'Diet Type',
            _selectedDietType,
            ['Normal', 'Vegetarian', 'Vegan', 'Gluten-Free', 'Dairy-Free', 'Keto', 'Paleo', 'Mediterranean'],
            (value) => setState(() => _selectedDietType = value),
            cardColor,
            textColor,
            subTextColor,
            borderColor,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Foods to Avoid',
            _foodsToAvoidController,
            'List any foods you want to avoid',
            TextInputType.multiline,
            cardColor,
            textColor,
            subTextColor,
            borderColor,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Daily Meals Count',
            _selectedDailyMeals,
            ['1', '2', '3', '4'],
            (value) => setState(() => _selectedDailyMeals = value),
            cardColor,
            textColor,
            subTextColor,
            borderColor,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseInfoStep(bool isDarkMode, Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exercise Information',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildDropdown(
            'Fitness Level',
            _selectedFitnessLevel,
            ['Beginner', 'Intermediate', 'Advanced'],
            (value) => setState(() => _selectedFitnessLevel = value),
            cardColor,
            textColor,
            subTextColor,
            borderColor,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Workout Preference',
            _selectedWorkoutPreference,
            ['Cardio', 'Strength Training', 'HIIT', 'Yoga/Pilates', 'Bodyweight', 'Flexibility', 'Mixed'],
            (value) => setState(() => _selectedWorkoutPreference = value),
            cardColor,
            textColor,
            subTextColor,
            borderColor,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Time Available (per day)',
            _selectedTimeAvailable,
            ['15 minutes', '30 minutes', '45 minutes', '1 hour', '1.5 hours', '2 hours'],
            (value) => setState(() => _selectedTimeAvailable = value),
            cardColor,
            textColor,
            subTextColor,
            borderColor,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Location',
            _selectedLocation,
            ['Home', 'Gym', 'Outdoor', 'Mixed'],
            (value) => setState(() {
              _selectedLocation = value;
              // Clear equipment if location changes from Home
              if (value != 'Home') {
                _selectedEquipment.clear();
              }
            }),
            cardColor,
            textColor,
            subTextColor,
            borderColor,
          ),
          // Show equipment selection only if Home is selected
          if (_selectedLocation == 'Home') ...[
            const SizedBox(height: 16),
            Text(
              'Equipment Available',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Dumbbells',
                'Barbell',
                'Resistance Bands',
                'Yoga Mat',
                'Treadmill',
                'None',
              ].map((equipment) {
                final isSelected = _selectedEquipment.contains(equipment);
                return FilterChip(
                  selected: isSelected,
                  label: Text(equipment),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedEquipment.add(equipment);
                      } else {
                        _selectedEquipment.remove(equipment);
                      }
                    });
                  },
                  backgroundColor: cardColor,
                  selectedColor: const Color(0xFF4F8CFF),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : textColor,
                  ),
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          _buildTextField(
            'Injuries/Limitations',
            _injuriesController,
            'List any injuries or physical limitations',
            TextInputType.multiline,
            cardColor,
            textColor,
            subTextColor,
            borderColor,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
    TextInputType keyboardType,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: cardColor,
          ),
          style: TextStyle(color: textColor),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: Text(
              'Select $label',
              style: TextStyle(color: subTextColor),
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: TextStyle(color: textColor)),
              );
            }).toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            dropdownColor: cardColor,
          ),
        ),
      ],
    );
  }
}

