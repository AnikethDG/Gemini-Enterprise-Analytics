SELECT
  
  -- 1. Extract the unique Session ID from the response (Format: projects/.../sessions/{ID}/...)
  REGEXP_EXTRACT(JSON_EXTRACT_SCALAR(response, '$.answer.name'), r'sessions/([^/]+)') AS session_id,
  userIamPrincipal,
  -- 2. Metadata for context
  timestamp,
  methodName,
  
  -- 3. The actual conversation content (User request and System reply)
  userQuery,
  serviceTextReply

FROM
  `bnoriega-test-ge.ConversationLogs.gemini_chat`

WHERE
  -- "StreamAssist" are the actual chat interactions
  methodName = 'StreamAssist' 
  -- Ensure we only include rows with a valid response/session
  AND JSON_EXTRACT_SCALAR(response, '$.answer.name') IS NOT NULL
  AND userIamPrincipal = 'anikethd@bnoriega.altostrat.com'
  
ORDER BY
  session_id,
  timestamp desc
