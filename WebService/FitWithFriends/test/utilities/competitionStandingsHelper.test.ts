import {
    calculateRingsDailyPoints,
    calculateDailyMetricValue,
    calculateWorkoutMetricValue,
    parseScoringRules,
    validateScoringRulesInput,
    getScoringUnit,
    isCustomRule,
    defaultRingsRule,
    ScoringRules,
    RingsScoringRule,
    WorkoutsScoringRule,
    DailyScoringRule,
} from '../../utilities/competitionStandingsHelper';

/*
    Unit tests for the rule parsing, validation, and per-day scoring helpers.
    Integration tests for getCompetitionStandings live alongside the route tests.
*/

const sampleRow = {
    calories_burned: 500,
    calories_goal: 500,
    exercise_time: 30,
    exercise_time_goal: 30,
    stand_time: 12,
    stand_time_goal: 12,
};

describe('parseScoringRules', () => {
    it('returns default rings rule for null', () => {
        expect(parseScoringRules(null)).toEqual(defaultRingsRule);
    });

    it('returns default rings rule for unknown kind', () => {
        expect(parseScoringRules({ kind: 'bogus' })).toEqual(defaultRingsRule);
    });

    it('parses a rings rule with minGoals and dailyCap', () => {
        const parsed = parseScoringRules({
            kind: 'rings',
            includedRings: ['calories', 'exercise'],
            minGoals: { calories: 500, exerciseTime: 30 },
            dailyCap: 200,
        });
        expect(parsed).toEqual({
            kind: 'rings',
            includedRings: ['calories', 'exercise'],
            minGoals: { calories: 500, exerciseTime: 30, standTime: undefined },
            dailyCap: 200,
        });
    });

    it('drops invalid includedRings entries', () => {
        const parsed = parseScoringRules({
            kind: 'rings',
            includedRings: ['calories', 'bogus'],
        });
        expect((parsed as RingsScoringRule).includedRings).toEqual(['calories']);
    });

    it('parses a workouts rule', () => {
        const parsed = parseScoringRules({ kind: 'workouts', metric: 'distance', activityTypes: [37, 52] });
        expect(parsed).toEqual({ kind: 'workouts', metric: 'distance', activityTypes: [37, 52] });
    });

    it('normalises empty workouts activityTypes to null', () => {
        const parsed = parseScoringRules({ kind: 'workouts', metric: 'calories', activityTypes: [] });
        expect((parsed as WorkoutsScoringRule).activityTypes).toBeNull();
    });

    it('parses a daily steps rule', () => {
        const parsed = parseScoringRules({ kind: 'daily', metric: 'steps' });
        expect(parsed).toEqual({ kind: 'daily', metric: 'steps' });
    });

    it('falls back to default for invalid daily metric', () => {
        expect(parseScoringRules({ kind: 'daily', metric: 'potato' })).toEqual(defaultRingsRule);
    });
});

describe('validateScoringRulesInput', () => {
    it('accepts default rings rule', () => {
        expect(validateScoringRulesInput({ kind: 'rings' })).toBeNull();
    });

    it('rejects empty includedRings', () => {
        expect(validateScoringRulesInput({ kind: 'rings', includedRings: [] })).toMatch(/includedRings/);
    });

    it('rejects invalid ring in includedRings', () => {
        expect(validateScoringRulesInput({ kind: 'rings', includedRings: ['calories', 'bogus'] })).toMatch(/includedRings/);
    });

    it('rejects dailyCap exceeding 200 × ring count', () => {
        const result = validateScoringRulesInput({ kind: 'rings', includedRings: ['calories', 'exercise'], dailyCap: 500 });
        expect(result).toMatch(/dailyCap/);
    });

    it('rejects non-integer dailyCap', () => {
        expect(validateScoringRulesInput({ kind: 'rings', dailyCap: 599.5 })).toMatch(/dailyCap/);
    });

    it('accepts dailyCap equal to 200 × ring count (matches legacy)', () => {
        expect(validateScoringRulesInput({ kind: 'rings', includedRings: ['calories', 'exercise'], dailyCap: 400 })).toBeNull();
    });

    it('accepts the legacy 600 cap with default 3 rings', () => {
        expect(validateScoringRulesInput({ kind: 'rings', dailyCap: 600 })).toBeNull();
    });

    it('rejects negative minGoals', () => {
        expect(validateScoringRulesInput({ kind: 'rings', minGoals: { calories: -10 } })).toMatch(/minGoals/);
    });

    it('accepts a workouts rule without activityTypes', () => {
        expect(validateScoringRulesInput({ kind: 'workouts', metric: 'calories' })).toBeNull();
    });

    it('rejects a workouts rule with bad metric', () => {
        expect(validateScoringRulesInput({ kind: 'workouts', metric: 'potato' })).toMatch(/metric/);
    });

    it('rejects non-integer activity types', () => {
        expect(validateScoringRulesInput({ kind: 'workouts', metric: 'distance', activityTypes: [37.5] })).toMatch(/activityTypes/);
    });

    it('accepts a daily rule', () => {
        expect(validateScoringRulesInput({ kind: 'daily', metric: 'steps' })).toBeNull();
    });

    it('rejects unknown kind', () => {
        expect(validateScoringRulesInput({ kind: 'other' })).toMatch(/Unknown/);
    });
});

