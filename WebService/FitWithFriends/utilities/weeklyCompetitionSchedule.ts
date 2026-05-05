'use strict';
import { Json } from '../sql/competitions.queries';

export interface CompetitionTemplate {
    displayName: string;
    scoringRules: Json;
}

export type WeeklyPair = [CompetitionTemplate, CompetitionTemplate];

// Week 0 = May 4, 2026 (first Monday of the schedule)
export const SCHEDULE_START_DATE = new Date('2026-05-04T00:00:00Z');

export const WEEKLY_SCHEDULE: WeeklyPair[] = [
    // ── May 2026 ─────────────────────────────────────────────────────────
    // Week 0 — May 4–10
    [
        { displayName: 'Spring Into Action', scoringRules: { kind: 'rings' } },
        { displayName: 'May Day Mileage', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 1 — May 11–17
    [
        { displayName: 'Bloom & Burn', scoringRules: { kind: 'workouts', metric: 'calories' } },
        { displayName: 'Pedometer Party', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
    // Week 2 — May 18–24
    [
        { displayName: 'Sunshine Sweat', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
        { displayName: 'Distance Dreamer', scoringRules: { kind: 'workouts', metric: 'distance' } },
    ],
    // Week 3 — May 25–31
    [
        { displayName: 'Memorial Move', scoringRules: { kind: 'workouts', metric: 'duration' } },
        { displayName: 'Stand Up for Summer', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
    ],
    // ── June 2026 ─────────────────────────────────────────────────────────
    // Week 4 — Jun 1–7
    [
        { displayName: 'June Jumpstart', scoringRules: { kind: 'rings' } },
        { displayName: 'Calorie Countdown', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
    ],
    // Week 5 — Jun 8–14
    [
        { displayName: 'Sweat Season Begins', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'Workout Warriors', scoringRules: { kind: 'workouts', metric: 'distance' } },
    ],
    // Week 6 — Jun 15–21
    [
        { displayName: 'Solstice Sprint', scoringRules: { kind: 'workouts', metric: 'calories' } },
        { displayName: 'Long Days, Long Walks', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 7 — Jun 22–28
    [
        { displayName: 'Summer Kickoff', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
        { displayName: 'Midsummer Miles', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // ── July 2026 ─────────────────────────────────────────────────────────
    // Week 8 — Jun 29–Jul 5
    [
        { displayName: 'Independence Day Dash', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'Fireworks & Fitness', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
    ],
    // Week 9 — Jul 6–12
    [
        { displayName: 'Hot Stuff', scoringRules: { kind: 'workouts', metric: 'calories' } },
        { displayName: 'Beat the Heat Walk', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 10 — Jul 13–19
    [
        { displayName: 'Summer Sizzler', scoringRules: { kind: 'rings' } },
        { displayName: 'Halfway to August', scoringRules: { kind: 'workouts', metric: 'distance' } },
    ],
    // Week 11 — Jul 20–26
    [
        { displayName: 'Dog Days Hustle', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
        { displayName: 'Sweat Equity', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // Week 12 — Jul 27–Aug 2
    [
        { displayName: 'End of July Blitz', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'Ring It In', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
    ],
    // ── August 2026 ───────────────────────────────────────────────────────
    // Week 13 — Aug 3–9
    [
        { displayName: 'August Arms Race', scoringRules: { kind: 'workouts', metric: 'calories' } },
        { displayName: 'Dog Day Distance', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 14 — Aug 10–16
    [
        { displayName: 'Late Summer Surge', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
        { displayName: 'Tempo Tuesday (All Week)', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // Week 15 — Aug 17–23
    [
        { displayName: 'Back-to-School Burn', scoringRules: { kind: 'rings' } },
        { displayName: 'Step Up Your Game', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
    // Week 16 — Aug 24–30
    [
        { displayName: 'Last Splash', scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'Summer Send-Off', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
    ],
    // ── September 2026 ────────────────────────────────────────────────────
    // Week 17 — Aug 31–Sep 6
    [
        { displayName: 'Labor Day Legs', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
        { displayName: 'New Month New Moves', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
    ],
    // Week 18 — Sep 7–13
    [
        { displayName: 'Fall Prep Week', scoringRules: { kind: 'workouts', metric: 'calories' } },
        { displayName: 'Crisp Air Cardio', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
    // Week 19 — Sep 14–20
    [
        { displayName: 'Autumn Approach', scoringRules: { kind: 'rings' } },
        { displayName: 'Sunset Strides', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // Week 20 — Sep 21–27
    [
        { displayName: 'Equinox Energy', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
        { displayName: 'Fall Forward Miles', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // ── October 2026 ──────────────────────────────────────────────────────
    // Week 21 — Sep 28–Oct 4
    [
        { displayName: 'Spooky Season Begins', scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'October Opening Sprint', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
    ],
    // Week 22 — Oct 5–11
    [
        { displayName: 'Pumpkin Spice & Exercise', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'Leaf Pile Laps', scoringRules: { kind: 'workouts', metric: 'calories' } },
    ],
    // Week 23 — Oct 12–18
    [
        { displayName: 'Haunted Hustle', scoringRules: { kind: 'rings' } },
        { displayName: 'Creepy Cardio', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 24 — Oct 19–25
    [
        { displayName: 'Costume Cardio', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
        { displayName: 'Monster Mash Miles', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // Week 25 — Oct 26–Nov 1
    [
        { displayName: 'Halloween Hustle', scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'Trick or Treat Steps', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
    // ── November 2026 ─────────────────────────────────────────────────────
    // Week 26 — Nov 2–8
    [
        { displayName: 'Fall Back, Move Forward', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
        { displayName: 'November Hustle', scoringRules: { kind: 'workouts', metric: 'calories' } },
    ],
    // Week 27 — Nov 9–15
    [
        { displayName: 'Cozy Cardio Season', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
        { displayName: 'Chilly Morning Miles', scoringRules: { kind: 'rings' } },
    ],
    // Week 28 — Nov 16–22
    [
        { displayName: 'Turkey Trot Training', scoringRules: { kind: 'workouts', metric: 'duration' } },
        { displayName: 'Pre-Feast Step Fest', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
    // Week 29 — Nov 23–29
    [
        { displayName: 'Thanksgiving Burn-Off', scoringRules: { kind: 'workouts', metric: 'calories' } },
        { displayName: 'Gobble & Go', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
    ],
    // ── December 2026 ─────────────────────────────────────────────────────
    // Week 30 — Nov 30–Dec 6
    [
        { displayName: 'December Kickoff', scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'Festive First Steps', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
    ],
    // Week 31 — Dec 7–13
    [
        { displayName: 'Jingle & Jog', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'Holiday Hustle', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // Week 32 — Dec 14–20
    [
        { displayName: 'Winter Wonderwalk', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
        { displayName: 'Season of Giving Gains', scoringRules: { kind: 'rings' } },
    ],
    // Week 33 — Dec 21–27
    [
        { displayName: 'Solstice Sweat', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
        { displayName: 'Christmas Calorie Burn', scoringRules: { kind: 'workouts', metric: 'calories' } },
    ],
    // Week 34 — Dec 28–Jan 3
    [
        { displayName: 'New Year Countdown Cardio', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'Out with the Old Reps', scoringRules: { kind: 'workouts', metric: 'distance' } },
    ],
    // ── January 2027 ──────────────────────────────────────────────────────
    // Week 35 — Jan 4–10
    [
        { displayName: 'New Year, New You', scoringRules: { kind: 'rings' } },
        { displayName: 'Resolution Runner', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 36 — Jan 11–17
    [
        { displayName: 'January Jumpstart', scoringRules: { kind: 'workouts', metric: 'calories' } },
        { displayName: 'Winter Warrior Steps', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
    // Week 37 — Jan 18–24
    [
        { displayName: 'Polar Bear Pounds', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
        { displayName: 'Frozen Feet Miles', scoringRules: { kind: 'workouts', metric: 'distance' } },
    ],
    // Week 38 — Jan 25–31
    [
        { displayName: 'End of January Blitz', scoringRules: { kind: 'workouts', metric: 'duration' } },
        { displayName: 'Chill and Burn', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
    ],
    // ── February 2027 ─────────────────────────────────────────────────────
    // Week 39 — Feb 1–7
    [
        { displayName: 'February Fitness Love', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'Heart Month Hustle', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
    ],
    // Week 40 — Feb 8–14
    [
        { displayName: "Valentine's Day Burn", scoringRules: { kind: 'workouts', metric: 'calories' } },
        { displayName: 'Love Your Lungs Miles', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 41 — Feb 15–21
    [
        { displayName: 'Presidents Day Pedal', scoringRules: { kind: 'rings' } },
        { displayName: 'Mid-February Momentum', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // Week 42 — Feb 22–28
    [
        { displayName: 'February Finish Strong', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
        { displayName: 'Leap Toward Spring', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
    // ── March 2027 ────────────────────────────────────────────────────────
    // Week 43 — Mar 1–7
    [
        { displayName: 'March Madness Miles', scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'Spring Preview Burn', scoringRules: { kind: 'workouts', metric: 'calories' } },
    ],
    // Week 44 — Mar 8–14
    [
        { displayName: 'Daylight Saving Dash', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
        { displayName: 'Extra Hour? Walk More!', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 45 — Mar 15–21
    [
        { displayName: 'St. Paddy Strides', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'Lucky Legs Challenge', scoringRules: { kind: 'rings' } },
    ],
    // Week 46 — Mar 22–28
    [
        { displayName: 'Spring Equinox Energy', scoringRules: { kind: 'workouts', metric: 'duration' } },
        { displayName: 'Almost April Hustle', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
    ],
    // ── April 2027 ────────────────────────────────────────────────────────
    // Week 47 — Mar 29–Apr 4
    [
        { displayName: 'April Fools? No Excuses', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
        { displayName: 'Spring Forward Strides', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 48 — Apr 5–11
    [
        { displayName: 'April Showers Cardio', scoringRules: { kind: 'workouts', metric: 'calories' } },
        { displayName: 'Easter Egg Hunt Steps', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
    // Week 49 — Apr 12–18
    [
        { displayName: 'Bloom Season Burn', scoringRules: { kind: 'rings' } },
        { displayName: 'Cherry Blossom Miles', scoringRules: { kind: 'workouts', metric: 'distance' } },
    ],
    // Week 50 — Apr 19–25
    [
        { displayName: 'Earth Day Every Day', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
        { displayName: 'April Closing Sprint', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // ── May 2027 ──────────────────────────────────────────────────────────
    // Week 51 — Apr 26–May 2
    [
        { displayName: 'May Eve Mileage', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
        { displayName: 'Spring Finale Burn', scoringRules: { kind: 'workouts', metric: 'calories' } },
    ],
    // Week 52 — May 3–9
    [
        { displayName: 'Year One Celebration', scoringRules: { kind: 'rings' } },
        { displayName: 'Anniversary Laps', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
    // Week 53 — May 10–16
    [
        { displayName: "Mother's Day Miles", scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
        { displayName: 'Fresh May Burn', scoringRules: { kind: 'workouts', metric: 'calories' } },
    ],
    // Week 54 — May 17–23
    [
        { displayName: 'Late Spring Lap Fest', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
        { displayName: 'Warm Up for Summer', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // Week 55 — May 24–30
    [
        { displayName: 'Memorial Miles', scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'Last May Monday', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
    ],
    // ── June 2027 ─────────────────────────────────────────────────────────
    // Week 56 — May 31–Jun 6
    [
        { displayName: 'June Bug Jump', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'Summer Opener', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
    ],
    // Week 57 — Jun 7–13
    [
        { displayName: 'Scorched Steps', scoringRules: { kind: 'workouts', metric: 'calories' } },
        { displayName: 'Sweltering Strides', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 58 — Jun 14–20
    [
        { displayName: 'Halfway Through June', scoringRules: { kind: 'rings' } },
        { displayName: 'Sunscreen & Sprints', scoringRules: { kind: 'workouts', metric: 'distance' } },
    ],
    // Week 59 — Jun 21–27
    [
        { displayName: 'Solstice Showdown', scoringRules: { kind: 'workouts', metric: 'duration' } },
        { displayName: 'Longest Day Legs', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
    ],
    // ── July 2027 ─────────────────────────────────────────────────────────
    // Week 60 — Jun 28–Jul 4
    [
        { displayName: 'Fourth of July Fitness', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'Patriot Pace', scoringRules: { kind: 'workouts', metric: 'calories' } },
    ],
    // Week 61 — Jul 5–11
    [
        { displayName: 'Post-Holiday Push', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
        { displayName: 'Midsummer Madness', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 62 — Jul 12–18
    [
        { displayName: 'Heat Index Hustle', scoringRules: { kind: 'rings' } },
        { displayName: 'July Jog-Off', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // Week 63 — Jul 19–25
    [
        { displayName: 'Dog Days Distance', scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'Summer Sweat Stakes', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
    ],
    // Week 64 — Jul 26–Aug 1
    [
        { displayName: 'July Finale Blitz', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'Finish Strong', scoringRules: { kind: 'workouts', metric: 'calories' } },
    ],
    // ── August 2027 ───────────────────────────────────────────────────────
    // Week 65 — Aug 2–8
    [
        { displayName: 'August Assault', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
        { displayName: 'End of Summer Countdown', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 66 — Aug 9–15
    [
        { displayName: 'Back to School Bootcamp', scoringRules: { kind: 'workouts', metric: 'duration' } },
        { displayName: 'Late Summer Step Up', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
    ],
    // Week 67 — Aug 16–22
    [
        { displayName: 'Harvest Season Hustle', scoringRules: { kind: 'workouts', metric: 'calories' } },
        { displayName: 'Full Rings Fury', scoringRules: { kind: 'rings' } },
    ],
    // Week 68 — Aug 23–29
    [
        { displayName: 'Last Call for Sunscreen', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'August Mile Marker', scoringRules: { kind: 'workouts', metric: 'distance' } },
    ],
    // ── September 2027 ────────────────────────────────────────────────────
    // Week 69 — Aug 30–Sep 5
    [
        { displayName: 'Labor Day Long Haul', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
        { displayName: 'September Surge', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
    ],
    // Week 70 — Sep 6–12
    [
        { displayName: 'Leaf Peeper Laps', scoringRules: { kind: 'workouts', metric: 'duration' } },
        { displayName: 'Fall Feeling Steps', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
    // Week 71 — Sep 13–19
    [
        { displayName: 'September Shakeout', scoringRules: { kind: 'rings' } },
        { displayName: 'Harvest Hustle', scoringRules: { kind: 'workouts', metric: 'calories' } },
    ],
    // Week 72 — Sep 20–26
    [
        { displayName: 'Equinox Earn It', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
        { displayName: 'Autumn Miles', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // ── October 2027 ──────────────────────────────────────────────────────
    // Week 73 — Sep 27–Oct 3
    [
        { displayName: 'October Kick-Off', scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'Sweater Weather Strides', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
    ],
    // Week 74 — Oct 4–10
    [
        { displayName: 'Crunchy Leaves Cardio', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'Pumpkin Patch Pace', scoringRules: { kind: 'workouts', metric: 'calories' } },
    ],
    // Week 75 — Oct 11–17
    [
        { displayName: 'Spooky Strides', scoringRules: { kind: 'rings' } },
        { displayName: 'Cider Run Miles', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // Week 76 — Oct 18–24
    [
        { displayName: 'Witch Way to the Finish?', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
        { displayName: 'Scary Good Steps', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 77 — Oct 25–31
    [
        { displayName: 'All Hallows Hustle', scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'Haunted Half-Laps', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
    ],
    // ── November 2027 ─────────────────────────────────────────────────────
    // Week 78 — Nov 1–7
    [
        { displayName: 'November Now', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'Grateful Gains', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
    ],
    // Week 79 — Nov 8–14
    [
        { displayName: 'Daylight Saving Dropout', scoringRules: { kind: 'workouts', metric: 'calories' } },
        { displayName: 'Post-Dark Dash', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 80 — Nov 15–21
    [
        { displayName: 'Turkey Prep Trot', scoringRules: { kind: 'rings' } },
        { displayName: 'Stuffing Burner', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // Week 81 — Nov 22–28
    [
        { displayName: 'Thankful & Sweaty', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
        { displayName: 'Gobble Down the Miles', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
    // ── December 2027 ─────────────────────────────────────────────────────
    // Week 82 — Nov 29–Dec 5
    [
        { displayName: 'Cyber Monday Cardio', scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'December Debut', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
    ],
    // Week 83 — Dec 6–12
    [
        { displayName: 'Tinsel & Treadmills', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
        { displayName: 'Holiday Hustle Vol. 2', scoringRules: { kind: 'workouts', metric: 'calories' } },
    ],
    // Week 84 — Dec 13–19
    [
        { displayName: 'Ugly Sweater Sprint', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
        { displayName: 'Elves vs Everyone', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
    // Week 85 — Dec 20–26
    [
        { displayName: 'Christmas Day Challenge', scoringRules: { kind: 'rings' } },
        { displayName: 'North Pole Laps', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // Week 86 — Dec 27–Jan 2
    [
        { displayName: "New Year's Eve Sweat", scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'Countdown to Fitness', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
    ],
    // ── January 2028 ──────────────────────────────────────────────────────
    // Week 87 — Jan 3–9
    [
        { displayName: 'Resolution Redemption', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'New Year New Rings', scoringRules: { kind: 'rings' } },
    ],
    // Week 88 — Jan 10–16
    [
        { displayName: 'January Jackpot', scoringRules: { kind: 'workouts', metric: 'calories' } },
        { displayName: 'Frozen Tundra Treks', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 89 — Jan 17–23
    [
        { displayName: 'MLK Day Motivation', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
        { displayName: 'Midwinter Hustle', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // Week 90 — Jan 24–30
    [
        { displayName: 'January Finale', scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'Sub-Zero Ambition', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
    ],
    // ── February 2028 ─────────────────────────────────────────────────────
    // Week 91 — Jan 31–Feb 6
    [
        { displayName: 'February Fuel Up', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: 'Groundhog Gains', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
    ],
    // Week 92 — Feb 7–13
    [
        { displayName: 'Cupid Cardio', scoringRules: { kind: 'workouts', metric: 'calories' } },
        { displayName: 'Sweetheart Steps', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 93 — Feb 14–20
    [
        { displayName: "Valentine's Vitality", scoringRules: { kind: 'rings' } },
        { displayName: 'Heart Health Sprint', scoringRules: { kind: 'workouts', metric: 'duration' } },
    ],
    // Week 94 — Feb 21–27
    [
        { displayName: 'Leap Year Laps', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
        { displayName: 'February Finale', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
    // ── March 2028 ────────────────────────────────────────────────────────
    // Week 95 — Feb 28–Mar 5
    [
        { displayName: 'March On!', scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'Spring Thaw Shuffle', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
    ],
    // Week 96 — Mar 6–12
    [
        { displayName: 'Daylight Saving Surge', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
        { displayName: 'Sunshine Sprint', scoringRules: { kind: 'workouts', metric: 'calories' } },
    ],
    // Week 97 — Mar 13–19
    [
        { displayName: 'Lucky Streaks', scoringRules: { kind: 'rings' } },
        { displayName: 'St. Paddy Pace', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
    // Week 98 — Mar 20–26
    [
        { displayName: 'Spring Equinox Effort', scoringRules: { kind: 'workouts', metric: 'duration' } },
        { displayName: 'First Day of Spring Fling', scoringRules: { kind: 'rings', includedRings: ['calories'] } },
    ],
    // ── April 2028 ────────────────────────────────────────────────────────
    // Week 99 — Mar 27–Apr 2
    [
        { displayName: 'April Fools Fitness', scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'Blossom Blitz', scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise'] } },
    ],
    // Week 100 — Apr 3–9
    [
        { displayName: 'Century Week Celebration', scoringRules: { kind: 'daily', metric: 'steps' } },
        { displayName: '100 Weeks Strong', scoringRules: { kind: 'workouts', metric: 'calories' } },
    ],
    // Week 101 — Apr 10–16
    [
        { displayName: 'Spring Shower Power', scoringRules: { kind: 'rings', includedRings: ['exercise', 'stand'] } },
        { displayName: 'April Miles', scoringRules: { kind: 'daily', metric: 'walkingRunningDistance' } },
    ],
    // Week 102 — Apr 17–23
    [
        { displayName: 'Earth Week Effort', scoringRules: { kind: 'workouts', metric: 'duration' } },
        { displayName: 'Trail Blazer', scoringRules: { kind: 'rings' } },
    ],
    // Week 103 — Apr 24–30
    [
        { displayName: 'Season Finale Burn', scoringRules: { kind: 'workouts', metric: 'distance' } },
        { displayName: 'Two Years of Fitness!', scoringRules: { kind: 'daily', metric: 'steps' } },
    ],
];

export function getWeekTemplates(monday: Date): WeeklyPair {
    const msPerWeek = 7 * 24 * 60 * 60 * 1000;
    const weekIndex = Math.round(
        (monday.getTime() - SCHEDULE_START_DATE.getTime()) / msPerWeek
    );
    if (weekIndex < 0 || weekIndex >= WEEKLY_SCHEDULE.length) {
        return [
            { displayName: 'All-Rings Challenge', scoringRules: { kind: 'rings' } },
            { displayName: 'Step It Up', scoringRules: { kind: 'daily', metric: 'steps' } },
        ];
    }
    return WEEKLY_SCHEDULE[weekIndex];
}
