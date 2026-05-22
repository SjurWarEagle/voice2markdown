#!/bin/bash
mkdir -p ./cache ./whisper_cache
docker build -t whisper-large-v3 .
docker run --rm \
  -v ./data:/data \
  -v ./cache:/root/.ollama \
  -v ./whisper_cache:/root/.cache/whisper \
  -v ./prompt.txt:/app/prompt.txt:ro \
  --name whisper whisper-large-v3 /app/prompt.txt /data/FlorianTest.m4a