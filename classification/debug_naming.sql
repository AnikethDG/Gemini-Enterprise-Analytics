
WITH ClusterSamples AS (
  SELECT
    cluster_id,
    ARRAY_AGG(prompt ORDER BY nearest_centroid_distance ASC LIMIT 10) AS samples,
    COUNT(*) AS prompt_count
  FROM
    `bnoriega-test-ge.ConversationLogs.classification`
  GROUP BY
    cluster_id
)
SELECT
  cluster_id,
  TRIM(JSON_VALUE(ml_generate_text_result, '$.candidates[0].content.parts[0].text')) AS cluster_name,
  TO_JSON_STRING(ml_generate_text_result) AS raw_response,
  samples AS representative_prompts,
  prompt_count
FROM
  ML.GENERATE_TEXT(
    MODEL `bnoriega-test-ge.ConversationLogs.generative_model`,
    (
      SELECT
        cluster_id,
        prompt_count,
        samples,
        CONCAT(
          'You are a data analyst. Analyze these user prompts to determine the common theme or topic. ',
          'Output ONLY a concise 2-5 word label for this cluster (e.g., "Creative Writing", "Code Debugging"). ',
          'Do not use any special characters or markup.\n\nPrompts:\n- ',
          ARRAY_TO_STRING(samples, '\n- ')
        ) AS prompt
      FROM
        ClusterSamples
    ),
    STRUCT(
      0.0 AS temperature,
      500 AS max_output_tokens
    )
  )
ORDER BY
  prompt_count DESC;
