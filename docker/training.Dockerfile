FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src/ ./src/

# Create models directory
RUN mkdir -p src/api/models

# Set environment variables
ENV PYTHONPATH=/app
ENV MODEL_VERSION=${MODEL_VERSION:-v1}

# Expose port
EXPOSE 8000

# Copy startup script
COPY docker/start.sh .
RUN chmod +x start.sh

# Run the startup script
CMD ["./start.sh"]