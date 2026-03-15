---
name: spark-job-metrics
description: Analyze Spark stage metrics for a maintenance job from itaipu_spark_stage_metrics. Use when investigating slow or timing-out maintenance jobs.
argument-hint: "<sparkop_name> <run_target_date>"
allowed-tools: mcp__nu-mcp__databricks-run-sql, Bash
---

# Spark Job Metrics Analysis

Analyze the Spark stage metrics for job `$0` on date `$1`.

Run the following queries using the `mcp__nu-mcp__databricks-run-sql` tool.

## Query 1 — Summary by step

```sql
SELECT
  step,
  count(*) AS stage_count,
  sum(task_count) AS total_tasks,
  round(sum(task_exec_time_total) / 3600, 1) AS total_cpu_hours,
  round(sum(task_exec_time_total) / 60, 1) AS linear_exec_minutes,
  sum(timestampdiff(MINUTE, stage_start, stage_end)) AS total_wall_minutes,
  max(timestampdiff(MINUTE, stage_start, stage_end)) AS max_stage_wall_minutes,
  round(sum(task_bytes_read_total) / 1e9, 2) AS read_gb,
  round(sum(task_bytes_written_total) / 1e9, 2) AS written_gb,
  sum(failed_task_count) AS failed_tasks
FROM etl.br__series_contract.itaipu_spark_stage_metrics
WHERE run_target_date = '$1'
  AND sparkop_name = '$0'
GROUP BY step
ORDER BY step
```

## Query 2 — Top 20 most expensive stages (by CPU hours)

```sql
SELECT
  job_id,
  stage_id,
  step,
  round(task_exec_time_total / 3600, 1) AS cpu_hours,
  round(task_exec_time_total / 60, 1) AS linear_exec_minutes,
  timestampdiff(MINUTE, stage_start, stage_end) AS wall_minutes,
  task_count,
  round(task_exec_time_max / 1000 / 60, 2) AS max_task_minutes,
  round(task_exec_time_median / 1000 / 60, 4) AS median_task_minutes,
  round(task_shuffle_read_max / 1e6, 0) AS shuffle_read_max_mb,
  round(task_shuffle_written_max / 1e6, 0) AS shuffle_written_max_mb,
  round(task_bytes_read_total / 1e9, 2) AS read_gb,
  round(task_bytes_written_total / 1e9, 2) AS written_gb,
  failed_task_count
FROM etl.br__series_contract.itaipu_spark_stage_metrics
WHERE run_target_date = '$1'
  AND sparkop_name = '$0'
ORDER BY task_exec_time_total DESC
LIMIT 20
```

## Query 3 — Task count distribution (parallelism profile)

```sql
SELECT
  step,
  CASE
    WHEN task_count = 1    THEN '1 task (sequential)'
    WHEN task_count <= 10  THEN '2-10 tasks'
    WHEN task_count <= 50  THEN '11-50 tasks'
    WHEN task_count <= 200 THEN '51-200 tasks'
    WHEN task_count <= 500 THEN '201-500 tasks'
    ELSE '500+ tasks'
  END AS task_bucket,
  count(*) AS stage_count,
  round(sum(task_exec_time_total) / 3600, 1) AS cpu_hours,
  sum(timestampdiff(MINUTE, stage_start, stage_end)) AS wall_minutes
FROM etl.br__series_contract.itaipu_spark_stage_metrics
WHERE run_target_date = '$1'
  AND sparkop_name = '$0'
GROUP BY step, 3
ORDER BY step, min(task_count)
```

## Analysis

After running all queries, provide a structured analysis covering:

1. **Step breakdown** — which step(s) dominate CPU hours and wall-clock time

2. **Time dimension interpretation** — use the three time metrics together to diagnose issues:
   - `linear_exec_minutes`: sum of all task durations — the true measure of computational work, unaffected by parallelism or scheduling noise. Use this to compare the actual work done across steps.
   - `total_wall_minutes` (sum of stage durations): actual elapsed time. If much larger than `linear_exec_minutes / total_tasks`, the gap points to scheduling overhead or task launch cost (too many small tasks).
   - `max_task_minutes` vs `median_task_minutes`: if max is significantly higher than median, the stage has **data skew** — a small number of tasks are doing disproportionate work and are blocking the stage from completing.

3. **Parallelism profile** — identify stages with very few tasks (under-parallelized, potential bottleneck) vs stages with many tasks (well-parallelized). Flag any concentration of CPU hours in single-task or low-task-count stages, as these serialize execution.

4. **Key metrics per step**:
   - Total CPU hours, linear execution minutes, and wall-clock minutes
   - Stage count and total task count
   - Data read/written
   - Failed tasks

5. **Top expensive stages** — what are the costliest individual stages doing (high shuffle, heavy reads, sequential writes)?

6. **Recommendations** — concrete tuning suggestions based on findings, focusing on:
   - Task count: whether increasing (to reduce skew / improve parallelism) or decreasing (to reduce overhead when tasks are too small) the number of tasks would help
   - Skew: if max >> median task time, the data partitioning strategy needs attention
   - Overhead: if wall time >> linear time implies tasks are too short and scheduling dominates
