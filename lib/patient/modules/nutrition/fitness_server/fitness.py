import os
import json
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import google.generativeai as genai

# Load the .env file from project root
# Path: lib/patient/modules/nutrition/fitness_server/fitness.py
# Go up 6 levels: fitness_server -> nutrition -> modules -> patient -> lib -> root
import pathlib
project_root = pathlib.Path(__file__).resolve().parent.parent.parent.parent.parent.parent
env_file = project_root / ".env"

if env_file.exists():
    load_dotenv(env_file)
    print(f"✅ Loaded .env from project root: {env_file}")
else:
    # Fallback to default load_dotenv() behavior
    load_dotenv()
    print(f"⚠️  .env file not found at project root ({env_file}), trying default locations")

# Get API key - if not found, use a default or prompt user
api_key = os.getenv("GEMINI_API_KEY")
if not api_key or api_key == "your_gemini_api_key_here":
    print("⚠️  GEMINI_API_KEY not found in .env file!")
    print(f"⚠️  Please create a .env file at project root ({env_file}) with: GEMINI_API_KEY=your_actual_api_key")
    print("Or set it as an environment variable")
    print("⚠️  Plans will not be generated without a valid key")
    api_key = "placeholder_key"

# Configure Gemini client
try:
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel("gemini-2.0-flash")
    print("✅ Gemini AI configured successfully")
except Exception as e:
    print(f"❌ Error configuring Gemini: {e}")
    print("Please check your API key")
    model = None

# Initialize Flask app
app = Flask(__name__)
CORS(app)

