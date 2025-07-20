"""
Train a simple sentiment analysis model using scikit-learn
"""
import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import joblib
import os

def create_sample_data():
    """Create a simple dataset for sentiment analysis"""
    # Sample data - in production you'd use a real dataset
    texts = [
        "I love this product, it's amazing!",
        "This is the worst thing ever",
        "Great quality and fast delivery",
        "Terrible customer service",
        "Excellent value for money",
        "Not recommended, poor quality",
        "Outstanding performance",
        "Completely disappointed",
        "Best purchase I've made",
        "Waste of money",
        "Highly recommended",
        "Poor quality control",
        "Fantastic experience",
        "Never buying again",
        "Perfect for my needs",
        "Overpriced and underwhelming",
        "Exceeded my expectations",
        "Regret this purchase",
        "Brilliant product design",
        "Useless and broken",
        # Add more samples for better training
        "Good value", "Bad experience", "Love it", "Hate it",
        "Wonderful", "Awful", "Nice quality", "Poor service",
        "Happy with purchase", "Disappointed", "Great job", "Terrible",
        "Satisfied customer", "Unsatisfied", "Positive experience", "Negative feedback",
        "Amazing results", "Horrible quality", "Perfect fit", "Completely wrong",
        "Excellent support", "No help at all", "Beautiful design", "Ugly appearance",
        "Fast shipping", "Very slow delivery", "Great price", "Too expensive",
        "Works perfectly", "Doesn't work", "Highly satisfied", "Very unhappy",
        "Impressive quality", "Cheaply made", "Exactly as described", "Nothing like advertised"
    ]
    
    labels = [
        # First 20 - alternating positive(1)/negative(0)
        1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,  
        # "Good value", "Bad experience", "Love it", "Hate it", 
        1, 0, 1, 0,
        # "Wonderful", "Awful", "Nice quality", "Poor service",
        1, 0, 1, 0,
        # "Happy with purchase", "Disappointed", "Great job", "Terrible",
        1, 0, 1, 0,
        # "Satisfied customer", "Unsatisfied", "Positive experience", "Negative feedback",
        1, 0, 1, 0,
        # "Amazing results", "Horrible quality", "Perfect fit", "Completely wrong",
        1, 0, 1, 0,
        # "Excellent support", "No help at all", "Beautiful design", "Ugly appearance",
        1, 0, 1, 0,
        # "Fast shipping", "Very slow delivery", "Great price", "Too expensive",
        1, 0, 1, 0,
        # "Works perfectly", "Doesn't work", "Highly satisfied", "Very unhappy",
        1, 0, 1, 0,
        # "Impressive quality", "Cheaply made", "Exactly as described", "Nothing like advertised"
        1, 0, 1, 0
    ]
    
    # Verify lengths match
    print(f"Texts: {len(texts)}, Labels: {len(labels)}")
    assert len(texts) == len(labels), f"Length mismatch: {len(texts)} texts vs {len(labels)} labels"
    
    return pd.DataFrame({
        'text': texts,
        'sentiment': labels  # 1 = positive, 0 = negative
    })

def train_sentiment_model():
    """Train the sentiment analysis model"""
    print("Starting model training...")
    
    # Create sample data
    df = create_sample_data()
    print(f"Dataset size: {len(df)} samples")
    print(f"   Positive: {sum(df['sentiment'])} samples")
    print(f"   Negative: {len(df) - sum(df['sentiment'])} samples")
    
    # Split the data
    X = df['text']
    y = df['sentiment']
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    # Create ML pipeline
    model = Pipeline([
        ('tfidf', TfidfVectorizer(
            max_features=1000,
            ngram_range=(1, 2),
            stop_words='english'
        )),
        ('classifier', LogisticRegression(random_state=42))
    ])
    
    # Train the model
    print("Training model...")
    model.fit(X_train, y_train)
    
    # Evaluate
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    print(f"Model training completed!")
    print(f"Accuracy: {accuracy:.2%}")
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred, 
                              target_names=['Negative', 'Positive']))
    
    # Save the model
    model_path = 'sentiment_model.joblib'
    joblib.dump(model, model_path)
    print(f"Model saved to: {model_path}")
    
    # Test with some examples
    print("\nTesting with sample predictions:")
    test_texts = [
        "This product is fantastic!",
        "I hate this service",
        "Average quality, nothing special"
    ]
    
    predictions = model.predict(test_texts)
    probabilities = model.predict_proba(test_texts)
    
    for text, pred, prob in zip(test_texts, predictions, probabilities):
        sentiment = "Positive" if pred == 1 else "Negative"
        confidence = prob[pred]
        print(f"   '{text}' → {sentiment} (confidence: {confidence:.2%})")
    
    return model

if __name__ == "__main__":
    train_sentiment_model()
