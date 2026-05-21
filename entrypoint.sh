#!/bin/bash

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

OUTPUT_DIR="$(dirname "$AUDIO_FILE")"
BASE_NAME="$(basename "${AUDIO_FILE%.*}")"
TRANSCRIPTION="$OUTPUT_DIR/$BASE_NAME.txt"

whisper "$AUDIO_FILE" --model large-v3 --output_format txt --output_dir "$OUTPUT_DIR"

PROMPT=$(cat "$PROMPT_FILE")

CONTENT=$(cat "$TRANSCRIPTION")

PAYLOAD=$(jq -n --arg prompt "$PROMPT" --arg content "$CONTENT" '{
  model: "phi3:3.8b",
  stream: false,
  prompt: $prompt + "\n\nText to process:\n" + $content
}')

RESPONSE=$(curl -s -X POST http://host.docker.internal:11434/api/generate -H "Content-Type: application/json" -d "$PAYLOAD")

echo "$RESPONSE" | jq -r '.response' > "$OUTPUT_DIR/$BASE_NAME.md"

rm "$TRANSCRIPTION"

echo "Transcription complete: $OUTPUT_DIR/$BASE_NAME.md"