# GenAI User Analytics: Adoption & Engagement

This document outlines 10 key analytics queries designed to measure **User Adoption**, **Growth**, and **Engagement** for Gemini Enterprise Chat.

**Table**: \`bnoriega-test-ge.ConversationLogs.gemini_chat\`

## 1. Daily Active Users (DAU) - **Adoption**
The primary measure of daily usage. Tracks unique authenticated users interacting with the system.

```sql
SELECT
  DATE(timestamp) as date,
  COUNT(DISTINCT userIamPrincipal) as daily_active_users
FROM \`bnoriega-test-ge.ConversationLogs.gemini_chat\`
GROUP BY 1
ORDER BY 1 DESC;
```

## 2. New User Acquisition - **Growth**
Tracks new users joining the platform by identifying their first interaction date.
*(Requires historical data for accuracy)*

```sql
WITH FirstSeen AS (
  SELECT
    userIamPrincipal,
    MIN(DATE(timestamp)) as first_seen_date
  FROM \`bnoriega-test-ge.ConversationLogs.gemini_chat\`
  GROUP BY 1
)
SELECT
  first_seen_date,
  COUNT(distinct userIamPrincipal) as new_users
FROM FirstSeen
GROUP BY 1
ORDER BY 1 DESC;
```

## 3. Stickiness (DAU/MAU Ratio) - **Engagement**
Measures how often users return. A higher ratio (closer to 100%) indicates habitual daily use.
*(Note: Requires at least 30 days of data for true MAU)*

```sql
WITH DailyStats AS (
  SELECT
    DATE(timestamp) as date,
    COUNT(DISTINCT userIamPrincipal) as dau
  FROM \`bnoriega-test-ge.ConversationLogs.gemini_chat\`
  GROUP BY 1
),
MonthlyStats AS (
  SELECT
    DATE(timestamp) as date,
    COUNT(DISTINCT userIamPrincipal) as mau_rolling_30d -- Simplified for demo
  FROM \`bnoriega-test-ge.ConversationLogs.gemini_chat\`
  GROUP BY 1
)
SELECT
  d.date,
  d.dau,
  m.mau_rolling_30d,
  SAFE_DIVIDE(d.dau, m.mau_rolling_30d) * 100 as stickiness_percent
FROM DailyStats d
JOIN MonthlyStats m ON d.date = m.date
ORDER BY 1 DESC;
```

## 4. Average Sessions per User - **Intensity**
How many times a day does an active user utilize the chat?

```sql
WITH UserSessions AS (
  SELECT
    DATE(timestamp) as date,
    userIamPrincipal,
    COUNT(DISTINCT REGEXP_EXTRACT(JSON_VALUE(response, '$.answer.name'), 'sessions/([^/]+)')) as session_count
  FROM \`bnoriega-test-ge.ConversationLogs.gemini_chat\`
  WHERE methodName = 'StreamAssist'
  AND JSON_VALUE(response, '$.answer.name') IS NOT NULL
  GROUP BY 1, 2
)
SELECT
  date,
  AVG(session_count) as avg_sessions_per_user
FROM UserSessions
GROUP BY 1
ORDER BY 1 DESC;
```

## 5. Average Queries per Session - **Depth**
Measures the depth of conversations. Higher usage suggests complex problem solving (or potentially confusion if too high).

```sql
WITH SessionDepths AS (
  SELECT
    REGEXP_EXTRACT(JSON_VALUE(response, '$.answer.name'), 'sessions/([^/]+)') as session_id,
    COUNT(*) as queries
  FROM \`bnoriega-test-ge.ConversationLogs.gemini_chat\`
  WHERE methodName = 'StreamAssist'
  AND JSON_VALUE(response, '$.answer.name') IS NOT NULL
  GROUP BY 1
)
SELECT
  AVG(queries) as avg_queries_per_session,
  APPROX_QUANTILES(queries, 100)[OFFSET(50)] as median_queries
FROM SessionDepths;
```

## 6. Power Users (Top 10) - **Champions**
Identifies the most engaged users by query volume. Useful for finding champions or gathering power-user feedback.

