/* 
Query: Emails Sent by Month (Account Activity Analysis)
Description: Calculates monthly email statistics per account, including 
their percentage share of the total monthly email volume and activity dates.
*/

-- Calculate window metrics for each account per month
SELECT DISTINCT
 sent_month,
 id_account,
  
-- Total emails sent across all accounts in a given month
 COUNT(id_message) OVER (PARTITION BY sent_month) AS total_sent,

-- Percentage of emails sent by this specific account out of the monthly total
 COUNT(id_message)
   OVER (PARTITION BY sent_month, id_account)
   / COUNT(id_message) OVER (PARTITION BY sent_month)
   * 100 as sent_msg_percent_from_this_month,
  
-- First and last email activity dates for the account within the month
 min(sent_date) OVER (PARTITION BY sent_month, id_account) as first_sent_date,
 max(sent_date) OVER (PARTITION BY sent_month, id_account) as last_sent_date
FROM
 (
   SELECT
-- Standardize dates and extract the first day of the month for time-series grouping
     date(
       EXTRACT(year FROM date_add(s.date, INTERVAL es.sent_date day)),
       EXTRACT(month FROM date_add(s.date, INTERVAL es.sent_date day)),
       1)
       AS sent_month,
     id_account,
     id_message,
     date_add(s.date, INTERVAL es.sent_date day) AS sent_date
   FROM `DA.email_sent` es
   JOIN `DA.account_session` acs
     ON acs.account_id = es.id_account
   JOIN `DA.session` s
     ON s.ga_session_id = acs.ga_session_id
 )
