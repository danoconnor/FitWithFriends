import * as RequestUtilities from '../testUtilities/testRequestUtilities';
import { humanReadableScoring } from '../../utilities/humanReadableScoring';

/*
    Redesign-specific tests for the /joinCompetition route. UA-detection,
    missing-params, and anonymous-fallback paths are covered by
    `joinCompetitionPage.test.ts`. This file focuses on:
    - the new metadata-aware happy-path render driven by GetCompetitionInviteDetails
    - the humanReadableScoring helper that powers the scoring chip
*/

// Seed data from WebService/SetupTestData.sql:
//   competition_id: 12345678-1234-1234-1234-123456789012
//   access_token:   TEST_ACCESS_TOKEN
//   admin:          Jordan Taylor
//   display_name:   Test Competition
const VALID_COMP_ID = '12345678-1234-1234-1234-123456789012';
const VALID_TOKEN = 'TEST_ACCESS_TOKEN';
const IOS_UA = 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15';

test('humanReadableScoring labels each rule kind', () => {
    expect(humanReadableScoring({ kind: 'rings' })).toBe('Activity rings');
    expect(humanReadableScoring({ kind: 'workouts', metric: 'duration' })).toContain('Tracked workouts');
    expect(humanReadableScoring({ kind: 'workouts', metric: 'calories' })).toContain('calories');
    expect(humanReadableScoring({ kind: 'workouts', metric: 'distance' })).toContain('distance');
    expect(humanReadableScoring({ kind: 'daily', metric: 'steps' })).toBe('Daily steps');
    expect(humanReadableScoring({ kind: 'daily', metric: 'walkingRunningDistance' })).toBe('Daily distance');
});

test('Valid token renders inviter + competition metadata into the page', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(
        `joinCompetition?competitionid=${VALID_COMP_ID}&competitiontoken=${VALID_TOKEN}`,
        IOS_UA
    );

    expect(response.status).toBe(200);
    const body: string = response.data;
    // Competition name surfaces
    expect(body).toContain('Test Competition');
    // Inviter first name surfaces
    expect(body).toContain('Jordan');
    // The scoring chip is wired up (NULL scoring_rules → legacy default → "Activity rings")
    expect(body).toContain('Activity rings');
    // The members pile renders the "Already in the group" caption
    expect(body).toContain('Already in the group');
    // Inviter row prefix
    expect(body).toContain("You've been invited");
});

test('Valid token + iOS UA: combines App Store CTA with the competition hero', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(
        `joinCompetition?competitionid=${VALID_COMP_ID}&competitiontoken=${VALID_TOKEN}`,
        IOS_UA
    );

    expect(response.status).toBe(200);
    expect(response.data).toContain('Test Competition');
    expect(response.data).toContain('Get FitWithFriends');
    expect(response.data).toContain('fitwithfriends://joinCompetition');
});
