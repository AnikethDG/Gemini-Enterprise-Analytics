# GenAI User Analytics

This directory contains SQL scripts for analyzing user adoption, growth, and engagement metrics.

## Files

- **[genai_user_metrics.sql](genai_user_metrics.sql)**: Contains 10 key analytics queries:
  1.  Daily Active Users (DAU)
  2.  New User Acquisition
  3.  Stickiness (DAU/MAU)
  4.  Average Sessions per User
  5.  Average Queries per Session
  6.  Power Users (Top 10)
  7.  Weekly User Retention
  8.  Session Duration Analysis
  9.  Feedback Participation Rate
  10. Deep Engagement Sessions

## Automation

You can run all queries automatically using the provided shell script:

```bash
./run_queries.sh
```

This script will:
1.  Parse the `genai_user_metrics.sql` file.
2.  Execute each query individually against BigQuery.
3.  Report success/failure status.

**Configuration**: Edit `run_queries.sh` to change the `PROJECT_ID` variable if needed.

