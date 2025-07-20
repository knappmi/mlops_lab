"""
Test script for the sentiment analysis API
"""
import requests
import json

def test_api():
    """Test the sentiment analysis API"""
    base_url = "http://localhost:8000"
    
    print("Testing Sentiment Analysis API")
    print("=" * 40)
    
    # Test health check
    try:
        response = requests.get(f"{base_url}/healthz")
        if response.status_code == 200:
            print("Health check: PASSED")
        else:
            print("Health check: FAILED")
            return
    except Exception as e:
        print(f"Health check failed: {e}")
        return
    
    # Test single prediction
    test_texts = [
        "I absolutely love this product! It's amazing!",
        "This is terrible, worst purchase ever.",
        "It's okay, nothing special but not bad either.",
        "Outstanding quality and excellent service!",
        "Completely disappointed with this purchase."
    ]
    
    print("\nTesting single predictions:")
    print("-" * 30)
    
    for text in test_texts:
        try:
            response = requests.post(
                f"{base_url}/predict",
                json={"text": text}
            )
            
            if response.status_code == 200:
                result = response.json()
                sentiment = result['sentiment']
                confidence = result['confidence']
                print(f"'{text[:40]}...' → {sentiment.upper()} ({confidence:.1%})")
            else:
                print(f"Failed to predict for: {text[:40]}...")
                
        except Exception as e:
            print(f"Error: {e}")
    
    # Test batch prediction
    print("\nTesting batch prediction:")
    print("-" * 30)
    
    try:
        response = requests.post(
            f"{base_url}/predict/batch",
            json={"texts": test_texts[:3]}
        )
        
        if response.status_code == 200:
            results = response.json()['predictions']
            print("Batch prediction successful:")
            for result in results:
                text = result['text']
                sentiment = result['sentiment']
                confidence = result['confidence']
                print(f"   '{text[:30]}...' → {sentiment.upper()} ({confidence:.1%})")
        else:
            print("Batch prediction failed")
            
    except Exception as e:
        print(f"Batch prediction error: {e}")
    
    # Test model info
    print("\nTesting model info:")
    print("-" * 30)
    
    try:
        response = requests.get(f"{base_url}/model/info")
        if response.status_code == 200:
            info = response.json()
            print("Model info retrieved:")
            for key, value in info.items():
                print(f"   {key}: {value}")
        else:
            print("Failed to get model info")
            
    except Exception as e:
        print(f"Model info error: {e}")
    
    print("\nAPI testing completed!")

if __name__ == "__main__":
    test_api()