describe('getScoringUnit', () => {
    it('returns points for rings', () => {
        expect(getScoringUnit({ kind: 'rings' })).toBe('points');
    });

    it('returns kcal for workouts calories', () => {
        expect(getScoringUnit({ kind: 'workouts', metric: 'calories' })).toBe('kcal');
    });

    it('returns minutes for workouts duration', () => {
        expect(getScoringUnit({ kind: 'workouts', metric: 'duration' })).toBe('minutes');
    });

    it('returns meters for workouts distance', () => {
        expect(getScoringUnit({ kind: 'workouts', metric: 'distance' })).toBe('meters');
    });

    it('returns steps for daily steps', () => {
        expect(getScoringUnit({ kind: 'daily', metric: 'steps' })).toBe('steps');
    });

    it('returns meters for daily walking-running distance', () => {
        expect(getScoringUnit({ kind: 'daily', metric: 'walkingRunningDistance' })).toBe('meters');
    });
});

describe('isCustomRule', () => {
    it('is false for default rings', () => {
        expect(isCustomRule({ kind: 'rings' })).toBe(false);
    });

    it('is false when includedRings explicitly lists the full set (semantically default)', () => {
        expect(isCustomRule({ kind: 'rings', includedRings: ['calories', 'exercise', 'stand'] })).toBe(false);
    });

    it('is false regardless of full-set ordering', () => {
        expect(isCustomRule({ kind: 'rings', includedRings: ['stand', 'calories', 'exercise'] })).toBe(false);
    });

    it('is true for rings with minGoals', () => {
        expect(isCustomRule({ kind: 'rings', minGoals: { calories: 500 } })).toBe(true);
    });

    it('is true for rings with excluded ring', () => {
        expect(isCustomRule({ kind: 'rings', includedRings: ['calories', 'exercise'] })).toBe(true);
    });

    it('is true for rings with custom dailyCap', () => {
        expect(isCustomRule({ kind: 'rings', dailyCap: 400 })).toBe(true);
    });

    it('is true for any workouts rule', () => {
        expect(isCustomRule({ kind: 'workouts', metric: 'calories' })).toBe(true);
    });

    it('is true for any daily rule', () => {
        expect(isCustomRule({ kind: 'daily', metric: 'steps' })).toBe(true);
    });
});

