FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y curl jq ffmpeg zstd && rm -rf /var/lib/apt/lists/*

RUN pip install openai-whisper

RUN curl -fsSL https://ollama.com/install.sh | sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]