```sql
SELECT
  userIamPrincipal,
  COUNT(*) as total_queries,
  COUNT(DISTINCT DATE(timestamp)) as active_days
FROM \`bnoriega-test-ge.ConversationLogs.gemini_chat\`
WHERE methodName = 'StreamAssist'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;
```

## 7. Weekly User Retention - **Retention**
Percentage of users from last week who returned this week.

```sql
WITH WeeklyUsers AS (
  SELECT DISTINCT
    userIamPrincipal,
    DATE_TRUNC(DATE(timestamp), WEEK) as week_start
  FROM \`bnoriega-test-ge.ConversationLogs.gemini_chat\`
)
SELECT
  CurrentWeek.week_start,
  COUNT(DISTINCT CurrentWeek.userIamPrincipal) as active_users,
  COUNT(DISTINCT PreviousWeek.userIamPrincipal) as retained_users,
  SAFE_DIVIDE(COUNT(DISTINCT PreviousWeek.userIamPrincipal), COUNT(DISTINCT CurrentWeek.userIamPrincipal)) * 100 as retention_rate
FROM WeeklyUsers CurrentWeek
LEFT JOIN WeeklyUsers PreviousWeek
  ON CurrentWeek.userIamPrincipal = PreviousWeek.userIamPrincipal
  AND PreviousWeek.week_start = DATE_SUB(CurrentWeek.week_start, INTERVAL 1 WEEK)
GROUP BY 1
ORDER BY 1 DESC;
```

## 8. Session Duration Analysis - **Engagement Time**
Estimates how long users spend in a session (Time from first to last query).

```sql
WITH SessionTimes AS (
  SELECT
    REGEXP_EXTRACT(JSON_VALUE(response, '$.answer.name'), 'sessions/([^/]+)') as session_id,
    MIN(timestamp) as session_start,
    MAX(timestamp) as session_end
  FROM \`bnoriega-test-ge.ConversationLogs.gemini_chat\`
  WHERE methodName = 'StreamAssist'
  AND JSON_VALUE(response, '$.answer.name') IS NOT NULL
  GROUP BY 1
)
SELECT
  AVG(TIMESTAMP_DIFF(session_end, session_start, SECOND) / 60) as avg_session_duration_minutes
FROM SessionTimes
WHERE session_start < session_end; -- Filter single-query sessions if desired
```

## 9. Feedback Participation Rate - **Engagement**
How often do users care enough to leave feedback (positive or negative)?

```sql
SELECT
  DATE(timestamp) as date,
  COUNTIF(JSON_VALUE(request, '$.userEvent.eventType') = 'add-feedback') as feedback_events,
  COUNTIF(methodName = 'StreamAssist') as total_queries,
  SAFE_DIVIDE(COUNTIF(JSON_VALUE(request, '$.userEvent.eventType') = 'add-feedback'), COUNTIF(methodName = 'StreamAssist')) * 100 as feedback_rate_percent
FROM \`bnoriega-test-ge.ConversationLogs.gemini_chat\`
GROUP BY 1
ORDER BY 1 DESC;
```

## 10. Deep Engagement Sessions (>5 Queries) - **Value**
Tracks the percentage of "deep" sessions, which often indicate high-value complex work.

```sql
WITH SessionCounts AS (
  SELECT
    REGEXP_EXTRACT(JSON_VALUE(response, '$.answer.name'), 'sessions/([^/]+)') as session_id,
    COUNT(*) as query_count
  FROM \`bnoriega-test-ge.ConversationLogs.gemini_chat\`
  WHERE methodName = 'StreamAssist'
  AND JSON_VALUE(response, '$.answer.name') IS NOT NULL
  GROUP BY 1
)
SELECT
  COUNTIF(query_count > 5) as deep_sessions,
  COUNT(*) as total_sessions,
  SAFE_DIVIDE(COUNTIF(query_count > 5), COUNT(*)) * 100 as deep_session_rate_percent
FROM SessionCounts;
```
