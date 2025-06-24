FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY drone_cleaner.py .

CMD ["python", "drone_cleaner.py"]
