# Nutrition & Fitness Backend

This is a Flask API server that generates personalized weekly nutrition and fitness plans using Google's Gemini AI.

## Setup

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Create a `.env` file in the **project root** directory (same level as `pubspec.yaml`) with your Gemini API key:
```
GEMINI_API_KEY=your_gemini_api_key_here
```

   **Note:** The `.env` file is now at the project root level and will be used by both fitness_server and find_doctor services.

3. Run the server:
```bash
python main.py
```

The server will start on `http://localhost:5000`

## API Endpoints

### POST /generate-plan
Generates a personalized weekly nutrition and fitness plan.

**Request Body:**
```json
{
  "age": "25",
  "sex": "Male",
  "weight": "70",
  "height": "170",
  "country": "USA",
  "goal": "Lose Weight",
  "activityLevel": "Active",
  "medicalConditions": "None",
  "dietType": "Normal",
  "foodsToAvoid": "None",
  "dailyMeals": "3 meals",
  "fitnessLevel": "Intermediate",
  "workoutPreference": "Mix",
  "timeAvailable": "30 min",
  "location": "Home",
  "equipment": "Dumbbells, Yoga Mat",
  "injuries": "None"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "diet_plan": {
      "monday": {
        "breakfast": {
          "name": "Protein Oatmeal",
          "foods": [
            {"name": "Oats", "quantity": 1, "unit": "cup", "calories": 150},
            {"name": "Protein Powder", "quantity": 1, "unit": "scoop", "calories": 120}
          ],
          "calories": 270
        },
        "lunch": { ... },
        "dinner": { ... },
        "snacks": { ... }
      },
      "tuesday": { ... },
      ...
    },
    "exercise_plan": {
      "monday": {
        "morning": {
          "name": "Cardio Session",
          "exercises": ["30 min jogging", "5 min stretching"],
          "duration": "35 minutes",
          "calories": 300
        },
        "evening": {
          "name": "Strength Training",
          "exercises": ["Push-ups", "Squats", "Planks"],
          "duration": "45 minutes",
          "calories": 250
        }
      },
      "tuesday": { ... },
      ...
    },
    "weekly_summary": {
      "total_calories_per_day": 2000,
      "total_workout_time_per_day": "1 hour",
      "key_goals": ["Lose 1-2 lbs per week", "Build muscle"],
      "tips": ["Stay hydrated", "Get 7-8 hours sleep"]
    }
  }
}
```

### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "message": "Nutrition API is running"
}
```

## Usage with Flutter App

The Flutter app connects to this API through the `NutritionService` class. Make sure the server is running before using the nutrition features in the app.

## Notes

- The API uses Google's Gemini 2.0 Flash model for generating plans
- Plans are generated based on user input and are personalized for each user
- The server includes CORS support for Flutter web compatibility
