import pandas as pd
from rapidfuzz import fuzz, process
from flask import Flask, request, jsonify
from flask_cors import CORS

# --- Step 1: Load formulas dataset (Disease → Drug) ---
df_formulas = pd.read_csv(
    "D:/University/semester8/FYP-2/medcon60/lib/doctor/modules/consultation/medcon_assistance/dataset/formulas_for_disease_cleaned.csv"
)
df_formulas = df_formulas.dropna(subset=["Disease"])
df_formulas["Disease"] = df_formulas["Disease"].str.strip().str.lower()

# --- Step 2: Load predicted diseases dataset (from symptoms) ---
df_predicted = pd.read_csv(
    "D:/University/semester8/FYP-2/medcon60/lib/patient/modules/disease/dataset/symptoms_to_disease_detection.csv"
)
df_predicted = df_predicted.dropna(subset=["Disease"])
df_predicted["Disease"] = df_predicted["Disease"].str.strip().str.lower()

# --- Step 3: Function for drug lookup ---
def get_drugs_for_disease(user_input, threshold=85):
    user_input = user_input.strip().lower()

    # on p. Check if disease exists in symptoms dataset
    best_symptom_match = process.extractOne(
        user_input, df_predicted["Disease"].unique(), scorer=fuzz.ratio
    )
    if not best_symptom_match or best_symptom_match[1] < threshold:
        return f"❌ '{user_input}' not found in symptoms dataset."

    matched_symptom_disease = best_symptom_match[0]

    # 2. Match with formulas dataset
    best_formula_match = process.extractOne(
        matched_symptom_disease, df_formulas["Disease"].unique(), scorer=fuzz.ratio
    )
    if not best_formula_match or best_formula_match[1] < threshold:
        return f"⚠️ No drug found for '{matched_symptom_disease}'."

    matched_formula_disease = best_formula_match[0]

    # 3. Get drugs
    drugs = df_formulas.loc[
        df_formulas["Disease"] == matched_formula_disease, "Drug"
    ].dropna().unique().tolist()

    if not drugs:
        return f"⚠️ No drugs listed for '{matched_formula_disease}'."

    # Format result nicely
    result = f"""
🔍 Input: {user_input}
✅ Matched disease (symptoms dataset): {matched_symptom_disease}
✅ Matched disease (formulas dataset): {matched_formula_disease}
💊 Recommended drugs: {", ".join(drugs)}
"""
    return result.strip()

# --- Step 4: Flask API Setup ---
app = Flask(__name__)
CORS(app)

@app.route('/api/drugs-for-disease', methods=['POST'])
def api_get_drugs_for_disease():
    try:
        data = request.get_json()
        disease_name = data.get('disease', '').strip().lower()
        threshold = data.get('threshold', 85)
        
        if not disease_name:
            return jsonify({'error': 'Disease name is required'}), 400
        
        # 1. Check if disease exists in symptoms dataset
        best_symptom_match = process.extractOne(
            disease_name, df_predicted["Disease"].unique(), scorer=fuzz.ratio
        )
        
        if not best_symptom_match or best_symptom_match[1] < threshold:
            return jsonify({
                'success': False,
                'message': f"'{disease_name}' not found in symptoms dataset.",
                'drugs': []
            })
        
        matched_symptom_disease = best_symptom_match[0]
        
        # 2. Match with formulas dataset
        best_formula_match = process.extractOne(
            matched_symptom_disease, df_formulas["Disease"].unique(), scorer=fuzz.ratio
        )
        
        if not best_formula_match or best_formula_match[1] < threshold:
            return jsonify({
                'success': False,
                'message': f"No drug found for '{matched_symptom_disease}'.",
                'drugs': []
            })
        
        matched_formula_disease = best_formula_match[0]
        
        # 3. Get drugs
        drugs = df_formulas.loc[
            df_formulas["Disease"] == matched_formula_disease, "Drug"
        ].dropna().unique().tolist()
        
        if not drugs:
            return jsonify({
                'success': False,
                'message': f"No drugs listed for '{matched_formula_disease}'.",
                'drugs': []
            })
        
        return jsonify({
            'success': True,
            'input_disease': disease_name,
            'matched_symptom_disease': matched_symptom_disease,
            'matched_formula_disease': matched_formula_disease,
            'drugs': drugs,
            'message': f"Found {len(drugs)} drugs for {matched_formula_disease}"
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/diseases', methods=['GET'])
def api_get_all_diseases():
    try:
        diseases = df_predicted["Disease"].unique().tolist()
        return jsonify({
            'success': True,
            'diseases': diseases,
            'count': len(diseases)
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/search-formulas', methods=['POST'])
def api_search_formulas():
    try:
        data = request.get_json()
        query = data.get('query', '').strip().lower()
        limit = data.get('limit', 10)
        
        if not query or len(query) < 2:
            return jsonify({
                'success': True,
                'formulas': [],
                'message': 'Query too short. Please enter at least 2 characters.'
            })
        
        # Search in drugs/formulas
        all_drugs = df_formulas["Drug"].dropna().unique().tolist()
        
        # Use fuzzy matching to find similar drugs
        matches = process.extract(
            query, 
            all_drugs, 
            scorer=fuzz.partial_ratio,
            limit=limit
        )
        
        # Filter matches with score >= 60
        filtered_matches = [
            {'name': match[0], 'score': match[1]} 
            for match in matches 
            if match[1] >= 60
        ]
        
        return jsonify({
            'success': True,
            'formulas': filtered_matches,
            'query': query,
            'count': len(filtered_matches)
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/health', methods=['GET'])
def api_health_check():
    return jsonify({'status': 'healthy', 'datasets_loaded': True})

# --- Step 5: Run Flask app or CLI ---
if __name__ == "__main__":
    import sys
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
    
    # Check if running as Flask app (no arguments) or CLI (with arguments)
    if len(sys.argv) == 1:
        local_ip = get_local_ip()
        
        print("🚀 Starting Flask API server...")
        print("📊 Datasets loaded successfully!")
        print("🌐 API available at: http://0.0.0.0:5001")
        print("🌐 Server IP Address:", local_ip)
        print("📱 Server URL: http://" + local_ip + ":5001")
        print("📱 For Android emulator: http://10.0.2.2:5001")
        print("💻 For localhost: http://127.0.0.1:5001")
        print("📱 For Flutter app, update api_config.dart with this IP")
        print("📋 Available endpoints:")
        print("   GET  /api/health")
        print("   GET  /api/diseases") 
        print("   POST /api/drugs-for-disease")
        print("\nPress Ctrl+C to stop the server")
        app.run(host='0.0.0.0', port=5001, debug=True)
    else:
        # CLI mode - original functionality
        disease_name = input("Enter disease name: ")
        result = get_drugs_for_disease(disease_name)
        print(result)
