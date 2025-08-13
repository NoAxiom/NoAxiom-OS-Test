#!/bin/bash

GZFILE="$1"
OUTFILE="$2"

if [ -z "$GZFILE" ] || [ -z "$OUTFILE" ]; then
    echo "Usage: $0 <input.gz> <output_file>"
    exit 1
fi

if [ ! -f "$GZFILE" ]; then
    echo -e "\033[31mError: Input file '$GZFILE' not found\033[0m"
    exit 1
fi

# Get compressed file size for progress estimation
COMPRESSED_SIZE=$(stat -c%s "$GZFILE" 2>/dev/null || stat -f%z "$GZFILE" 2>/dev/null)

if [ -z "$COMPRESSED_SIZE" ] || [ "$COMPRESSED_SIZE" -eq 0 ]; then
    echo -e "\033[31mError: Could not determine file size\033[0m"
    exit 1
fi

echo -e "\033[32mCompressed size: $(numfmt --to=iec $COMPRESSED_SIZE)\033[0m"
echo -e "\033[33mExtracting (progress based on compressed data read)...\033[0m"

# Clean up previous output
rm -f "$OUTFILE"

# Use a simpler approach with dd and progress monitoring
BYTES_READ=0
BLOCK_SIZE=1048576  # 1MB
START_TIME=$(date +%s)

# Create monitoring process
{
    while kill -0 $$ 2>/dev/null; do
        if [ -f "$OUTFILE" ]; then
            CURRENT_SIZE=$(stat -c%s "$OUTFILE" 2>/dev/null || echo 0)
            CURRENT_TIME=$(date +%s)
            ELAPSED=$((CURRENT_TIME - START_TIME))
            
            if [ $ELAPSED -gt 0 ]; then
                SPEED=$((CURRENT_SIZE / ELAPSED))
                SPEED_STR="$(numfmt --to=iec $SPEED)/s"
            else
                SPEED_STR="calculating..."
            fi
            
            printf "\r\033[32mExtracting: \033[33m%s\033[0m extracted, \033[35m%s\033[0m" \
                   "$(numfmt --to=iec $CURRENT_SIZE)" "$SPEED_STR"
        fi
        sleep 1
    done
} &
MONITOR_PID=$!

# Trap to clean up
trap 'kill $MONITOR_PID 2>/dev/null; exit' INT TERM EXIT

# Do the actual extraction
gunzip -c "$GZFILE" > "$OUTFILE"
EXTRACT_STATUS=$?

# Stop monitoring
kill $MONITOR_PID 2>/dev/null
wait $MONITOR_PID 2>/dev/null

if [ $EXTRACT_STATUS -eq 0 ]; then
    FINAL_SIZE=$(stat -c%s "$OUTFILE" 2>/dev/null || stat -f%z "$OUTFILE" 2>/dev/null)
    echo -e "\n\033[32mExtraction complete!\033[0m"
    echo -e "\033[32mFinal size: $(numfmt --to=iec $FINAL_SIZE)\033[0m"
else
    echo -e "\n\033[31mExtraction failed!\033[0m"
    exit 1
fi