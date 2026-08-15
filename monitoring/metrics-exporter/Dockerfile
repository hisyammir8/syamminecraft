FROM python:3.13-alpine

WORKDIR /app

COPY exporter.py /app/exporter.py

RUN chmod +x /app/exporter.py

EXPOSE 9100

CMD ["python", "/app/exporter.py"]
