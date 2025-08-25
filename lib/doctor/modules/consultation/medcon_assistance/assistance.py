import pandas as pd
import joblib
from rapidfuzz import process, fuzz
import warnings

# Suppress scikit-learn UserWarnings
warnings.filterwarnings("ignore", category=UserWarning)

# Load trained model and encoders
model = joblib.load("medcon_medicine_model.pkl")
disease_encoder = joblib.load("disease_encoder.pkl")
medicine_encoder = joblib.load("medicine_encoder.pkl")

# Load disease list from training data
disease_list = list(disease_encoder.classes_)

print("=== MedCon Medicine Predictor ===")
print("Type 'quit' to exit.\n")

while True:
    user_input = input("Enter disease name: ").strip()
    if user_input.lower() == 'quit':
        break

    # Fuzzy match user input to closest disease in training data
    best_match, score, _ = process.extractOne(
        user_input, disease_list, scorer=fuzz.WRatio
    )

    if score < 60:  # similarity threshold
        print(f"Disease '{user_input}' not recognized.\n")
        continue

    # Encode and reshape for Random Forest prediction
    disease_encoded = disease_encoder.transform([best_match])
    disease_encoded_df = pd.DataFrame(disease_encoded, columns=['disease_encoded'])
    
    pred_encoded = model.predict(disease_encoded_df)
    medicine = medicine_encoder.inverse_transform(pred_encoded)

    print(f"Input matched to: {best_match} (score: {score})")
    print("Recommended medicine:", ", ".join(medicine), "\n")
