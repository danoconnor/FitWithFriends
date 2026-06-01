-- Migration: Per-user competition notification timing
-- Date: 2026-05-31

-- The user's preferred IANA timezone, reported by the client. Used to send the
-- competition "processing" and "final results" push notifications at ~8am local
-- time per user. NULL = unknown (e.g. client hasn't reported yet); callers fall
-- back to the competition's iana_timezone.
ALTER TABLE public.users ADD COLUMN preferred_timezone text;

-- Per-(user, competition) delivery tracking for the two end-of-competition
-- notifications. A flag is set true once the notification has been satisfied —
-- either successfully delivered via APNs, or rendered in-app (the client marks
-- it seen when it shows the end-of-competition screen). This decouples the
-- notification from the single competition state transition so each user can be
-- notified at their own local 8am.
ALTER TABLE public.users_competitions
    ADD COLUMN sent_processing_notification boolean NOT NULL DEFAULT false,
    ADD COLUMN sent_complete_notification boolean NOT NULL DEFAULT false;
