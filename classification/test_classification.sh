#!/bin/bash

# Configuration
PROJECT_ID="bnoriega-test-ge"
DIR="/usr/local/google/home/anikethd/gemini/Gemini-Enterprise-Analytics/classification"

echo "Using Project ID: $PROJECT_ID"
cd "$DIR" || exit

# Function to run a full file
run_file() {
    local file=$1
    echo "----------------------------------------------------------------"
    echo "Running Full Script: $file"
    # Read the file content
    query=$(cat "$file")
    
    # Run with bq
    bq query --project_id="$PROJECT_ID" --use_legacy_sql=false --format=pretty "$query"
    
    if [ $? -eq 0 ]; then
        echo "✅ $file SUCCESS"
    else
        echo "❌ $file FAILED"
    fi
    echo ""
}

# Function to parse and run sections (for 03)
run_sections() {
    local file=$1
    echo "----------------------------------------------------------------"
    echo "Running Sections in: $file"
    
    # Find lines starting with "-- <Letter>." (e.g. "-- A.")
    grep -nE "^-- [A-Z]\." "$file" | while read -r match; do
        start_line=$(echo "$match" | cut -d: -f1)
        title=$(echo "$match" | cut -d: -f2-)
        section_id=$(echo "$title" | awk '{print $2}' | sed 's/\.//')
        display_title=$(echo "$title" | sed 's/^-- [A-Z]*\. //')

        # Find next section start
        next_start=$(grep -nE "^-- [A-Z]\." "$file" | awk -v s="$start_line" -F: '$1 > s {print $1}' | head -1)
        
        if [ -z "$next_start" ]; then
            end_line="$"
        else
            end_line=$((next_start - 1))
        fi

        echo ">>> Running Query $section_id: $display_title"
        
        # Extract query
        if [ "$end_line" == "$" ]; then
            sed -n "${start_line},\$p" "$file" > "temp_c_${section_id}.sql"
        else
            sed -n "${start_line},${end_line}p" "$file" > "temp_c_${section_id}.sql"
        fi
        
        # Run
        bq query --project_id="$PROJECT_ID" --use_legacy_sql=false --format=pretty < "temp_c_${section_id}.sql"
        
        if [ $? -eq 0 ]; then
            echo "✅ Query $section_id SUCCESS"
        else
            echo "❌ Query $section_id FAILED"
        fi
        rm "temp_c_${section_id}.sql"
        echo ""
    done
}

# 1. Train Models
# This might take a while or fail if permissions are missing.
run_file "01_train_models.sql"

# 2. Process Data
# This inserts data.
run_file "02_process_and_save.sql"

# 3. Analytics
# Run section by section
run_sections "03_analytics.sql"
