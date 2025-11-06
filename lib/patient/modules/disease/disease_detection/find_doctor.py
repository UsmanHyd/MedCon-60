"""
Doctor Recommendation System using Gemini AI

This module:
1. Fetches the latest disease predictions from Firebase
2. Uses Gemini API to map diseases to doctor specialties
3. Fetches relevant doctors from Firestore
4. Returns structured recommendations in 3 categories:
   - Recommended doctors (for top disease)
   - Other relevant doctors (for remaining diseases)
   - All doctors (grouped by specialty)
"""

import os
import json
import re
from typing import List, Dict, Any, Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv
import google.generativeai as genai
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Load environment variables from project root
import pathlib
# Path: lib/patient/modules/disease/disease_detection/find_doctor.py
# Go up 6 levels: disease_detection -> disease -> modules -> patient -> lib -> root
project_root = pathlib.Path(__file__).resolve().parent.parent.parent.parent.parent.parent
env_file = project_root / ".env"

if env_file.exists():
    load_dotenv(env_file)
    print(f"✅ Loaded .env from project root: {env_file}")
else:
    # Fallback to default load_dotenv() behavior
    load_dotenv()
    print("⚠️ .env file not found at project root, trying default locations")

# Initialize FastAPI app
app = FastAPI(title="Doctor Recommendation API", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Firebase Admin
try:
    # Try to use serviceAccountKey.json in the disease_detection folder first
    service_account_path = os.path.join(os.path.dirname(__file__), "serviceAccountKey.json")
    if not os.path.exists(service_account_path):
        # Fall back to server directory
        service_account_path = os.path.join(
            os.path.dirname(__file__), "..", "..", "..", "..", "..", "server", "serviceAccountKey.json"
        )
    
    if os.path.exists(service_account_path):
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
        print("✅ Firebase Admin initialized successfully")
    else:
        # Try using environment variable
        if os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
            firebase_admin.initialize_app()
            print("✅ Firebase Admin initialized using GOOGLE_APPLICATION_CREDENTIALS")
        else:
            raise FileNotFoundError("serviceAccountKey.json not found")
except Exception as e:
    print(f"⚠️ Firebase initialization error: {e}")
    print("⚠️ Doctor recommendations will not work without Firebase connection")
    db = None
else:
    try:
        db = firestore.client()
    except Exception as e:
        print(f"⚠️ Error getting Firestore client: {e}")
        db = None

# Configure Gemini API
gemini_api_key = os.getenv("GEMINI_API_KEY")
gemini_model = None  # Initialize to None first

if not gemini_api_key or gemini_api_key == "your_gemini_api_key_here":
    print("⚠️ GEMINI_API_KEY not found in .env file!")
    print(f"⚠️ Please create a .env file at project root ({env_file}) with: GEMINI_API_KEY=your_actual_api_key")
    print("⚠️ Gemini API is required for doctor recommendations. Please configure it.")
    gemini_model = None
else:
    try:
        genai.configure(api_key=gemini_api_key)
        gemini_model = genai.GenerativeModel("gemini-2.0-flash")
        print("✅ Gemini AI configured successfully")
    except Exception as e:
        print(f"❌ Error configuring Gemini: {e}")
        print("⚠️ Please check your GEMINI_API_KEY in .env file")
        gemini_model = None

# Pydantic models
class DiseaseSpecialtyRequest(BaseModel):
    user_id: str

class DoctorRecommendation(BaseModel):
    id: str
    name: str
    specialization: str
    email: str
    phone: Optional[str] = None
    profileImage: Optional[str] = None
    rating: float = 0.0
    reviewCount: int = 0
    experienceYears: int = 0
    hospital: Optional[str] = None
    address: Optional[str] = None
    consultationFee: Optional[float] = None

class DiseaseSpecialtyMapping(BaseModel):
    disease: str
    specialty: str
    reason: str

class DoctorRecommendationsResponse(BaseModel):
    recommended_doctors: List[DoctorRecommendation]
    other_relevant_doctors: List[DoctorRecommendation]
    all_doctors_by_specialty: Dict[str, List[DoctorRecommendation]]
    disease_specialty_mappings: List[DiseaseSpecialtyMapping]
    message: str

# No hardcoded fallback - always use Gemini API

def get_latest_predictions(user_id: str) -> Optional[Dict[str, Any]]:
    """Fetch the latest disease prediction from Firebase symptom_checks collection"""
    if not db:
        return None
    
    try:
        # Query symptom_checks collection without order_by to avoid index requirement
        # We'll sort in Python instead
        predictions_query = (
            db.collection("symptom_checks")
            .where("userId", "==", user_id)
            .stream()
        )
        
        docs = []
        for doc in predictions_query:
            doc_data = doc.to_dict()
            doc_data["_doc_id"] = doc.id  # Store doc ID for reference
            docs.append(doc_data)
        
        if not docs:
            print(f"⚠️ No predictions found for user {user_id}")
            return None
        
        # Sort by createdAt in Python (latest first)
        def get_timestamp(doc):
            created_at = doc.get("createdAt")
            if created_at:
                # Handle Firestore Timestamp
                if hasattr(created_at, 'seconds'):
                    return created_at.seconds
                elif isinstance(created_at, dict) and 'seconds' in created_at:
                    return created_at['seconds']
                elif isinstance(created_at, datetime):
                    return created_at.timestamp()
            return 0
        
        # Sort documents by createdAt, newest first
        docs.sort(key=get_timestamp, reverse=True)
        
        latest_doc = docs[0]
        # Remove the temporary _doc_id field
        if "_doc_id" in latest_doc:
            del latest_doc["_doc_id"]
        
        print(f"✅ Found {len(docs)} prediction(s), using latest one")
        return latest_doc
        
    except Exception as e:
        print(f"❌ Error fetching predictions: {e}")
        import traceback
        traceback.print_exc()
        return None

def get_doctor_specialties_from_gemini(diseases: List[Dict[str, Any]]) -> List[Dict[str, str]]:
    """Use Gemini API to map diseases to doctor specialties"""
    # Check if gemini_model is available
    try:
        # Check if gemini_model exists in module globals
        import sys
        current_module = sys.modules[__name__]
        gemini_model_ref = getattr(current_module, 'gemini_model', None)
        
        if not gemini_model_ref:
            raise Exception("Gemini API key not configured. Please set GEMINI_API_KEY in .env file at project root.")
            
        # Store reference for use in this function
        model = gemini_model_ref
    except (NameError, AttributeError, Exception) as e:
        error_msg = f"Gemini model not available: {e}. Please configure GEMINI_API_KEY in .env file at project root."
        print(f"❌ {error_msg}")
        raise Exception(error_msg)
    
    disease_names = [d.get("disease", "") for d in diseases if d.get("disease")]
    
    if not disease_names:
        return []
    
    prompt = f"""
    You are a medical AI assistant. Given the following diseases detected from symptoms:
    
    {', '.join(disease_names)}
    
    For each disease, determine:
    1. The most appropriate doctor specialty (e.g., Cardiologist, Pulmonologist, Neurologist, Dermatologist, etc.)
    2. A brief reason why this specialty is recommended
    
    Return ONLY a valid JSON object with this exact structure (no markdown, no code blocks, just JSON):
    {{
      "recommendations": [
        {{
          "disease": "Disease Name",
          "specialty": "Specialty Name",
          "reason": "Brief reason"
        }}
      ]
    }}
    
    IMPORTANT:
    - Return ONLY valid JSON, no other text
    - Use standard medical specialty names (Cardiologist, Pulmonologist, Neurologist, etc.)
    - Make sure each disease has a corresponding recommendation
    """
    
    try:
        # Use the model reference we safely obtained
        response = model.generate_content(prompt)
        response_text = response.text.strip()
        
        # Remove markdown code blocks if present
        response_text = re.sub(r'```json\s*', '', response_text)
        response_text = re.sub(r'```\s*', '', response_text)
        response_text = response_text.strip()
        
        # Extract JSON from response
        start_idx = response_text.find('{')
        end_idx = response_text.rfind('}')
        
        if start_idx != -1 and end_idx != -1:
            json_text = response_text[start_idx:end_idx + 1]
            result = json.loads(json_text)
            return result.get("recommendations", [])
        else:
            raise Exception("Could not parse Gemini response - invalid JSON format")
            
    except Exception as e:
        error_msg = f"Gemini API error: {e}. Please check your API key and try again."
        print(f"❌ {error_msg}")
        raise Exception(error_msg)

def normalize_specialty(specialty: str) -> str:
    """Normalize specialty names for matching (handle variations)"""
    specialty_lower = specialty.lower().strip()
    
    # Common variations
    mappings = {
        "cardiologist": "Cardiologist",
        "cardiology": "Cardiologist",
        "heart specialist": "Cardiologist",
        "pulmonologist": "Pulmonologist",
        "pulmonology": "Pulmonologist",
        "lung specialist": "Pulmonologist",
        "respiratory specialist": "Pulmonologist",
        "neurologist": "Neurologist",
        "neurology": "Neurologist",
        "dermatologist": "Dermatologist",
        "dermatology": "Dermatologist",
        "skin specialist": "Dermatologist",
        "gastroenterologist": "Gastroenterologist",
        "gastroenterology": "Gastroenterologist",
        "endocrinologist": "Endocrinologist",
        "endocrinology": "Endocrinologist",
        "hematologist": "Hematologist",
        "hematology": "Hematologist",
        "oncologist": "Oncologist",
        "oncology": "Oncologist",
        "orthopedist": "Orthopedist",
        "orthopedics": "Orthopedist",
        "orthopedic": "Orthopedist",
        "orthopedic surgeon": "Orthopedist",
        "general practitioner": "General Practitioner",
        "gp": "General Practitioner",
        "family doctor": "General Practitioner",
    }
    
    return mappings.get(specialty_lower, specialty)  # Return original if no match

def get_doctors_by_specialty(specialty: str) -> List[Dict[str, Any]]:
    """Fetch doctors from Firestore by specialty"""
    if not db:
        return []
    
    try:
        normalized_specialty = normalize_specialty(specialty)
        doctors = []
        
        # Query doctors collection - try "specializations" (array) first (most common)
        # Since we can't normalize in Firestore queries, we need to fetch and filter
        try:
            # Get all doctors and filter by normalized specialty
            doctors_query = db.collection("doctors").stream()
            
            for doc in doctors_query:
                doc_data = doc.to_dict()
                specializations = doc_data.get("specializations", [])
                
                # Check if any specialization in the array matches (after normalization)
                if isinstance(specializations, list):
                    for spec in specializations:
                        if spec:
                            # Normalize the specialty from database and compare
                            normalized_db_spec = normalize_specialty(str(spec))
                            if normalized_db_spec == normalized_specialty:
                                doc_data["id"] = doc.id
                                doctors.append(doc_data)
                                break  # Found a match, no need to check other specializations
        except Exception as e:
            print(f"⚠️ Error querying by 'specializations' array: {e}")
        
        # If no results, try with "specialization" (singular string) field
        if not doctors:
            try:
                doctors_query = (
                    db.collection("doctors")
                    .where("specialization", "==", normalized_specialty)
                    .limit(20)
                    .stream()
                )
                
                for doc in doctors_query:
                    doc_data = doc.to_dict()
                    doc_data["id"] = doc.id
                    doctors.append(doc_data)
                print(f"✅ Query by 'specialization' string: found {len(doctors)} doctors")
            except Exception as e:
                print(f"⚠️ Error querying by 'specialization': {e}")
        
        # If no results, try with "specialty" field
        if not doctors:
            try:
                doctors_query = (
                    db.collection("doctors")
                    .where("specialty", "==", normalized_specialty)
                    .limit(20)
                    .stream()
                )
                
                for doc in doctors_query:
                    doc_data = doc.to_dict()
                    doc_data["id"] = doc.id
                    doctors.append(doc_data)
                print(f"✅ Query by 'specialty': found {len(doctors)} doctors")
            except Exception as e:
                print(f"⚠️ Error querying by 'specialty': {e}")
        
        # If still no results, try fuzzy matching by fetching all and filtering
        if not doctors:
            print(f"⚠️ No exact match found for '{normalized_specialty}', trying fuzzy match...")
            doctors_query = db.collection("doctors").stream()
            
            for doc in doctors_query:
                doc_data = doc.to_dict()
                doc_id = doc.id
                
                # Skip if already in list
                if any(d.get("id") == doc_id for d in doctors):
                    continue
                
                # Check specializations array with normalization
                specializations = doc_data.get("specializations", [])
                if isinstance(specializations, list):
                    for spec in specializations:
                        if spec:
                            # Normalize and compare
                            normalized_db_spec = normalize_specialty(str(spec))
                            # Check for match after normalization
                            if (normalized_db_spec == normalized_specialty or
                                normalized_specialty.lower() in normalized_db_spec.lower() or
                                normalized_db_spec.lower() in normalized_specialty.lower()):
                                doc_data["id"] = doc_id
                                doctors.append(doc_data)
                                break
                
                # Also check singular fields with normalization
                if not any(d.get("id") == doc_id for d in doctors):
                    doc_specialty = (doc_data.get("specialization", "") or 
                                    doc_data.get("specialty", "")).strip()
                    
                    if doc_specialty:
                        normalized_db_spec = normalize_specialty(doc_specialty)
                        # Fuzzy match after normalization
                        if (normalized_db_spec == normalized_specialty or
                            normalized_specialty.lower() in normalized_db_spec.lower() or
                            normalized_db_spec.lower() in normalized_specialty.lower()):
                            doc_data["id"] = doc_id
                            doctors.append(doc_data)
        
        print(f"📊 Found {len(doctors)} doctors for specialty '{normalized_specialty}'")
        return doctors
    except Exception as e:
        print(f"❌ Error fetching doctors: {e}")
        import traceback
        traceback.print_exc()
        return []

def get_all_doctors_grouped() -> Dict[str, List[Dict[str, Any]]]:
    """Fetch all doctors from Firestore and group by specialty"""
    if not db:
        print("❌ Firestore database not available")
        return {}
    
    try:
        doctors_query = db.collection("doctors").stream()
        doctors_by_specialty = {}
        count = 0
        
        for doc in doctors_query:
            count += 1
            doc_data = doc.to_dict()
            doc_data["id"] = doc.id
            
            # Handle specializations as array (most common case)
            specializations = doc_data.get("specializations", [])
            if isinstance(specializations, list) and len(specializations) > 0:
                # If doctor has multiple specializations, add to each one
                for spec in specializations:
                    if spec:
                        normalized_specialty = normalize_specialty(str(spec))
                        if normalized_specialty not in doctors_by_specialty:
                            doctors_by_specialty[normalized_specialty] = []
                        doctors_by_specialty[normalized_specialty].append(doc_data)
            else:
                # Fallback to singular specialization/specialty field
                specialty = (doc_data.get("specialization", "") or 
                           doc_data.get("specialty", "General Practitioner"))
                if not specialty:
                    specialty = "General Practitioner"
                normalized_specialty = normalize_specialty(specialty)
                
                if normalized_specialty not in doctors_by_specialty:
                    doctors_by_specialty[normalized_specialty] = []
                
                doctors_by_specialty[normalized_specialty].append(doc_data)
        
        print(f"📊 Total doctors processed: {count}")
        print(f"📊 Doctors grouped into {len(doctors_by_specialty)} specialties")
        if count == 0:
            print("⚠️ WARNING: No doctors found in database! Make sure doctors collection exists in Firestore.")
        
        return doctors_by_specialty
    except Exception as e:
        print(f"❌ Error fetching all doctors: {e}")
        import traceback
        traceback.print_exc()
        return {}

def convert_doctor_to_model(doctor_data: Dict[str, Any]) -> DoctorRecommendation:
    """Convert Firestore doctor document to Pydantic model"""
    # Handle specializations array (most common) - take first one for display
    specializations = doctor_data.get("specializations", [])
    if isinstance(specializations, list) and len(specializations) > 0:
        specialization = str(specializations[0])  # Use first specialization
    else:
        # Fallback to singular fields
        specialization = (doctor_data.get("specialization") or 
                         doctor_data.get("specialty") or 
                         "General Practitioner")
    
    # Handle location - can be in different fields
    location = (doctor_data.get("location") or 
                doctor_data.get("address") or "")
    
    # Handle experience - can be array or number
    experience_years = 0
    experience = doctor_data.get("experience")
    if isinstance(experience, list) and len(experience) > 0:
        # If it's an array, try to extract years somehow (for now just use 0)
        experience_years = 0
    elif isinstance(experience, (int, float)):
        experience_years = int(experience)
    else:
        experience_years = doctor_data.get("experienceYears") or 0
    
    return DoctorRecommendation(
        id=doctor_data.get("id", ""),
        name=doctor_data.get("name", "Unknown Doctor"),
        specialization=specialization,
        email=doctor_data.get("email", ""),
        phone=doctor_data.get("phone") or doctor_data.get("phoneNumber"),
        profileImage=(doctor_data.get("profileImage") or 
                     doctor_data.get("profilePic") or 
                     doctor_data.get("avatar") or
                     doctor_data.get("profilePicture")),
        rating=(doctor_data.get("rating") or 0.0) if isinstance(doctor_data.get("rating"), (int, float)) else 0.0,
        reviewCount=doctor_data.get("reviewCount") or 0,
        experienceYears=experience_years,
        hospital=doctor_data.get("hospital"),
        address=location,
        consultationFee=(doctor_data.get("consultationFee") or 0.0) if isinstance(doctor_data.get("consultationFee"), (int, float)) else None,
    )

@app.get("/")
async def root():
    return {"message": "Doctor Recommendation API is running!"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    firebase_status = "connected" if db else "disconnected"
    gemini_status = "configured" if gemini_model else "not configured"
    
    return {
        "status": "healthy",
        "firebase": firebase_status,
        "gemini": gemini_status
    }

@app.post("/find-doctors", response_model=DoctorRecommendationsResponse)
async def find_doctors(request: DiseaseSpecialtyRequest):
    """
    Find doctors based on user's latest disease predictions
    
    1. Fetches latest predictions from Firebase
    2. Uses Gemini to map diseases to specialties
    3. Returns doctors in 3 categories:
       - Recommended (for top disease)
       - Other relevant (for other diseases)
       - All doctors (grouped by specialty)
    """
    try:
        user_id = request.user_id
        
        if not user_id:
            raise HTTPException(status_code=400, detail="user_id is required")
        
        # Fetch latest predictions
        print(f"🔍 Fetching predictions for user: {user_id}")
        
        # Always fetch all doctors first (for "All Doctors" tab)
        print("🔍 Fetching all doctors from database...")
        all_doctors_data = get_all_doctors_grouped()
        all_doctors_by_specialty = {
            specialty: [convert_doctor_to_model(d) for d in doctors]
            for specialty, doctors in all_doctors_data.items()
        }
        print(f"✅ Found {sum(len(docs) for docs in all_doctors_data.values())} total doctors")
        
        # Try to get predictions (but don't fail if this doesn't work)
        prediction_data = None
        try:
            prediction_data = get_latest_predictions(user_id)
        except Exception as e:
            print(f"⚠️ Could not fetch predictions (this is okay): {e}")
            # Continue with just all doctors
        
        if not prediction_data:
            print("⚠️ No prediction data found - returning all doctors only")
            return DoctorRecommendationsResponse(
                recommended_doctors=[],
                other_relevant_doctors=[],
                all_doctors_by_specialty=all_doctors_by_specialty,
                disease_specialty_mappings=[],
                message=f"Showing all {sum(len(docs) for docs in all_doctors_data.values())} doctors. Check for diseases first to get personalized recommendations."
            )
        
        print(f"✅ Found prediction data with keys: {list(prediction_data.keys())}")
        predictions = prediction_data.get("predictions", [])
        
        if not predictions or len(predictions) == 0:
            print("⚠️ No predictions array found in data")
            # Return all doctors we already fetched
            return DoctorRecommendationsResponse(
                recommended_doctors=[],
                other_relevant_doctors=[],
                all_doctors_by_specialty=all_doctors_by_specialty,
                disease_specialty_mappings=[],
                message=f"No diseases detected in your latest check. Showing all {sum(len(docs) for docs in all_doctors_data.values())} doctors."
            )
        
        print(f"📊 Found {len(predictions)} predictions")
        
        # Sort predictions by confidence (highest first) and take top 5
        sorted_predictions = sorted(
            predictions,
            key=lambda x: x.get("confidence", 0),
            reverse=True
        )[:5]
        
        # Get specialty mappings from Gemini (required - no fallback)
        try:
            specialty_mappings = get_doctor_specialties_from_gemini(sorted_predictions)
        except Exception as e:
            # If Gemini fails, return error message but still show all doctors
            print(f"❌ Failed to get specialty mappings: {e}")
            return DoctorRecommendationsResponse(
                recommended_doctors=[],
                other_relevant_doctors=[],
                all_doctors_by_specialty=all_doctors_by_specialty,
                disease_specialty_mappings=[],
                message=f"Gemini API error: {str(e)}. Showing all {sum(len(docs) for docs in all_doctors_data.values())} doctors. Please configure GEMINI_API_KEY in .env file."
            )
        
        # Extract recommended specialty (from top disease)
        recommended_doctors_list = []
        if specialty_mappings:
            top_specialty = specialty_mappings[0].get("specialty", "General Practitioner")
            print(f"🔍 Searching for doctors with specialty: {top_specialty}")
            doctors_data = get_doctors_by_specialty(top_specialty)
            print(f"✅ Found {len(doctors_data)} doctors for {top_specialty}")
            recommended_doctors_list = [convert_doctor_to_model(d) for d in doctors_data[:5]]  # Limit to 5
        
        # Get doctors for other diseases (remaining 4)
        other_doctors_list = []
        if len(specialty_mappings) > 1:
            seen_specialties = {specialty_mappings[0].get("specialty")}
            for mapping in specialty_mappings[1:]:
                specialty = mapping.get("specialty", "General Practitioner")
                if specialty not in seen_specialties:
                    print(f"🔍 Searching for doctors with specialty: {specialty}")
                    doctors_data = get_doctors_by_specialty(specialty)
                    print(f"✅ Found {len(doctors_data)} doctors for {specialty}")
                    # Add 1-2 doctors per specialty
                    other_doctors_list.extend([convert_doctor_to_model(d) for d in doctors_data[:2]])
                    seen_specialties.add(specialty)
        
        # Get all doctors grouped by specialty
        print("🔍 Fetching all doctors from database...")
        all_doctors_data = get_all_doctors_grouped()
        print(f"✅ Found {sum(len(docs) for docs in all_doctors_data.values())} total doctors across {len(all_doctors_data)} specialties")
        all_doctors_by_specialty = {
            specialty: [convert_doctor_to_model(d) for d in doctors]
            for specialty, doctors in all_doctors_data.items()
        }
        
        # Convert specialty mappings to response format
        disease_mappings = [
            DiseaseSpecialtyMapping(
                disease=m.get("disease", ""),
                specialty=m.get("specialty", ""),
                reason=m.get("reason", "")
            )
            for m in specialty_mappings
        ]
        
        return DoctorRecommendationsResponse(
            recommended_doctors=recommended_doctors_list,
            other_relevant_doctors=other_doctors_list[:8],  # Limit to 8 total
            all_doctors_by_specialty=all_doctors_by_specialty,
            disease_specialty_mappings=disease_mappings,
            message=f"Found {len(recommended_doctors_list)} recommended doctors and {len(other_doctors_list)} other relevant doctors."
        )
        
    except Exception as e:
        print(f"❌ Error in find_doctors: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error finding doctors: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    import socket
    
    def get_local_ip():
        """Get the local IP address"""
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "127.0.0.1"
    
    local_ip = get_local_ip()
    
    print("🚀 Starting Doctor Recommendation FastAPI Server...")
    print("📍 Server will be available at: http://localhost:8004")
    print("🌐 Server IP Address:", local_ip)
    print("📱 Server URL: http://" + local_ip + ":8004")
    print("📱 For Android emulator, use: http://10.0.2.2:8004")
    print("🍎 For iOS simulator, use: http://localhost:8004")
    print("📱 For Flutter app, update api_config.dart with this IP")
    print("\n" + "="*50)
    uvicorn.run(app, host="0.0.0.0", port=8004)

