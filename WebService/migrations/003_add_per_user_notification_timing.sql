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

-- Backfill for the cutover: competitions that already transitioned under the old
-- code path were notified at the state transition (around midnight UTC). Mark
-- those notifications as already-satisfied so the new per-user pass — which would
-- otherwise pick up any state 2/3 competition that ended within the last few days
-- with false flags — does not re-send them and double-notify users.
--
-- State values: 1 = NotStartedOrActive, 2 = ProcessingResults, 3 = Archived.

-- The "processing" notification was sent at the active -> processing transition,
-- so it has already happened for anything past the active state.
UPDATE public.users_competitions uc
SET sent_processing_notification = true
FROM public.competitions c
WHERE uc.competition_id = c.competition_id
  AND c.state IN (2, 3);

-- The "final results" notification was sent at archival, so it has already
-- happened only for archived competitions. Competitions still in the processing
-- state intentionally keep sent_complete_notification = false so the new per-user
-- pass delivers their results notification (once) when they archive.
UPDATE public.users_competitions uc
SET sent_complete_notification = true
FROM public.competitions c
WHERE uc.competition_id = c.competition_id
  AND c.state = 3;
