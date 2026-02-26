/*
oxy:
  description: "Get a summary of recent strength training data including 1RM estimates and volume"
  retrieval:
    include:
      - "How are my lifts going?"
      - "What's my recent strength progress?"
      - "Show me my training summary"
*/

WITH recent_data AS (
    SELECT
        DATE_TRUNC('week', Date) AS week,
        Exercise,
        MAX(weight * POWER(reps, 0.1)) AS est_1rm,
        SUM(weight * reps * sets) AS total_volume,
        AVG(rpe) AS avg_rpe,
        COUNT(*) AS total_sets
    FROM personal_data.exercise.strength_tracker
    WHERE Date >= CURRENT_DATE - INTERVAL '8 weeks'
    GROUP BY 1, 2
)
SELECT
    week,
    Exercise AS exercise_name,
    ROUND(est_1rm, 1) AS estimated_1rm,
    ROUND(total_volume, 0) AS volume,
    ROUND(avg_rpe, 1) AS avg_rpe,
    total_sets
FROM recent_data
ORDER BY week DESC, exercise_name;
