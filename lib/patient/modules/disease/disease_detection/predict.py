# disease-env\Scripts\activate      then py predict.py
# pip install torch -i https://pypi.tuna.tsinghua.edu.cn/simple
# pip install transformers==4.40.1
# pip install scikit-learn -i https://pypi.tuna.tsinghua.edu.cn/simple
# pip install numpy==1.26.4 -i https://pypi.tuna.tsinghua.edu.cn/simple
# pip install datasets, fuzzywuzzy, 


import torch
from transformers import BertTokenizer, BertForSequenceClassification
from datasets import load_dataset
import pandas as pd
import joblib
import os
from collections import defaultdict
from fuzzywuzzy import fuzz
import warnings
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Any

# Suppress sklearn version warning
warnings.filterwarnings("ignore", category=UserWarning)

# FastAPI app setup
app = FastAPI(title="Disease Detection API", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class SymptomRequest(BaseModel):
    symptoms: List[str]

class DiseasePrediction(BaseModel):
    disease: str
    confidence: float
    matched_symptoms: List[str]
    treatments: List[str]
    status: str
    status_color: str

class PredictionResponse(BaseModel):
    predictions: List[DiseasePrediction]
    message: str

print("📥 Downloading dataset from Hugging Face...")
dataset = load_dataset("kamruzzaman-asif/Diseases_Dataset", split="QuyenAnh")
df = dataset.to_pandas()

# Clean and map symptoms
disease_symptom_map = dict(zip(df["Disease"], df["Symptoms"]))
disease_treatment_map = dict(zip(df["Disease"], df.get("Treatments", [""] * len(df))))  # Add treatment mapping

for disease in disease_symptom_map:
    if isinstance(disease_symptom_map[disease], str):
        disease_symptom_map[disease] = [s.strip().lower() for s in disease_symptom_map[disease].split(",")]
    else:
        disease_symptom_map[disease] = []

# Clean treatment data
for disease in disease_treatment_map:
    if isinstance(disease_treatment_map[disease], str):
        disease_treatment_map[disease] = [t.strip() for t in disease_treatment_map[disease].split(",") if t.strip()]
    else:
        disease_treatment_map[disease] = []

# Load BERT
print("🔄 Loading BERT model from: bert_model")
model = BertForSequenceClassification.from_pretrained("bert_model")
tokenizer = BertTokenizer.from_pretrained("bert_model")
model.eval()

# Load label encoder
label_encoder = joblib.load("label_encoder.pkl")

def get_status_info(confidence: float) -> tuple[str, str]:
    """Get status and color based on confidence level"""
    if confidence >= 80:
        return "High Risk - Strong match, consult doctor", "#F44336"  # Red
    elif confidence >= 60:
        return "Moderate Risk - Possible match, needs evaluation", "#FFEB3B"  # Yellow
    elif confidence >= 50:
        return "Low Risk - Uncertain, monitor symptoms", "#03A9F4"  # Light Blue
    else:
        return "Low Risk - Uncertain, monitor symptoms", "#4CAF50"  # Green

def predict_diseases_api(user_symptoms: List[str]) -> List[DiseasePrediction]:
    """Predict diseases based on symptoms for API"""
    if not user_symptoms:
        raise HTTPException(status_code=400, detail="At least one symptom is required")
    
    # Convert symptoms to lowercase for matching
    user_symptoms = [s.strip().lower() for s in user_symptoms if s.strip()]
    
    # Matching Logic (same as original)
    scores = []
    for disease, symptoms in disease_symptom_map.items():
        if not symptoms:
            continue

        # Count how many disease symptoms were matched by user symptoms
        matched_disease_symptoms = set()
        for usym in user_symptoms:
            for dsym in symptoms:
                if fuzz.token_sort_ratio(usym, dsym) >= 70:  # Threshold for matching
                    matched_disease_symptoms.add(dsym)

        # Calculate percentage: (matched symptoms / total disease symptoms) * 100
        match_percentage = (len(matched_disease_symptoms) / len(symptoms)) * 100
        scores.append((disease, round(match_percentage, 1), matched_disease_symptoms))

    scores = sorted(scores, key=lambda x: x[1], reverse=True)
    
    predictions = []
    
    # Add top 5 fuzzy matches
    for disease, confidence, matched_symptoms in scores[:5]:
        if confidence > 0:  # Only include if there's some match
            treatments = disease_treatment_map.get(disease, [])
            status, status_color = get_status_info(confidence)
            
            predictions.append(DiseasePrediction(
                disease=disease,
                confidence=confidence,
                matched_symptoms=list(matched_symptoms),
                treatments=treatments,
                status=status,
                status_color=status_color
            ))
    
    # Use BERT if no good fuzzy matches (same logic as original)
    if not predictions or predictions[0].confidence < 30:
        try:
            input_text = " ".join(user_symptoms)
            inputs = tokenizer(input_text, return_tensors="pt", truncation=True, padding=True)
            with torch.no_grad():
                outputs = model(**inputs)
                predicted_idx = torch.argmax(outputs.logits).item()
                predicted_disease = label_encoder.inverse_transform([predicted_idx])[0]
            
            # Get matched symptoms for BERT prediction
            disease_symptoms = disease_symptom_map.get(predicted_disease, [])
            matched_symptoms = set()
            for user_sym in user_symptoms:
                for disease_sym in disease_symptoms:
                    if fuzz.token_sort_ratio(user_sym, disease_sym) >= 70:
                        matched_symptoms.add(disease_sym)
            
            treatments = disease_treatment_map.get(predicted_disease, [])
            status, status_color = get_status_info(30)  # Lower confidence for BERT fallback
            
            bert_prediction = DiseasePrediction(
                disease=predicted_disease,
                confidence=30.0,  # Lower confidence for BERT fallback
                matched_symptoms=list(matched_symptoms),
                treatments=treatments,
                status=status,
                status_color=status_color
            )
            
            # Add BERT prediction if not already in list
            if not any(p.disease == predicted_disease for p in predictions):
                predictions.insert(0, bert_prediction)
                
        except Exception as e:
            print(f"BERT prediction error: {e}")
    
    return predictions

# Original CLI functionality (commented out for API mode)
# print("\n💊 Enter symptoms. Type 'exit' to quit.")
# while True:
#     user_input = input("Symptoms > ")
#     if user_input.strip().lower() == "exit":
#         break

#     user_symptoms = [s.strip().lower() for s in user_input.split(",") if s.strip()]

#     if not user_symptoms:
#         print("⚠️ Please enter at least one symptom.\n")
#         continue

# FastAPI Endpoints
@app.get("/")
async def root():
    return {"message": "Disease Detection API is running!"}

@app.post("/predict", response_model=PredictionResponse)
async def predict_disease(request: SymptomRequest):
    """Predict diseases based on symptoms"""
    try:
        predictions = predict_diseases_api(request.symptoms)
        
        if not predictions:
            return PredictionResponse(
                predictions=[],
                message="No diseases found matching your symptoms. Please consult a healthcare professional."
            )
        
        return PredictionResponse(
            predictions=predictions,
            message="Analysis complete. Please consult a healthcare professional for accurate diagnosis."
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "models_loaded": model is not None}

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Disease Detection FastAPI Server...")
    print("📍 Server will be available at: http://localhost:8000")
    print("📱 For Android emulator, use: http://10.0.2.2:8000")
    print("🍎 For iOS simulator, use: http://localhost:8000")
    print("\n" + "="*50)
    uvicorn.run(app, host="0.0.0.0", port=8000)
