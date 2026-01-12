/*
    Step 2: Process and Save Results
    
    1.  Create the destination table `classification`.
    2.  Generate embeddings for ALL prompts.
    3.  Predict clusters.
    4.  Insert into the table.
*/

-- 1. Create the classification table
CREATE TABLE IF NOT EXISTS `bnoriega-test-ge.ConversationLogs.classification` (
  timestamp TIMESTAMP,
  user_iam_principal STRING,
  prompt STRING,
  cluster_id INT64,
  nearest_centroid_distance FLOAT64,
  embedding ARRAY<FLOAT64>
);

-- 2. Insert Processed Data
-- We use ML.PREDICT with the K-Means model, which expects the 'embedding' column.
-- We generate that 'embedding' column on the fly using ML.GENERATE_EMBEDDING.

INSERT INTO `bnoriega-test-ge.ConversationLogs.classification` (timestamp, user_iam_principal, prompt, cluster_id, nearest_centroid_distance, embedding)
WITH SourceData AS (
  SELECT
    timestamp,
    userIamPrincipal,
    JSON_VALUE(request, '$.query.parts[0].text') AS content
  FROM
    `bnoriega-test-ge.ConversationLogs.gemini_chat`
  WHERE
    methodName = 'StreamAssist'
    AND JSON_VALUE(request, '$.query.parts[0].text') IS NOT NULL
),
EmbeddedData AS (
  SELECT
    *
  FROM
    ML.GENERATE_EMBEDDING(
      MODEL `bnoriega-test-ge.ConversationLogs.embedding_model`,
      (SELECT content, timestamp, userIamPrincipal FROM SourceData)
    )
)
SELECT
  timestamp,
  userIamPrincipal AS user_iam_principal,
  content AS prompt,
  CENTROID_ID AS cluster_id,
  NEAREST_CENTROIDS_DISTANCE[OFFSET(0)].distance AS nearest_centroid_distance,
  embedding
FROM
  ML.PREDICT(
    MODEL `bnoriega-test-ge.ConversationLogs.kmeans_model`,
    (SELECT ml_generate_embedding_result AS embedding, content, timestamp, userIamPrincipal FROM EmbeddedData)
  );
