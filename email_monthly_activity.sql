CREATE OR REPLACE VIEW Students.email_monthly
AS
WITH
  sent_date AS (
    SELECT
      DATE_TRUNC(DATE_ADD(s.date, INTERVAL es.sent_date DAY), MONTH)
        AS sent_month,
      es.id_account,
      COUNT(DISTINCT es.id_message) AS msg_monthly,
      MIN(DATE_ADD(s.date, INTERVAL es.sent_date DAY)) AS first_sent_date,
      MAX(DATE_ADD(s.date, INTERVAL es.sent_date DAY)) AS last_sent_date
    FROM `DA.email_sent` es
    JOIN `DA.account_session` acs
      ON es.id_account = acs.account_id
    JOIN `DA.session` s
      ON s.ga_session_id = acs.ga_session_id
    GROUP BY
      sent_month,
      es.id_account
  )
SELECT
  sent_month,
  id_account,
  ROUND(
    SAFE_DIVIDE(msg_monthly, SUM(msg_monthly) OVER (PARTITION BY sent_month))
      * 100,
    2)
    AS sent_msg_percent_from_this_month,
  first_sent_date,
  last_sent_date
FROM sent_date;
