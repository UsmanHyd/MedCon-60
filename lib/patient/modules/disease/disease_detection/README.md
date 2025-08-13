# Disease Detection FastAPI Backend

This FastAPI backend connects the Flutter frontend with the disease detection model to provide real-time disease predictions based on symptoms.

## Setup Instructions

### 1. Install Dependencies

First, make sure you have Python 3.8+ installed. Then install the required packages:

```bash
pip install -r requirements.txt
```

### 2. Activate Virtual Environment (if using)

If you're using a virtual environment:

```bash
# Windows
disease-env\Scripts\activate

# Linux/Mac
source disease-env/bin/activate
```

### 3. Run the FastAPI Server

```bash
python predict.py
```

The server will start on `http://localhost:8000`

### 4. API Endpoints

- **GET /** - Health check
- **GET /health** - Server health status
- **POST /predict** - Disease prediction endpoint

### 5. API Usage

Send a POST request to `/predict` with the following JSON body:

```json
{
  "symptoms": ["fever", "headache", "fatigue"]
}
```

Response format:

```json
{
  "predictions": [
    {
      "disease": "Common Cold",
      "confidence": 85.5,
      "matched_symptoms": ["fever", "fatigue"],
      "treatments": ["rest", "fluids"],
      "status": "Monitor symptoms",
      "status_color": "#4CAF50"
    }
  ],
  "message": "Analysis complete. Please consult a healthcare professional for accurate diagnosis."
}
```

## Flutter Integration

The Flutter app will automatically connect to the FastAPI backend when you:

1. Select symptoms in the disease detection screen
2. Click "Check for Potential Diagnoses"
3. The app will show a loading indicator while making the API call
4. Results will be displayed in the diagnosis screen

## Troubleshooting

### Common Issues:

1. **Port already in use**: Change the port in `predict.py` line 200
2. **Model loading errors**: Make sure all model files are in the correct directory
3. **CORS errors**: The server is configured to allow all origins for development

### For Android Emulator:
- Use `http://10.0.2.2:8000` as the API URL
- For physical device, use your computer's IP address (e.g., `http://192.168.0.107:8000`)

### For iOS Simulator:
- Use `http://localhost:8000` as the API URL

## Model Information

The backend uses:
- BERT model for sequence classification
- Fuzzy string matching for symptom comparison
- Disease-symptom mapping from Hugging Face dataset
- Confidence scoring based on symptom matches

## Security Notes

- This is for development/demo purposes
- In production, add proper authentication and validation
- Consider rate limiting and input sanitization 