---
name: dashboard-semantic-check
description: Before creating any dashboard, check if an existing semantic view is available that matches the data topic, and ask the user if they want to use it.
---

# Instructions

**TRIGGER**: Whenever the user asks to create a dashboard.

**BEFORE writing any dashboard spec or SQL**, follow these steps:

## Step 1: Search for Relevant Semantic Views

Use `snowflake_semantic_view_search` with a query derived from the user's dashboard topic (e.g. "ticket sales", "revenue", "customers", etc.).

## Step 2: Evaluate Results

- If **one or more semantic views** are found that match the topic:
  - Present them to the user in a concise list (name, database/schema, and a one-line description of what entities/tables it covers)
  - Ask: **"I found existing semantic view(s) related to this topic. Would you like me to use one of them to power the dashboard? Using a semantic view ensures the queries align with your defined business logic."**
  - Wait for the user's response before proceeding.
  - If the user says yes, use `generic_semantic_context` to load the chosen semantic view, then build dashboard SQL grounded on that model's logical table names and column names.
  - If the user says no, proceed with standard SQL against physical tables.

- If **no relevant semantic views** are found:
  - Proceed directly to building the dashboard without asking.

## Step 3: Build the Dashboard

Continue with the normal dashboard creation workflow.
