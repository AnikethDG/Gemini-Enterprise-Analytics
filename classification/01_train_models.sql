/*
    Step 1: Train/Create Models
    
    1.  Create a remote model to generate embeddings via Vertex AI.
    2.  Create a Generative Model to name the clusters.
    3.  Create a K-Means model to cluster the prompts.
    
    REPLACE `us.vertex_embeddings_conn` with your actual connection ID if different.
*/

-- 1. Create the Embedding Model (Remote)
-- This connects to Vertex AI's text-embedding-004 model.
CREATE OR REPLACE MODEL `bnoriega-test-ge.ConversationLogs.embedding_model`
REMOTE WITH CONNECTION `us.vertex_embeddings_conn`
OPTIONS (ENDPOINT = 'text-embedding-004');

-- 2. Create the Generative Model (for Naming Clusters)
-- This uses Gemini 2.5 pro/flash to generate human-readable labels for our clusters.
CREATE OR REPLACE MODEL `bnoriega-test-ge.ConversationLogs.generative_model`
REMOTE WITH CONNECTION `us.vertex_embeddings_conn`
OPTIONS (ENDPOINT = 'gemini-2.5-pro');

-- 3. Create the K-Means Clustering Model
-- We train this on a sample of unique prompts to define our "Classes".
CREATE OR REPLACE MODEL `bnoriega-test-ge.ConversationLogs.kmeans_model`
OPTIONS (
  model_type = 'kmeans',
  num_clusters = 5,
  standardize_features = TRUE
) AS
SELECT
  ml_generate_embedding_result AS embedding
FROM
  ML.GENERATE_EMBEDDING(
    MODEL `bnoriega-test-ge.ConversationLogs.embedding_model`,
    (
      SELECT DISTINCT JSON_VALUE(request, '$.query.parts[0].text') AS content
      FROM `bnoriega-test-ge.ConversationLogs.gemini_chat`
      WHERE methodName = 'StreamAssist'
      AND JSON_VALUE(request, '$.query.parts[0].text') IS NOT NULL
      LIMIT 10000 -- Train on a subset for speed
    )
  );
