# Python Backend Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Fix dpkg state if corrupted and install system dependencies
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Upgrade pip, setuptools, wheel first to avoid segfault issues
# Use setuptools <70 to fix langdetect build issues
RUN pip install --upgrade pip wheel && \
    pip install "setuptools<70"

# Install requirements (langdetect may fail, but code has fallback)
# Create filtered requirements file without langdetect if initial install fails
RUN pip install --no-cache-dir -r requirements.txt || \
    (echo "Warning: Some packages failed (likely langdetect), continuing without them..." && \
     grep -v "langdetect" requirements.txt | grep -v "^#" | grep -v "^$" | sed '/^$/d' > /tmp/requirements_filtered.txt && \
     pip install --no-cache-dir -r /tmp/requirements_filtered.txt && \
     echo "langdetect installation skipped - using spacy fallback")

# Copy application code
COPY src/ ./src/
COPY scripts/ ./scripts/

# Create logs directory
RUN mkdir -p logs

# Expose port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

