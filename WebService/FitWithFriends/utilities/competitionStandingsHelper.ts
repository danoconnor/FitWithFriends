import * as ActivityDataQueries from '../sql/activityData.queries';
import * as CompetitionQueries from '../sql/competitions.queries';
import * as UserQueries from '../sql/users.queries';
import { convertUserIdToBuffer } from '../utilities/userHelpers';
import { CompetitionState } from './enums/CompetitionState';

export interface UserPoints {
    userId: string;
    firstName: string;
    lastName: string;
    activityPoints: number;
    pointsToday: number;
}

/* ───────────────────────── Scoring rule types ───────────────────────── */

export type RingKey = 'calories' | 'exercise' | 'stand';
export type WorkoutMetric = 'calories' | 'duration' | 'distance';
export type DailyMetric = 'steps' | 'walkingRunningDistance';

export interface RingsScoringRule {
    kind: 'rings';
    includedRings?: RingKey[];
    minGoals?: { calories?: number; exerciseTime?: number; standTime?: number };
    dailyCap?: number;
}

export interface WorkoutsScoringRule {
    kind: 'workouts';
    metric: WorkoutMetric;
    activityTypes?: number[] | null;
}

export interface DailyScoringRule {
    kind: 'daily';
    metric: DailyMetric;
}

export type ScoringRules = RingsScoringRule | WorkoutsScoringRule | DailyScoringRule;

export type ScoringUnit = 'points' | 'kcal' | 'minutes' | 'meters' | 'steps';

export const defaultRingsRule: RingsScoringRule = { kind: 'rings' };

const allRings: RingKey[] = ['calories', 'exercise', 'stand'];

// Workout distance unit enum - must match Clients/iOS/.../Data/Model/Unit.swift
const UNIT_MILE = 1;
const UNIT_METER = 2;
const METERS_PER_MILE = 1609.344;

/* ───────────────────────── Rule parsing / validation ───────────────────────── */

/**
 * Normalise a JSONB value read from competitions.scoring_rules into a typed rule.
 * Returns the legacy rings rule for NULL / unrecognised input so existing rows keep scoring identically.
 */
export function parseScoringRules(raw: unknown): ScoringRules {
    if (!raw || typeof raw !== 'object') {
        return defaultRingsRule;
    }
    const r = raw as Record<string, unknown>;
    switch (r.kind) {
        case 'rings': {
            const includedRings = Array.isArray(r.includedRings)
                ? r.includedRings.filter((x): x is RingKey => typeof x === 'string' && (allRings as string[]).includes(x))
                : undefined;
            const minGoalsRaw = (r.minGoals && typeof r.minGoals === 'object') ? r.minGoals as Record<string, unknown> : undefined;
            const minGoals = minGoalsRaw ? {
                calories: typeof minGoalsRaw.calories === 'number' ? minGoalsRaw.calories : undefined,
                exerciseTime: typeof minGoalsRaw.exerciseTime === 'number' ? minGoalsRaw.exerciseTime : undefined,
                standTime: typeof minGoalsRaw.standTime === 'number' ? minGoalsRaw.standTime : undefined,
            } : undefined;
            return {
                kind: 'rings',
                includedRings: includedRings && includedRings.length > 0 ? includedRings : undefined,
                minGoals,
                dailyCap: typeof r.dailyCap === 'number' && r.dailyCap > 0 ? r.dailyCap : undefined,
            };
        }
        case 'workouts': {
            if (r.metric !== 'calories' && r.metric !== 'duration' && r.metric !== 'distance') {
                return defaultRingsRule;
            }
            const activityTypes = Array.isArray(r.activityTypes)
                ? r.activityTypes.filter((x): x is number => typeof x === 'number' && Number.isFinite(x))
                : null;
            return {
                kind: 'workouts',
                metric: r.metric as WorkoutMetric,
                activityTypes: activityTypes && activityTypes.length > 0 ? activityTypes : null,
            };
        }
        case 'daily': {
            if (r.metric !== 'steps' && r.metric !== 'walkingRunningDistance') {
                return defaultRingsRule;
            }
            return { kind: 'daily', metric: r.metric as DailyMetric };
        }
        default:
            return defaultRingsRule;
    }
}

/**
 * Validate a rule coming from client input. Returns null if valid, or an error message.
 * Stricter than `parseScoringRules`, which is lenient when reading stored values.
 */
