
-- Query 1: Quick peek at the shape & basic stats
-- What: Get a feel for row count, date range, and distinct buyers/sellers/events.
SELECT
  COUNT(*)                                  AS rows_total,
  MIN(saletime)::DATE                        AS first_sale_date,
  MAX(saletime)::DATE                        AS last_sale_date,
  COUNT(DISTINCT buyerid)                    AS buyers_distinct,
  COUNT(DISTINCT sellerid)                   AS sellers_distinct,
  COUNT(DISTINCT eventid)                    AS events_distinct
FROM samples.tickit.sales;



-- Query 2: Daily revenue & tickets sold
-- What: Daily time series to spot trends and seasonality.
-- Note: Treat "revenue" as total price paid; "net_revenue" subtracts commission.
SELECT
  CAST(saletime AS DATE)                                   AS sale_date,
  SUM(pricepaid)                                           AS revenue,
  SUM(pricepaid - COALESCE(commission,0))                  AS net_revenue,
  SUM(qtysold)                                             AS tickets_sold
FROM samples.tickit.sales
GROUP BY sale_date
ORDER BY sale_date;

-- Query 3: Top 10 events by revenue
-- What: See which events drive the most $ and ticket volume.
SELECT
  eventid,
  COUNT(*)                                 AS orders,
  SUM(qtysold)                             AS tickets_sold,
  SUM(pricepaid)                           AS revenue,
  SUM(pricepaid - COALESCE(commission,0))  AS net_revenue
FROM samples.tickit.sales
GROUP BY eventid
ORDER BY revenue DESC;

-- Query 4: Top 10 sellers by net revenue efficiency
-- What: Sellers ranked by net revenue and their average commission rate.
SELECT
  sellerid,
  COUNT(*)                                 AS orders,
  SUM(qtysold)                             AS tickets_sold,
  SUM(pricepaid)                           AS gross_revenue,
  SUM(pricepaid - COALESCE(commission,0))  AS net_revenue,
  CASE
    WHEN SUM(pricepaid) = 0 THEN 0
    ELSE SUM(COALESCE(commission,0)) / SUM(pricepaid)
  END                                       AS avg_commission_rate
FROM samples.tickit.sales
GROUP BY sellerid
ORDER BY net_revenue DESC
LIMIT 10;

-- Query 6: Buyer RFM snapshot (Recency, Frequency, Monetary)
-- What: Score buyers by how recently/frequently/how much they buy.
-- Tip: Adjust NOW() reference date to freeze time if you want a stable snapshot.
WITH buyer_agg AS (
  SELECT
    buyerid,
    MAX(saletime)                        AS last_order_ts,
    COUNT(*)                             AS order_count,
    SUM(pricepaid)                       AS monetary
  FROM samples.tickit.sales
  GROUP BY buyerid
),
scored AS (
  SELECT
    buyerid,
    DATEDIFF('day', last_order_ts, CURRENT_TIMESTAMP()) AS recency_days,
    order_count,
    monetary,
    NTILE(5) OVER (ORDER BY -DATEDIFF('day', last_order_ts, CURRENT_TIMESTAMP())) AS r_score,  -- lower recency_days is better
    NTILE(5) OVER (ORDER BY order_count)                                           AS f_score,
    NTILE(5) OVER (ORDER BY monetary)                                              AS m_score
  FROM buyer_agg
)
SELECT
  buyerid,
  recency_days,
  order_count,
  monetary,
  r_score, f_score, m_score,
  (r_score + f_score + m_score) AS rfm_total
FROM scored
ORDER BY rfm_total DESC, monetary DESC
LIMIT 100;


-- Query 8: Ticket-size distribution & ASP (average selling price) by bucket
-- What: How many orders are small/medium/large, and their average price.
SELECT
  CASE
    WHEN qtysold = 1 THEN '1'
    WHEN qtysold BETWEEN 2 AND 3 THEN '2-3'
    WHEN qtysold BETWEEN 4 AND 6 THEN '4-6'
    ELSE '7+'
  END AS qty__tix_sold_bucket,
  COUNT(*)                      AS orders,
  SUM(qtysold)                  AS tickets_sold,
  AVG(pricepaid / NULLIF(qtysold,0)) AS avg_price_per_ticket
FROM samples.tickit.sales
GROUP BY qty__tix_sold_bucket
ORDER BY
  CASE qty__tix_sold_bucket WHEN '1' THEN 1 WHEN '2-3' THEN 2 WHEN '4-6' THEN 3 ELSE 4 END;


SELECT *
FROM samples.tickit.sales
WHERE MONTH(saletime) = 5;
