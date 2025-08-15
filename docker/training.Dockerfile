FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src/training ./src/training
COPY src/api/models ./src/api/models

# Create necessary directories
RUN mkdir -p /app/src/api/models
RUN mkdir -p /app/src/training/data

# Copy training data
COPY src/training/data/iris.csv /app/src/training/data/

# Set environment variables
ENV PYTHONPATH=/app

# Set working directory for training
WORKDIR /app/src/training

# Default command
CMD ["python", "pipelines/iris_pipeline.py"]