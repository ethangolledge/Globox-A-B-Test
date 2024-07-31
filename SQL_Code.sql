--Determining the start and end date of the experiment

SELECT 
    MIN(join_dt) AS start_date, 
    MAX(join_dt) AS end_date
FROM groups;

--Start date: 2023-01-25 
--End date: 2023-02-06

/*
Relevance
Determining the start and end date of the A/B test is crucial for analysing and understanding the impact of any changes or interventions during the experiment. These dates help to precisely assess the results and provide context to the stakeholders when interpreting the cost of running the banner and weigh up the potential of a novelty effect.
*/

--Unique user IDs that appear more than once

SELECT
    uid, 
    COUNT(uid) AS count_of_conversions
FROM activity
GROUP BY uid
HAVING COUNT(uid) > 1;

/*
Relevance 
If we did not factor in user id’s appearing multiple times, we would not get an accurate representation of desired test metrics. Specifically, the conversion rate would appear much higher than the true value, misrepresenting findings to stakeholders.
*/

--Handling NULL values

SELECT
    COALESCE(activity.spent, 0)
FROM activity;

/*
Relevance 
If we did not factor in null values, we would not get an accurate representation of desired test metrics. Specifically, the average amount spent by a user would appear much higher than the true value, misrepresenting findings to stakeholders.
*/

--Exploring the sample size

SELECT DISTINCT
    COUNT(uid) AS count_of_users
FROM groups;

--Total sample size: 48943 users

SELECT DISTINCT
    "group", 
    COUNT(uid) AS group_count
FROM groups
GROUP BY "group";

--Control group (A) sample size: 24343 users
--Treatment group (B) sample size: 24600 users
/*
Relevance 
Understanding the total, control and treatment sample sizes is crucial when evaluating the reliability of the experiment and when conducting subsequent statistical tests. These sample size values will be essential for assessing the experiments validity and statistical significance, helping to guide further interpretations on relevance to the wider population.
*/

--Exploring rates of conversion

SELECT
    CONCAT(((SELECT CAST(COUNT(DISTINCT uid) AS float)
    FROM activity)
    /
    (SELECT CAST(COUNT(id) AS float)
    FROM users))*100, '%')
    AS conversion_rate;

--Overall conversion rate: 4.28%.


SELECT
    CONCAT(((SELECT CAST(COUNT(DISTINCT activity.uid) AS float)
    FROM activity
    RIGHT JOIN groups
    ON activity.uid = groups.uid
    WHERE spent IS NOT NULL 
    AND "group" = 'A')
    /
    (SELECT CAST(COUNT(DISTINCT groups.uid) AS float)
    FROM activity
    RIGHT JOIN groups
    ON activity.uid = groups.uid
    WHERE "group" = 'A'))*100, '%')
    AS conversion_rate_for_group_a,
    
    CONCAT(((SELECT CAST(COUNT(DISTINCT activity.uid) AS float)
    FROM activity
    RIGHT JOIN groups
    ON activity.uid = groups.uid
    WHERE spent IS NOT NULL 
    AND "group" = 'B')
    /
    (SELECT CAST(COUNT(DISTINCT groups.uid) AS float)
    FROM activity
    RIGHT JOIN groups
    ON activity.uid = groups.uid
    WHERE "group" = 'B'))*100, '%')
    AS conversion_rate_for_group_b;

--Control group (A) conversion rate: 3.92%
--Treatment group (B) conversion rate: 4.63%

--Exploring the average amount spent 

SELECT
    (SELECT SUM(spent)/COUNT(DISTINCT groups.uid)
    FROM activity 
    RIGHT JOIN groups
    ON activity.uid = groups.uid
    WHERE "group" = 'A')
    AS average_spent_group_a,
    (SELECT SUM(spent)/COUNT(DISTINCT groups.uid)
    FROM activity 
    RIGHT JOIN groups
    ON activity.uid = groups.uid
    WHERE "group" = 'B')
    AS average_spent_group_b   

--Average amount spent by a user in the control (A): $3.37
--Average amount spent by a user in treatment (B): $3.39
/*
Relevance
Understanding the average amount spent per user is crucial in assessing the impact of the A/B test on user spending behaviour. By including all users, irrespective of their conversion status, the metric provides an accurate representation of spending trends, which will help us compare the performance of the control and treatment group, enabling us to make informed decisions.
*/

--Gathering relevant data for visualisations

WITH user_activity AS (
  SELECT
    users.id AS user_id,
    users.country AS user_country,
    COALESCE(users.gender, 'Unknown') AS user_gender,
    groups."group" AS test_group,
    groups.device AS user_device,
    activity.spent,
    groups.join_dt AS date,
    CASE WHEN activity.spent > 0 THEN TRUE ELSE FALSE END AS converted
  FROM users
  LEFT JOIN groups ON users.id = groups.uid
  LEFT JOIN activity ON users.id = activity.uid
)

SELECT
  user_id,
  user_country,
  user_gender,
  test_group,
  user_device,
  converted,
  COALESCE(SUM(spent), 0) AS total_spent,
  date
FROM user_activity
GROUP BY user_id, user_country, user_gender, test_group, user_device, converted, date;