export function validateScoringRulesInput(input: unknown): string | null {
    if (!input || typeof input !== 'object') return 'scoringRules must be an object';
    const r = input as Record<string, unknown>;
    switch (r.kind) {
        case 'rings': {
            if (r.includedRings !== undefined) {
                if (!Array.isArray(r.includedRings) || r.includedRings.length === 0) {
                    return 'includedRings must be a non-empty array';
                }
                for (const item of r.includedRings) {
                    if (typeof item !== 'string' || !(allRings as string[]).includes(item)) {
                        return `includedRings contains invalid value: ${item}`;
                    }
                }
            }
            if (r.minGoals !== undefined) {
                if (!r.minGoals || typeof r.minGoals !== 'object') return 'minGoals must be an object';
                for (const [key, value] of Object.entries(r.minGoals as Record<string, unknown>)) {
                    if (!['calories', 'exerciseTime', 'standTime'].includes(key)) return `minGoals has unknown key: ${key}`;
                    if (typeof value !== 'number' || value < 0 || value > 10000) return `minGoals.${key} must be a non-negative number <= 10000`;
                }
            }
            if (r.dailyCap !== undefined) {
                if (typeof r.dailyCap !== 'number' || r.dailyCap <= 0) return 'dailyCap must be a positive number';
                const ringsCount = Array.isArray(r.includedRings) ? r.includedRings.length : 3;
                // Natural max is 200 per included ring (legacy cap for 3 rings = 600).
                if (r.dailyCap > ringsCount * 200) return `dailyCap cannot exceed ${ringsCount * 200}`;
            }
            return null;
        }
        case 'workouts': {
            if (r.metric !== 'calories' && r.metric !== 'duration' && r.metric !== 'distance') {
                return 'workouts.metric must be calories, duration, or distance';
            }
            if (r.activityTypes !== undefined && r.activityTypes !== null) {
                if (!Array.isArray(r.activityTypes)) return 'activityTypes must be an array';
                for (const item of r.activityTypes) {
                    if (typeof item !== 'number' || !Number.isInteger(item) || item < 0) {
                        return 'activityTypes must contain non-negative integers';
                    }
                }
            }
            return null;
        }
        case 'daily': {
            if (r.metric !== 'steps' && r.metric !== 'walkingRunningDistance') {
                return 'daily.metric must be steps or walkingRunningDistance';
            }
            return null;
        }
        default:
            return `Unknown scoring rule kind: ${String(r.kind)}`;
    }
}

/** True for rules other than the legacy rings rule — used to gate custom rules behind Pro. */
export function isCustomRule(rules: ScoringRules): boolean {
    if (rules.kind !== 'rings') return true;
    return !!rules.includedRings || !!rules.minGoals || !!rules.dailyCap;
}

export function getScoringUnit(rules: ScoringRules): ScoringUnit {
    switch (rules.kind) {
        case 'rings':
            return 'points';
        case 'workouts':
            switch (rules.metric) {
                case 'calories': return 'kcal';
                case 'duration': return 'minutes';
                case 'distance': return 'meters';
            }
        // eslint-disable-next-line no-fallthrough
        case 'daily':
            return rules.metric === 'steps' ? 'steps' : 'meters';
    }
}

/* ───────────────────────── Per-day score calculation ───────────────────────── */

function resolveIncludedRings(rule: RingsScoringRule): RingKey[] {
    return (rule.includedRings && rule.includedRings.length > 0) ? rule.includedRings : allRings;
}

function resolveDailyCap(rule: RingsScoringRule): number {
    if (rule.dailyCap && rule.dailyCap > 0) return rule.dailyCap;
    // Legacy-compatible default: 3 rings × 200 = 600 (matches Apple Watch competition cap).
    // Scales proportionally when rings are excluded.
    return resolveIncludedRings(rule).length * 200;
}

/**
 * Rings-rule daily score. Each included ring contributes 1 point per percent of goal completed
 * (no per-ring cap, matching legacy behaviour: over-achievement on one ring can compensate for
 * under-achievement on another). The total is then clamped to `dailyCap`.
 * Excluded rings contribute 0. An effective per-metric goal of 0 (user has no goal and no
 * minimum) contributes 0.
 */
export function calculateRingsDailyPoints(
    row: {
        calories_burned: number; calories_goal: number;
        exercise_time: number; exercise_time_goal: number;
        stand_time: number; stand_time_goal: number;
    },
    rule: RingsScoringRule = defaultRingsRule,
): number {
    const included = resolveIncludedRings(rule);
    const cap = resolveDailyCap(rule);
    let points = 0;

    if (included.includes('calories')) {
        const effectiveGoal = Math.max(row.calories_goal, rule.minGoals?.calories ?? 0);
        if (effectiveGoal > 0) points += row.calories_burned / effectiveGoal * 100;
    }
    if (included.includes('exercise')) {
        const effectiveGoal = Math.max(row.exercise_time_goal, rule.minGoals?.exerciseTime ?? 0);
        if (effectiveGoal > 0) points += row.exercise_time / effectiveGoal * 100;
    }
    if (included.includes('stand')) {
        const effectiveGoal = Math.max(row.stand_time_goal, rule.minGoals?.standTime ?? 0);
        if (effectiveGoal > 0) points += row.stand_time / effectiveGoal * 100;
    }

    return Math.min(points, cap);
}