def generate_weekly_plan(user_data):
    """Generate a comprehensive weekly nutrition and fitness plan using Gemini"""
    
    # Check if model is available
    if model is None:
        return {"success": False, "error": "Gemini AI model not configured. Please check your API key."}
    
    # Extract meal count and country for meal planning
    meal_count = user_data.get('dailyMeals', '3')
    country = user_data.get('country', 'Not specified')
    
    # Create a detailed prompt for Gemini
    prompt = f"""
    Create a comprehensive weekly nutrition and fitness plan based on the following user information:
    
    Personal Information:
    - Age: {user_data.get('age', 'Not specified')}
    - Sex: {user_data.get('sex', 'Not specified')}
    - Weight: {user_data.get('weight', 'Not specified')} kg
    - Height: {user_data.get('height', 'Not specified')} cm
    - Country: {country}
    - Goal: {user_data.get('goal', 'Not specified')}
    - Medical Conditions: {user_data.get('medicalConditions', 'None')}
    
    Diet Information:
    - Diet Type: {user_data.get('dietType', 'Not specified')}
    - Foods to Avoid: {user_data.get('foodsToAvoid', 'None')}
    - Daily Meals Count: {meal_count}
    
    Exercise Information:
    - Fitness Level: {user_data.get('fitnessLevel', 'Not specified')}
    - Workout Preference: {user_data.get('workoutPreference', 'Not specified')}
    - Time Available: {user_data.get('timeAvailable', 'Not specified')}
    - Location: {user_data.get('location', 'Not specified')}
    - Equipment: {user_data.get('equipment', 'None')}
    - Injuries/Limitations: {user_data.get('injuries', 'None')}
    
    CRITICAL DIETARY REQUIREMENTS:
    1. The user is from: {country}. You MUST use traditional, authentic foods from {country} in the meal plan.
    2. Create exactly {meal_count} meals per day based on the user's preference.
    3. Use local ingredients, recipes, and cooking styles from {country}.
    4. Include culturally appropriate dishes that are common in {country}.
    5. Ensure meals are authentic to {country}'s cuisine while respecting dietary restrictions.
    
    Please provide a detailed weekly plan (Monday to Sunday) with the following structure:
    
    1. DIET PLAN for each day (exactly {meal_count} meals):
    - Use traditional foods from {country}
    - Include specific foods with quantities, units, and calories
    - Match the meal count requested ({meal_count} meals per day)
    - If {meal_count} is 1, provide only lunch. If 2, provide breakfast and dinner. If 3, provide breakfast, lunch, dinner. If 4, add snacks.
    
    2. EXERCISE PLAN for each day:
    - Morning workout (if applicable)
    - Afternoon/Evening workout
    - Include specific exercises, sets, reps, duration
    - Include rest days
    
    IMPORTANT: You MUST respond with ONLY valid JSON. Do not include any text before or after the JSON.
    
    Format the response as a JSON object with this structure:
    
    IMPORTANT: Based on meal count ({meal_count}):
    - If meal count is 1: Only include "lunch" (set breakfast and dinner to empty {{"name": "", "foods": [], "calories": 0}})
    - If meal count is 2: Include "breakfast" and "dinner" (set lunch to empty {{"name": "", "foods": [], "calories": 0}})
    - If meal count is 3: Include "breakfast", "lunch", "dinner"
    - If meal count is 4: Include "breakfast", "lunch", "dinner", and "snacks"
    
    ALWAYS include all three meal fields (breakfast, lunch, dinner) in the JSON, even if empty.
    
    CRITICAL REQUIREMENT - Each meal MUST include ALL of the following fields (these are MANDATORY, not optional):
    - name: Meal name
    - foods: Array of food items with name, quantity, unit, and calories
    - calories: Total calories for the meal (numeric value)
    - protein: Protein in grams (g) - MUST be a numeric value, NOT zero (e.g., 25, 30.5)
    - carbohydrates: Carbohydrates in grams (g) - MUST be a numeric value, NOT zero (e.g., 50, 60.2)
    - fats: Fats in grams (g) - MUST be a numeric value, NOT zero (e.g., 10, 15.3)
    - fiber: Fiber in grams (g) - MUST be a numeric value (can be 0 if meal has no fiber, but still include the field)
    - mealType: One of "Breakfast", "Lunch", "Dinner", or "Snack" - for filtering
    
    IMPORTANT: 
    1. Calculate accurate nutritional values based on the actual foods in each meal
    2. Use realistic, scientifically accurate nutritional data for the foods you're including
    3. DO NOT return 0 for protein, carbohydrates, or fats - these are essential nutrients that should be present in every meal
    4. Provide realistic values (e.g., a meal with rice, vegetables, and chicken should have protein around 20-40g, carbs 30-60g, fats 5-20g)
    5. If a meal is truly empty (no foods), set all nutritional values to 0
    
    Example meal structure (ALL fields required):
    {{"name": "Chicken Rice Bowl", "foods": [{{"name": "Grilled Chicken", "quantity": 150, "unit": "g", "calories": 250}}, {{"name": "Brown Rice", "quantity": 1, "unit": "cup", "calories": 220}}], "calories": 470, "protein": 35, "carbohydrates": 45, "fats": 12, "fiber": 4, "mealType": "Lunch"}}
    
    {{
        "diet_plan": {{
            "monday": {{
                "breakfast": {{"name": "Meal name", "foods": [{{"name": "Food item", "quantity": 1, "unit": "unit", "calories": 100}}], "calories": 400, "protein": 25, "carbohydrates": 50, "fats": 10, "fiber": 5, "mealType": "Breakfast"}},
                "lunch": {{"name": "Meal name", "foods": [{{"name": "Food item", "quantity": 1, "unit": "unit", "calories": 100}}], "calories": 500, "protein": 30, "carbohydrates": 60, "fats": 15, "fiber": 8, "mealType": "Lunch"}},
                "dinner": {{"name": "Meal name", "foods": [{{"name": "Food item", "quantity": 1, "unit": "unit", "calories": 100}}], "calories": 400, "protein": 25, "carbohydrates": 40, "fats": 12, "fiber": 6, "mealType": "Dinner"}},
                "snacks": {{"name": "Snack name", "foods": [{{"name": "Food item", "quantity": 1, "unit": "unit", "calories": 100}}], "calories": 150, "protein": 5, "carbohydrates": 20, "fats": 5, "fiber": 3, "mealType": "Snack"}}
            }},
            "tuesday": {{...}},
            "wednesday": {{...}},
            "thursday": {{...}},
            "friday": {{...}},
            "saturday": {{...}},
            "sunday": {{...}}
        }},
        "exercise_plan": {{
            "monday": {{
                "morning": {{"name": "Workout name", "exercises": ["Exercise 1", "Exercise 2"], "duration": "30 minutes", "calories": 300}},
                "evening": {{"name": "Workout name", "exercises": ["Exercise 1", "Exercise 2"], "duration": "45 minutes", "calories": 250}}
            }},
            "tuesday": {{...}},
            "wednesday": {{...}},
            "thursday": {{...}},
            "friday": {{...}},
            "saturday": {{...}},
            "sunday": {{...}}
        }},
        "weekly_summary": {{
            "total_calories_per_day": 2100,
            "total_workout_time_per_day": "75 minutes",
            "key_goals": ["Goal 1", "Goal 2", "Goal 3"],
            "tips": ["Tip 1", "Tip 2", "Tip 3"]
        }}
    }}
    
    CRITICAL: Make sure each day has DIFFERENT meals and exercises. Do not repeat the same content for all days.
    Make sure the plan is realistic, achievable, and tailored to the user's specific needs and constraints.
    """

    try:
        print(f"🚀 Generating plan for user from {country} with {meal_count} meals per day...")
        print(f"📊 Prompt length: {len(prompt)} characters")
        
        # Generate content with optimized settings
        generation_config = {
            "temperature": 0.7,
            "max_output_tokens": 8192,  # Limit response size for faster generation
        }
        
        response = model.generate_content(
            prompt,
            generation_config=generation_config
        )
        response_text = response.text.strip()
        
        print(f"✅ Received response ({len(response_text)} characters)")
        
        # Limit response size to prevent memory issues
        if len(response_text) > 100000:  # 100KB limit
            print(f"⚠️ Response too large ({len(response_text)} chars), truncating...")
            response_text = response_text[:100000]
        
        # Try to extract JSON from the response
        try:
            # Remove markdown code blocks if present
            import re
            response_text = re.sub(r'```json\s*', '', response_text)
            response_text = re.sub(r'```\s*', '', response_text)
            response_text = response_text.strip()
            
            # First try to parse the entire response as JSON
            plan_data = json.loads(response_text)
            print("✅ Successfully parsed JSON response")
            return {"success": True, "data": plan_data}
        except json.JSONDecodeError as e:
            print(f"⚠️ JSON parse error: {e}")
            # Try to find JSON within the response using a safer approach
            
            # Find the first occurrence of { and last occurrence of } to extract JSON
            start_idx = response_text.find('{')
            end_idx = response_text.rfind('}')
            
            if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
                try:
                    json_text = response_text[start_idx:end_idx + 1]
                    plan_data = json.loads(json_text)
                    print("✅ Successfully extracted and parsed JSON from response")
                    return {"success": True, "data": plan_data}
                except json.JSONDecodeError as e2:
                    print(f"❌ Failed to parse extracted JSON: {e2}")
                    # Save error response for debugging
                    with open('gemini_error_response.txt', 'w', encoding='utf-8') as f:
                        f.write(response_text)
                    print("💾 Saved error response to gemini_error_response.txt")
            
            # If all JSON parsing fails, return the raw text for debugging
            print(f"❌ Failed to parse JSON. Raw response preview: {response_text[:500]}...")
            return {"success": False, "error": "Failed to parse JSON response from Gemini", "raw_preview": response_text[:500]}
    except Exception as e:
        print(f"❌ Exception in generate_weekly_plan: {e}")
        import traceback
        traceback.print_exc()
        return {"success": False, "error": str(e)}

