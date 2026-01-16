# Prompt Classification Pipeline

This directory contains the SQL scripts to classify Gemini Enterprise Chat prompts using BigQuery ML (BQML).

## Prerequisites

1.  **GCP Project**: Ensure you have a GCP project with BigQuery enabled.
2.  **Permissions**:
    *   `bigquery.jobs.create`
    *   `bigquery.models.create`
    *   `bigquery.tables.updateData`
    *   `bigquery.connections.delegate` (for remote models)
3.  **Cloud Resource Connection**: You need a Cloud Resource Connection (e.g., `us.vertex_embeddings_conn`) to access the Vertex AI Embedding API from BigQuery.

## Pipeline Steps

### 1. Train Models
Run `01_train_models.sql` to create the embedding model and the K-Means clustering model.
*   **Note**: You may need to update the `CONNECTION` string in the script to match your environment.

### 2. Process & Save
Run `02_process_and_save.sql` to:
*   Create the `classification` table.
*   Generate embeddings for your prompts.
*   Predict clusters and save the results.

### 3. Analyze
Run `03_analytics.sql` to get insights:
*   **Cluster Interpretation**: See what each cluster represents.
*   **Outlier Detection**: Find new or anomalous prompts.
*   **Engagement**: See which topics are trending.

## Automation

You can run the full pipeline (Training -> Processing -> Analytics) using the automated script:

```bash
./test_classification.sh
```

This script executes the SQL files in the correct order, splitting `03_analytics.sql` into individual queries for easier debugging.