/**
 * Legacy entry point for callers that always assume the default rings rule.
 * Exists so existing call sites (userDetails endpoint, daily archiving) keep compiling; new
 * rule-aware callers should use `calculateRingsDailyPoints` with an explicit rule.
 */
export function calculateDailyPoints(row: {
    calories_burned: number; calories_goal: number;
    exercise_time: number; exercise_time_goal: number;
    stand_time: number; stand_time_goal: number;
}): number {
    return calculateRingsDailyPoints(row, defaultRingsRule);
}

/** Daily-totals rule: read the already-aggregated daily column. */
export function calculateDailyMetricValue(
    row: { step_count: number; distance_walking_running_meters: number },
    rule: DailyScoringRule,
): number {
    return rule.metric === 'steps' ? row.step_count : row.distance_walking_running_meters;
}

function convertWorkoutDistanceToMeters(distance: number | null | undefined, unit: number | null | undefined): number {
    if (distance == null || unit == null) return 0;
    switch (unit) {
        case UNIT_MILE: return distance * METERS_PER_MILE;
        case UNIT_METER: return distance;
        default: return 0;
    }
}

/** Extract one workout's contribution toward a workouts-rule total (in the rule's unit). */
export function calculateWorkoutMetricValue(
    workout: { duration: number; distance: number | null; unit: number | null; calories_burned: number },
    rule: WorkoutsScoringRule,
): number {
    switch (rule.metric) {
        case 'calories': return workout.calories_burned;
        case 'duration': return workout.duration / 60; // seconds → minutes
        case 'distance': return convertWorkoutDistanceToMeters(workout.distance, workout.unit);
    }
}

/* ───────────────────────── Competition-wide rollup ───────────────────────── */

function isSameYMD(a: Date, b: Date): boolean {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

/**
 * Get the current standings for a competition.
 *
 * Archived competitions read frozen values from `users_competitions.final_points`. Active
 * competitions dispatch to activity-summary scoring (rings / daily) or workout scoring.
 */
export async function getCompetitionStandings(
    competitionInfo: CompetitionQueries.IGetCompetitionResult,
    users: UserQueries.IGetUsersInCompetitionResult[],
    timeZone: string,
): Promise<{ [userId: string]: UserPoints }> {

    if (competitionInfo.state === CompetitionState.Archived) {
        const archived: { [userId: string]: UserPoints } = {};
        users.forEach(user => {
            archived[user.userId] = {
                userId: user.userId,
                firstName: user.first_name,
                lastName: user.last_name,
                activityPoints: user.finalPoints,
                pointsToday: 0,
            };
        });
        return archived;
    }

    const rules = parseScoringRules(competitionInfo.scoring_rules);

    const currentDateStr = new Date().toLocaleDateString('en-US', { timeZone });
    const currentDate = new Date(currentDateStr);

    const userPoints: { [userId: string]: UserPoints } = {};
    users.forEach(row => {
        userPoints[row.userId] = {
            userId: row.userId,
            firstName: row.first_name,
            lastName: row.last_name,
            activityPoints: 0,
            pointsToday: 0,
        };
    });

    const userIdList = users.map(row => convertUserIdToBuffer(row.userId));

    if (rules.kind === 'workouts') {
        const workouts = await ActivityDataQueries.getWorkoutsForUsersInDateRange({
            userIds: userIdList,
            startDate: competitionInfo.start_date,
            endDate: competitionInfo.end_date,
        });
        const typeFilter = rules.activityTypes && rules.activityTypes.length > 0 ? new Set(rules.activityTypes) : null;
        for (const w of workouts) {
            const bucket = userPoints[w.userId];
            if (!bucket) continue;
            if (typeFilter && !typeFilter.has(w.workout_type)) continue;
            const value = calculateWorkoutMetricValue(w, rules);
            bucket.activityPoints += value;
            if (isSameYMD(w.start_date, currentDate)) {
                bucket.pointsToday += value;
            }
        }
    } else {
        const summaries = await ActivityDataQueries.getActivitySummariesForUsers({
            userIds: userIdList,
            startDate: competitionInfo.start_date,
            endDate: competitionInfo.end_date,
        });
        for (const row of summaries) {
            const bucket = userPoints[row.userId];
            if (!bucket) continue;
            const daily = rules.kind === 'rings'
                ? calculateRingsDailyPoints(row, rules)
                : calculateDailyMetricValue(row, rules);
            bucket.activityPoints += daily;
            if (isSameYMD(row.date, currentDate)) {
                bucket.pointsToday = daily;
            }
        }
    }

    return userPoints;
}
