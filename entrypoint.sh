#!/bin/bash

export WHISPER_CACHE="/root/.cache/whisper"

if [ $# -ne 2 ]; then
    echo "Usage: transcribe <prompt_file> <audio_file>"
    exit 1
fi

PROMPT_FILE="$1"
AUDIO_FILE="$2"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Prompt file not found: $PROMPT_FILE"
    exit 1
fi

if [ ! -f "$AUDIO_FILE" ]; then
    echo "Audio file not found: $AUDIO_FILE"
    exit 1
fi

echo "Starting Ollama server..."
ollama serve &
OLLAMA_PID=$!

echo "Waiting for Ollama to be ready..."
for i in {1..30}; do
    if curl -s http://127.0.0.1:11434/api/tags > /dev/null 2>&1; then
        echo "Ollama is ready."
        break
    fi
    sleep 1
done

echo "Checking for phi3:3.8b model..."
if ! ollama list | grep -q "^phi3.*3.8b"; then
    echo "Pulling phi3:3.8b model..."
    ollama pull phi3:3.8b
fi

BASE_NAME="$(basename "${AUDIO_FILE%.*}")"
WORK_DIR="/tmp/whisper_work"
mkdir -p "$WORK_DIR"

echo "Transcribing audio..."
python -m whisper "$AUDIO_FILE" --model large-v3 --output_format txt --output_dir "$WORK_DIR"

TRANSCRIPTION="$WORK_DIR/$BASE_NAME.txt"

PROMPT=$(cat "$PROMPT_FILE")
CONTENT=$(cat "$TRANSCRIPTION")

echo "Processing transcription with LLM..."

TEMP_PAYLOAD=$(mktemp)
cat > "$TEMP_PAYLOAD" << EOF
{
  "model": "phi3:3.8b",
  "stream": false,
  "prompt": "${PROMPT}\n\nText to process:\n${CONTENT}"
}
EOF

RESPONSE=$(curl -s -X POST http://127.0.0.1:11434/api/generate -H "Content-Type: application/json" -d @"$TEMP_PAYLOAD")
rm "$TEMP_PAYLOAD"

echo "$RESPONSE" | jq -r '.response' > "$WORK_DIR/$BASE_NAME.md"

cp "$WORK_DIR/$BASE_NAME.md" "$(dirname "$AUDIO_FILE")/$BASE_NAME.md"

rm -rf "$WORK_DIR"

kill $OLLAMA_PID 2>/dev/null

echo "Transcription complete: $(dirname "$AUDIO_FILE")/$BASE_NAME.md"