describe('calculateRingsDailyPoints', () => {
    it('matches legacy behaviour: 1 point per percent, no per-ring cap, total capped at 600', () => {
        const row = { ...sampleRow,
            calories_burned: 1000, calories_goal: 500,      // 200 pts
            exercise_time: 60, exercise_time_goal: 30,      // 200 pts
            stand_time: 24, stand_time_goal: 12,            // 200 pts
        };
        // 600 total, equal to dailyCap
        expect(calculateRingsDailyPoints(row)).toBe(600);
    });

    it('clamps total at dailyCap (600) when rings overachieve above 600', () => {
        const row = { ...sampleRow,
            calories_burned: 10_000, calories_goal: 500,    // 2000 pts
            exercise_time: 600, exercise_time_goal: 30,     // 2000 pts
            stand_time: 100, stand_time_goal: 12,           // ~833 pts
        };
        expect(calculateRingsDailyPoints(row)).toBe(600);
    });

    it('returns 0 when user has 0 goal and no minimum set (gaming prevention pre-requirement)', () => {
        const row = { ...sampleRow, calories_burned: 999, calories_goal: 0, exercise_time: 0, exercise_time_goal: 0, stand_time: 0, stand_time_goal: 0 };
        expect(calculateRingsDailyPoints(row)).toBe(0);
    });

    it('uses minGoal when user goal is below it (prevents trivial-goal gaming)', () => {
        const rule: RingsScoringRule = { kind: 'rings', minGoals: { calories: 500 } };
        // user set goal=1, burned 1 cal → legacy would be 100%, but min makes it 0.2%
        const row = { ...sampleRow, calories_burned: 1, calories_goal: 1, exercise_time: 0, exercise_time_goal: 0, stand_time: 0, stand_time_goal: 0 };
        // effective denominator is max(1, 500) = 500. 1/500 * 100 = 0.2 pts.
        expect(calculateRingsDailyPoints(row, rule)).toBeCloseTo(0.2, 5);
    });

    it('uses userGoal when it exceeds the minGoal', () => {
        const rule: RingsScoringRule = { kind: 'rings', minGoals: { calories: 500 } };
        const row = { ...sampleRow, calories_burned: 750, calories_goal: 1000, exercise_time: 0, exercise_time_goal: 0, stand_time: 0, stand_time_goal: 0 };
        // effective denominator is max(1000, 500) = 1000. 750/1000 * 100 = 75 pts.
        expect(calculateRingsDailyPoints(row, rule)).toBeCloseTo(75, 5);
    });

    it('excludes a ring when not in includedRings and uses ring-count-based default cap', () => {
        const rule: RingsScoringRule = { kind: 'rings', includedRings: ['calories', 'exercise'] };
        const row = { ...sampleRow,
            calories_burned: 500, calories_goal: 500,      // 100 pts
            exercise_time: 30, exercise_time_goal: 30,     // 100 pts
            stand_time: 12, stand_time_goal: 12,           // would be 100, but excluded
        };
        // dailyCap defaults to 400 (2 rings × 200), so the 200 total is well under the cap
        expect(calculateRingsDailyPoints(row, rule)).toBe(200);
    });

    it('excluded-ring rule caps at the 2-ring default (400) when rings overachieve', () => {
        const rule: RingsScoringRule = { kind: 'rings', includedRings: ['calories', 'exercise'] };
        const row = { ...sampleRow,
            calories_burned: 5000, calories_goal: 500,     // 1000 pts
            exercise_time: 300, exercise_time_goal: 30,    // 1000 pts
            stand_time: 0, stand_time_goal: 12,
        };
        expect(calculateRingsDailyPoints(row, rule)).toBe(400);
    });

    it('honours custom dailyCap lower than natural sum', () => {
        const rule: RingsScoringRule = { kind: 'rings', dailyCap: 150 };
        const row = { ...sampleRow,
            calories_burned: 500, calories_goal: 500,
            exercise_time: 30, exercise_time_goal: 30,
            stand_time: 12, stand_time_goal: 12,
        };
        expect(calculateRingsDailyPoints(row, rule)).toBe(150);
    });

    it('lets a single ring reach the full dailyCap via overachievement (legacy compatibility)', () => {
        const rule: RingsScoringRule = { kind: 'rings', includedRings: ['calories'], dailyCap: 100 };
        const row = { ...sampleRow,
            calories_burned: 5000, calories_goal: 500,     // 1000 pts uncapped
            exercise_time: 0, exercise_time_goal: 0,
            stand_time: 0, stand_time_goal: 0,
        };
        // dailyCap clamps the 1000 down to 100
        expect(calculateRingsDailyPoints(row, rule)).toBe(100);
    });
});

describe('calculateDailyMetricValue', () => {
    const row = { step_count: 8500, distance_walking_running_meters: 6200 };

    it('returns step_count for steps metric', () => {
        const rule: DailyScoringRule = { kind: 'daily', metric: 'steps' };
        expect(calculateDailyMetricValue(row, rule)).toBe(8500);
    });

    it('returns distance_walking_running_meters for walkingRunningDistance metric', () => {
        const rule: DailyScoringRule = { kind: 'daily', metric: 'walkingRunningDistance' };
        expect(calculateDailyMetricValue(row, rule)).toBe(6200);
    });
});

describe('calculateWorkoutMetricValue', () => {
    // Workout units: 1=mile, 2=meter
    const runMiles = { duration: 1800, distance: 5, unit: 1, calories_burned: 500 };
    const bikeMeters = { duration: 3600, distance: 20000, unit: 2, calories_burned: 800 };
    const yoga = { duration: 2400, distance: null, unit: null, calories_burned: 200 };

    it('calories metric returns raw kcal', () => {
        const rule: WorkoutsScoringRule = { kind: 'workouts', metric: 'calories' };
        expect(calculateWorkoutMetricValue(runMiles, rule)).toBe(500);
    });

    it('duration metric converts seconds to minutes', () => {
        const rule: WorkoutsScoringRule = { kind: 'workouts', metric: 'duration' };
        expect(calculateWorkoutMetricValue(runMiles, rule)).toBe(30);
        expect(calculateWorkoutMetricValue(bikeMeters, rule)).toBe(60);
    });

    it('distance metric converts miles to meters', () => {
        const rule: WorkoutsScoringRule = { kind: 'workouts', metric: 'distance' };
        expect(calculateWorkoutMetricValue(runMiles, rule)).toBeCloseTo(5 * 1609.344, 2);
    });

    it('distance metric leaves meters as meters', () => {
        const rule: WorkoutsScoringRule = { kind: 'workouts', metric: 'distance' };
        expect(calculateWorkoutMetricValue(bikeMeters, rule)).toBe(20000);
    });

    it('distance metric returns 0 for workouts with no distance', () => {
        const rule: WorkoutsScoringRule = { kind: 'workouts', metric: 'distance' };
        expect(calculateWorkoutMetricValue(yoga, rule)).toBe(0);
    });

    it('calories metric still counts distance-less workouts', () => {
        const rule: WorkoutsScoringRule = { kind: 'workouts', metric: 'calories' };
        expect(calculateWorkoutMetricValue(yoga, rule)).toBe(200);
    });
});
