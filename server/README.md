# Prescription Assistant Flask API

This Flask API provides disease-based drug recommendations using the assistance.py module.

## Setup

1. Navigate to the assistance directory:
```bash
cd lib/doctor/modules/consultation/medcon_assistance/
```

2. Install Python dependencies:
```bash
pip install -r requirements.txt
```

3. Make sure the CSV datasets are in the correct paths:
   - `D:/University/semester8/FYP-2/medcon60/lib/doctor/modules/consultation/medcon_assistance/dataset/formulas_for_disease_cleaned.csv`
   - `D:/University/semester8/FYP-2/medcon60/lib/patient/modules/disease/dataset/symptoms_to_disease_detection.csv`

4. Run the assistance.py file:
```bash
python assistance.py
```

The API will be available at `http://localhost:5000`

## Usage Modes

- **Flask API Mode**: Run `python assistance.py` (no arguments) to start the web server
- **CLI Mode**: Run `python assistance.py --cli` to use the original command-line interface

## API Endpoints

### GET /api/health
Health check endpoint to verify the API is running and datasets are loaded.

### GET /api/diseases
Returns all available diseases from the symptoms dataset.

### POST /api/drugs-for-disease
Get drug recommendations for a specific disease.

**Request Body:**
```json
{
  "disease": "migraine",
  "threshold": 85
}
```

**Response:**
```json
{
  "success": true,
  "input_disease": "migraine",
  "matched_symptom_disease": "migraine",
  "matched_formula_disease": "migraine",
  "drugs": ["Sumatriptan", "Rizatriptan", "Topiramate"],
  "message": "Found 3 drugs for migraine"
}
```

## Usage in Flutter

The Flutter app uses the `PrescriptionService` class to communicate with this API. Make sure the Flask server is running before using the prescription assistant screen.
