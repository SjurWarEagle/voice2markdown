FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y curl jq && rm -rf /var/lib/apt/lists/*

RUN pip install openai-whisper

RUN useradd -m -u 1000 user

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER user

ENTRYPOINT ["/entrypoint.sh"]