FROM python:3.9-slim

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src/ ./src/
COPY model_registry.json ./

# TODO: Add conditional model training based on MODEL_VERSION
# Set environment variables
ENV PYTHONPATH=/app
ENV MODEL_VERSION=v1

# Train models (both versions for flexibility)
RUN python3 src/training/train.py 1
RUN python3 src/training/train.py 2

# Expose port
EXPOSE 8000

# TODO: Add startup script that selects model version
CMD ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000"]