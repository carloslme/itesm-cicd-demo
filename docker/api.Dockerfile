FROM python:3.9-slim

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y gcc && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy all source code
COPY . .

# Create models directory
RUN mkdir -p src/api/models

# Set environment
ENV PYTHONPATH=/app
ENV MODEL_VERSION=${MODEL_VERSION:-v1}

EXPOSE 8000

# Fix: Convert v1/v2 to 1/2 for training script
CMD if [ "$MODEL_VERSION" = "v1" ]; then \
        python3 src/training/train.py 1; \
    else \
        python3 src/training/train.py 2; \
    fi && \
    uvicorn src.api.main:app --host 0.0.0.0 --port 8000