"""
FastAPI ML service for sentiment analysis
"""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import joblib
import os
from typing import Dict, List
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Sentiment Analysis ML Service",
    description="A simple sentiment analysis API using scikit-learn",
    version="1.0.0"
)

# Global model variable
model = None

class TextInput(BaseModel):
    """Request model for prediction"""
    text: str

class PredictionResponse(BaseModel):
    """Response model for prediction"""
    text: str
    sentiment: str
    confidence: float
    prediction_label: int

class BatchTextInput(BaseModel):
    """Request model for batch prediction"""
    texts: List[str]

class BatchPredictionResponse(BaseModel):
    """Response model for batch prediction"""
    predictions: List[PredictionResponse]

def load_model():
    """Load the trained model"""
    # Try different possible paths for the model
    possible_paths = [
        "sentiment_model.joblib",  # Root directory (for local development)
        "../sentiment_model.joblib",  # One level up
        "models/sentiment_model.joblib",  # models directory
        "../models/sentiment_model.joblib",  # models directory one level up
        "/app/models/sentiment_model.joblib"  # Docker container path
    ]
    
    for model_path in possible_paths:
        if os.path.exists(model_path):
            logger.info(f"Loading model from {model_path}")
            return joblib.load(model_path)
    
    logger.error(f"Model not found in any of the expected paths: {possible_paths}")
    return None

@app.on_event("startup")
async def startup_event():
    """Load model on startup"""
    global model
    model = load_model()
    if model is None:
        logger.error("Failed to load model on startup!")
    else:
        logger.info("Model loaded successfully!")

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Sentiment Analysis ML Service",
        "version": "1.0.0",
        "status": "healthy" if model is not None else "model_not_loaded"
    }

@app.get("/healthz")
async def health_check():
    """Health check endpoint for Kubernetes"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    return {"status": "healthy", "model_loaded": True}

@app.post("/predict", response_model=PredictionResponse)
async def predict_sentiment(input_data: TextInput):
    """Predict sentiment for a single text"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        # Make prediction
        prediction = model.predict([input_data.text])[0]
        probability = model.predict_proba([input_data.text])[0]
        
        # Get confidence (probability of predicted class)
        confidence = probability[prediction]
        sentiment = "positive" if prediction == 1 else "negative"
        
        logger.info(f"Prediction: '{input_data.text}' → {sentiment} ({confidence:.2%})")
        
        return PredictionResponse(
            text=input_data.text,
            sentiment=sentiment,
            confidence=float(confidence),
            prediction_label=int(prediction)
        )
    
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

@app.post("/predict/batch", response_model=BatchPredictionResponse)
async def predict_sentiment_batch(input_data: BatchTextInput):
    """Predict sentiment for multiple texts"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    if len(input_data.texts) > 100:
        raise HTTPException(status_code=400, detail="Too many texts. Maximum 100 allowed.")
    
    try:
        predictions = []
        
        # Make predictions for all texts
        pred_labels = model.predict(input_data.texts)
        probabilities = model.predict_proba(input_data.texts)
        
        for text, pred_label, prob in zip(input_data.texts, pred_labels, probabilities):
            confidence = prob[pred_label]
            sentiment = "positive" if pred_label == 1 else "negative"
            
            predictions.append(PredictionResponse(
                text=text,
                sentiment=sentiment,
                confidence=float(confidence),
                prediction_label=int(pred_label)
            ))
        
        logger.info(f"Batch prediction completed for {len(input_data.texts)} texts")
        
        return BatchPredictionResponse(predictions=predictions)
    
    except Exception as e:
        logger.error(f"Batch prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Batch prediction failed: {str(e)}")

@app.get("/model/info")
async def model_info():
    """Get information about the loaded model"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    # Extract some model information
    tfidf_features = model.named_steps['tfidf'].get_feature_names_out() if hasattr(model.named_steps['tfidf'], 'get_feature_names_out') else []
    
    return {
        "model_type": str(type(model.named_steps['classifier']).__name__),
        "feature_count": len(tfidf_features) if len(tfidf_features) > 0 else "Unknown",
        "pipeline_steps": list(model.named_steps.keys()),
        "is_fitted": hasattr(model.named_steps['classifier'], 'coef_')
    }
