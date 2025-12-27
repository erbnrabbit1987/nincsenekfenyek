# Python Backend Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Set environment variables to reduce memory usage
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

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
# Limit pip memory usage
RUN pip install --upgrade pip wheel setuptools && \
    pip install "setuptools<70" && \
    python -c "import sys; print(f'Python version: {sys.version}')"

# Install core dependencies first (small, essential packages)
# Install one by one to minimize memory usage and avoid segfault
RUN pip install --no-cache-dir fastapi==0.104.1 && \
    pip install --no-cache-dir "uvicorn[standard]==0.24.0" && \
    pip install --no-cache-dir python-dotenv==1.0.0 && \
    pip install --no-cache-dir pydantic==2.5.2 && \
    pip install --no-cache-dir pydantic-settings==2.1.0

# Install database dependencies (one by one to reduce memory)
RUN pip install --no-cache-dir pymongo==4.6.0 && \
    pip install --no-cache-dir motor==3.3.2 && \
    pip install --no-cache-dir sqlalchemy==2.0.23 && \
    pip install --no-cache-dir alembic==1.12.1 && \
    pip install --no-cache-dir psycopg2-binary==2.9.9 && \
    pip install --no-cache-dir mongoengine==0.27.0

# Install cache & queue
RUN pip install --no-cache-dir \
    redis==5.0.1 \
    celery==5.3.4

# Install HTTP clients (small packages)
RUN pip install --no-cache-dir \
    requests==2.31.0 \
    httpx==0.25.2

# Install auth & security
RUN pip install --no-cache-dir \
    python-jose[cryptography]==3.3.0 \
    passlib[bcrypt]==1.7.4 \
    python-multipart==0.0.6

# Install web scraping (one by one, can be heavy - skip if segfault)
RUN pip install --no-cache-dir beautifulsoup4==4.12.2 || echo "Warning: beautifulsoup4 failed" && \
    pip install --no-cache-dir lxml==4.9.3 || echo "Warning: lxml failed" && \
    pip install --no-cache-dir selenium==4.15.2 || echo "Warning: selenium failed" && \
    pip install --no-cache-dir scrapy==2.11.0 || echo "Warning: scrapy failed"

# Install NLP (skip langdetect and heavy transformers dependencies)
RUN pip install --no-cache-dir \
    spacy==3.7.2 \
    nltk==3.8.1 \
    transformers==4.35.2 \
    sentencepiece==0.1.99 || echo "Warning: Some NLP packages failed"

# Skip langdetect (known build issues) - code has fallback
# Install other packages
RUN pip install --no-cache-dir \
    APScheduler==3.10.4 \
    python-json-logger==2.0.7 \
    python-dateutil==2.8.2

# Install testing (optional, can skip if build fails)
RUN pip install --no-cache-dir \
    pytest==7.4.3 \
    pytest-asyncio==0.21.1 \
    pytest-cov==4.1.0 \
    faker==20.1.0 || echo "Warning: Testing packages failed"

# Install code quality tools (optional)
RUN pip install --no-cache-dir \
    black==23.11.0 \
    flake8==6.1.0 \
    mypy==1.7.1 \
    isort==5.12.0 || echo "Warning: Code quality packages failed"

# Copy application code
COPY src/ ./src/
COPY scripts/ ./scripts/

# Create logs directory
RUN mkdir -p logs

# Expose port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

