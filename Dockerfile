FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first (for better Docker layer caching)
COPY app/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ .

# Copy the trained model from root to models directory
COPY sentiment_model.joblib /app/models/

# Copy the models directory (training scripts)
COPY models/ /app/models/

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/healthz || exit 1

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
