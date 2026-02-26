/*
oxy:
  retrieval:
    include: 
      - "What's my one-rep max for bench press?"
      - "what's my 1RM"
*/

WITH per_month AS (
    SELECT 
        DATE_TRUNC('month', Date) AS month,
        weight,
        reps,
        weight * (POWER(reps, 0.1)) AS est_1RM
    FROM personal_data.exercise.strength_tracker
    WHERE Exercise = 'Flat Barbell Bench Press'
),
max_per_month AS (
    SELECT 
        month,
        MAX(est_1RM) AS max_estimated_1RM
    FROM per_month
    GROUP BY month
)
SELECT 
    m.month,
    m.max_estimated_1RM,
    p.weight AS corresponding_weight,
    p.reps AS corresponding_reps
FROM max_per_month m
JOIN per_month p
  ON p.month = m.month
 AND p.est_1RM = m.max_estimated_1RM
ORDER BY m.month;

