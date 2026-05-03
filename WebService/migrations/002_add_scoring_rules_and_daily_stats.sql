-- Migration: Add custom scoring rules on competitions + daily step/distance/flights columns
-- Date: 2026-04-22

-- Per-competition scoring rule config. NULL = legacy Activity Rings scoring (all 3 rings,
-- no minimum goals, 600 daily cap) so existing rows keep scoring identically.
ALTER TABLE public.competitions
    ADD COLUMN scoring_rules jsonb;

-- iOS has always uploaded these fields, but the backend dropped them. They're needed to
-- score "Daily Totals" rule competitions (steps / walking-running distance).
ALTER TABLE public.activity_summaries
    ADD COLUMN step_count integer NOT NULL DEFAULT 0,
    ADD COLUMN distance_walking_running_meters integer NOT NULL DEFAULT 0,
    ADD COLUMN flights_climbed integer NOT NULL DEFAULT 0;
