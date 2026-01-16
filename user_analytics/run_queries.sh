#!/bin/bash

# Configuration
PROJECT_ID="bnoriega-test-ge"
SOURCE_FILE="genai_user_metrics.sql"

echo "Using Project ID: $PROJECT_ID to execute queries..."

# Find all lines starting with "-- <number>."
# We use grep to find line numbers of the start of each query block
grep -nE "^-- [0-9]+\." "$SOURCE_FILE" | while read -r match; do
    start_line=$(echo "$match" | cut -d: -f1)
    # Extract the query number (e.g. "-- 1." -> "1")
    title=$(echo "$match" | cut -d: -f2-)
    query_num=$(echo "$title" | awk '{print $2}' | sed 's/\.//')
    
    # Clean title for display
    display_title=$(echo "$title" | sed 's/^-- [0-9]*\. //')

    # Determine the end line for this block
    # We look for the next line starting with "-- <number>."
    next_start=$(grep -nE "^-- [0-9]+\." "$SOURCE_FILE" | awk -v s="$start_line" -F: '$1 > s {print $1}' | head -1)
    
    if [ -z "$next_start" ]; then
        # If no next start, go to the end of the file
        end_line=$(wc -l < "$SOURCE_FILE")
        # Adjust if wc -l counts the last newline or not, usually safe to just use the number
        # Actually sed handles up to $
        end_line="$"
    else
        end_line=$((next_start - 1))
    fi

    echo "======================================================="
    echo "Running Query $query_num: $display_title"
    # echo "Lines: $start_line to $end_line"
    
    # Extract the query to a temp file
    if [ "$end_line" == "$" ]; then
         sed -n "${start_line},\$p" "$SOURCE_FILE" > "temp_query_${query_num}.sql"
    else
         sed -n "${start_line},${end_line}p" "$SOURCE_FILE" > "temp_query_${query_num}.sql"
    fi

    # Execute with bq
    # We use --dry_run first? No, user wants to test if they work.
    # We limit output to avoid huge dumps from SELECT * (though these are mostly aggs)
    bq query --project_id="$PROJECT_ID" --use_legacy_sql=false --format=pretty < "temp_query_${query_num}.sql"
    
    RET_CODE=$?
    if [ $RET_CODE -eq 0 ]; then
        echo "✅ Query $query_num SUCCESS"
    else
        echo "❌ Query $query_num FAILED (Exit Code: $RET_CODE)"
    fi
    
    # Cleanup
    rm "temp_query_${query_num}.sql"
    echo ""
done
