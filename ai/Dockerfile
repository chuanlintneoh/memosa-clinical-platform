# Use official Python image
FROM python:3.10-slim

# Set working directory
WORKDIR /ai

# Install system dependencies
RUN apt-get update && apt-get install -y gcc && apt-get clean

# Copy files from ai folder (monorepo)
COPY app/ ./app
COPY requirements.txt .

# Install dependencies
RUN pip install --upgrade pip && pip install -r requirements.txt

# Expose port
EXPOSE 8080

# Run the FastAPI app
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}"]