FROM python:3.12-slim

WORKDIR /app

# Copy requirements first for better layer caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY main.py .

# Set non-root user for better security
RUN adduser --disabled-password --gecos "" appuser
USER appuser

# Expose port
EXPOSE 8000

# Set environment variables with safe default values
ENV DB_PASSWORD=placeholder
ENV API_BASE_URL=http://localhost:8000
ENV LOG_LEVEL=info
ENV MAX_CONNECTIONS=10
ENV ENVIRONMENT=development

# Command to run the application with uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