@app.route('/generate-plan', methods=['POST'])
def generate_plan():
    """API endpoint to generate weekly nutrition and fitness plan"""
    try:
        user_data = request.get_json()
        
        if not user_data:
            return jsonify({"success": False, "error": "No data provided"}), 400
        
        # Validate input size to prevent overflow
        user_data_str = json.dumps(user_data)
        if len(user_data_str) > 10000:  # 10KB limit for input
            return jsonify({"success": False, "error": "Input data too large"}), 400
        
        # Generate the plan
        result = generate_weekly_plan(user_data)
        
        if result["success"]:
            return jsonify(result)
        else:
            return jsonify(result), 500
            
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    print("🔍 Health check endpoint called")
    return jsonify({"status": "healthy", "message": "Nutrition API is running"})

@app.route('/', methods=['GET'])
def root():
    """Root endpoint for testing"""
    print("🔍 Root endpoint called")
    return jsonify({"message": "Nutrition API is running", "endpoints": ["/health", "/generate-plan"]})

if __name__ == '__main__':
    import socket
    
    def get_local_ip():
        """Get the local IP address"""
        try:
            # Connect to a remote server to get local IP
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "127.0.0.1"
    
    local_ip = get_local_ip()
    
    print("🚀 Starting Nutrition & Fitness API server...")
    print("=" * 50)
    print("📡 API will be available at: http://localhost:5000")
    print("🌐 Server IP Address:", local_ip)
    print("📱 Server URL: http://" + local_ip + ":5000")
    print("🔗 Endpoints:")
    print("   - POST /generate-plan - Generate weekly plan")
    print("   - GET /health - Health check")
    print("📱 For Flutter app, update api_config.dart with this IP")
    print("=" * 50)
    
    if api_key == "placeholder_key":
        print("⚠️  WARNING: No valid Gemini API key found!")
        print("   To generate real plans, create a .env file with:")
        print("   GEMINI_API_KEY=your_actual_api_key")
        print("   Or set the environment variable")
        print("=" * 50)
    
    print("✅ Server starting... Press Ctrl+C to stop")
    print("=" * 50)
    
    try:
        app.run(debug=True, host='0.0.0.0', port=5000)
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"❌ Server error: {e}")
        print("Make sure port 5000 is available")