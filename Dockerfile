FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir flask gunicorn prometheus_client
COPY demo.py app.py

EXPOSE 8080
ENV GUNICORN_WORKERS=1
ENV GUNICORN_TIMEOUT=30
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
