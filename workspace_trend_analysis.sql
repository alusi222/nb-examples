-- Workspace Users Trend Analysis (Last 30 Days)
testttt
-- Daily Active Users Trend
SELECT 
    DS as date,
    COUNT(DISTINCT USER_ID) as daily_active_users,
    SUM(WORKSPACES_NUM_EVENTS) as total_events,
    SUM(WORKSPACES_NUM_SWITCHES) as total_switches,
    SUM(WORKSPACES_FILE_NUM_OPENS) as total_file_opens,
    SUM(WORKSPACES_WORKSHEETS_NUM_QUERIES) as total_queries,
    SUM(WORKSPACES_WORKSHEETS_TOTAL_CREDITS) as total_credits
FROM SNOWSCIENCE.UI.WORKSPACES_USER_DAY_FACT
WHERE DS >= DATEADD(day, -30, CURRENT_DATE())
GROUP BY DS
ORDER BY DS DESC;

-- Weekly Active Users (WAU) Trend
SELECT 
    DATE_TRUNC('week', DS) as week,
    COUNT(DISTINCT USER_ID) as weekly_active_users,
    AVG(WORKSPACES_NUM_EVENTS) as avg_events_per_user,
    SUM(WORKSPACES_WORKSHEETS_TOTAL_CREDITS) as total_credits
FROM SNOWSCIENCE.UI.WORKSPACES_USER_DAY_FACT
WHERE DS >= DATEADD(day, -90, CURRENT_DATE())
GROUP BY DATE_TRUNC('week', DS)
ORDER BY week DESC;

-- Top Deployments by Active Users (Last 7 Days)
SELECT 
    DEPLOYMENT,
    COUNT(DISTINCT USER_ID) as active_users,
    SUM(WORKSPACES_NUM_EVENTS) as total_events,
    SUM(WORKSPACES_WORKSHEETS_NUM_QUERIES) as total_queries,
    ROUND(SUM(WORKSPACES_WORKSHEETS_TOTAL_CREDITS), 2) as total_credits
FROM SNOWSCIENCE.UI.WORKSPACES_USER_DAY_FACT
WHERE DS >= DATEADD(day, -7, CURRENT_DATE())
GROUP BY DEPLOYMENT
ORDER BY active_users DESC
LIMIT 10;

-- User Engagement Metrics (Growth Rate)
WITH daily_metrics AS (
    SELECT 
        DS,
        COUNT(DISTINCT USER_ID) as dau,
        SUM(WORKSPACES_NUM_EVENTS) as events
    FROM SNOWSCIENCE.UI.WORKSPACES_USER_DAY_FACT
    WHERE DS >= DATEADD(day, -30, CURRENT_DATE())
    GROUP BY DS
)
SELECT 
    DS as date,
    dau as daily_active_users,
    LAG(dau) OVER (ORDER BY DS) as previous_day_dau,
    ROUND((dau - LAG(dau) OVER (ORDER BY DS)) / NULLIF(LAG(dau) OVER (ORDER BY DS), 0) * 100, 2) as dau_growth_pct,
    events as total_events
FROM daily_metrics
ORDER BY DS DESC;
