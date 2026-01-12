# Gemini Enterprise Analytics

This repository contains SQL queries and documentation for analyzing User Adoption, Growth, and Engagement metrics for Gemini Enterprise Chat logs in BigQuery.

## Overview

We track various metrics to understand how users interact with Gemini Enterprise, including:
- **Adoption**: Daily Active Users (DAU)
- **Growth**: New User Acquisition
- **Engagement**: Stickiness (DAU/MAU), Session Depth, Session Duration
- **Champions**: Identifying Power Users
- **Retention**: Weekly User Retention

## Documentation

- [GenAI User Analytics](genai_user_analytics.md): Detailed SQL queries for 10 key analytics metrics.

## Data Source

The queries are designed for the BigQuery table: `bnoriega-test-ge.ConversationLogs.gemini_chat`

## Usage

You can run these queries directly in the BigQuery console to generate reports and dashboards.