import * as TestSQL from '../../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../../testUtilities/testAuthUtilities';
import { convertUserIdToBuffer, convertBufferToUserId } from '../../../utilities/userHelpers';
import FWFErrorCodes from '../../../utilities/enums/FWFErrorCodes';

/*
    Tests the /competitions route for creating a new competition
*/

// The userId that will be created in the database during the test setup
const testUserId = Math.random().toString().slice(2, 8);

// Data created during the tests that needs to be cleaned up after
// We don't want to drop all data in the database because tests may be running in parallel and we don't want to interfere with them
var usersToCleanup: string[] = [];
var competitionsToCleanup: string[] = [];

beforeEach(async () => {
    try {
        await TestSQL.createUser({
            userId: convertUserIdToBuffer(testUserId),
            firstName: 'Test',
            maxActiveCompetitions: 10,
            isPro: false,
            createdDate: new Date()
        });
        usersToCleanup.push(testUserId);
    } catch (error) {
        // Handle the error here
        console.log('Test setup failed: ' + error);
        throw error;
    }
});

afterEach(async () => {
    await Promise.all(usersToCleanup.map(userId => TestSQL.clearDataForUser({ userId: convertUserIdToBuffer(userId) })));
    await Promise.all(competitionsToCleanup.map(competitionId => TestSQL.clearDataForCompetition({ competitionId })));

    usersToCleanup = [];
    competitionsToCleanup = [];
});

test('Create competition happy path', async () => {
    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        displayName: 'Test Competition',
        ianaTimezone: 'America/New_York'
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);

    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('competition_id');
    expect(response.data).toHaveProperty('accessCode');
    
    const createdCompetitionId: string = response.data.competition_id;
    competitionsToCleanup.push(createdCompetitionId);

    // Validate that the authenticated user was marked as the admin of the new competition
    const createdCompetitions = await TestSQL.getCompetition({ competitionId: createdCompetitionId });
    expect(createdCompetitions).toHaveLength(1);

    const createdCompetition = createdCompetitions[0];
    expect(createdCompetition.admin_user_id).toEqual(convertUserIdToBuffer(testUserId));
    expect(createdCompetition.display_name).toEqual(competitionInfo.displayName);
    expect(createdCompetition.start_date.getUTCDate()).toEqual(competitionInfo.startDate.getUTCDate());
    expect(createdCompetition.end_date.getUTCDate()).toEqual(competitionInfo.endDate.getUTCDate());
    expect(createdCompetition.iana_timezone).toEqual(competitionInfo.ianaTimezone);
    expect(createdCompetition.access_token).toEqual(response.data.accessCode);

    // Validate that the authenticated user was added to the competition
    const competitionUsers = await TestSQL.getUsersInCompetition({ competitionId: createdCompetitionId });
    expect(competitionUsers).toHaveLength(1);
    expect(convertBufferToUserId(competitionUsers[0].user_id)).toBe(testUserId);
});

test('Create competition missing access token', async () => {
    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        displayName: 'Test Competition',
        ianaTimezone: 'America/New_York'
    };

    // Make the request with no access token
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo);
    
    // The auth middleware will treat the missing AT as an invalid client request
    expect(response.status).toBe(400);
});

test('Create competition missing start date', async () => {
    const now = new Date();
    const competitionInfo = {
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        displayName: 'Test Competition',
        ianaTimezone: 'America/New_York'
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Invalid date format');
});

test('Create competition missing end date', async () => {
    const now = new Date();
    const competitionInfo = {
        startDate: now,
        displayName: 'Test Competition',
        ianaTimezone: 'America/New_York'
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Invalid date format');
});

test('Create competition missing display name', async () => {
    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        ianaTimezone: 'America/New_York'
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Create competition missing timezone', async () => {
    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        displayName: 'Test Competition'
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Create competition invalid timezone', async () => {
    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        displayName: 'Test Competition',
        ianaTimezone: 'Invalid/Timezone'
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('not in list of valid timezones');
});


test('Create competition end date before start date', async () => {
    const now = new Date();
    const competitionInfo = {
        startDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 2), // The competition starts in 2 days
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24), // The competition ends in 1 day
        displayName: 'Test Competition',
        ianaTimezone: 'America/New_York'
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('End date was not valid');
});

test('Create competition end date in the past', async () => {
    const competitionInfo = {
        startDate: new Date('2020-01-01'),
        endDate: new Date('2020-01-02'),
        displayName: 'Test Competition',
        ianaTimezone: 'America/New_York'
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('End date must be in the future');
});

test('Create competition competition length too long', async () => {
    // Competitions may only last a maximum of 30 days
    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 60), // 60 days from now
        displayName: 'Test Competition',
        ianaTimezone: 'America/New_York'
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('End date was not valid');
});

test('Create competition too many active competitions', async () => {
    // Create a new user that is only allowed to have 1 active competition
    const oneCompUserId = Math.random().toString().slice(2, 8);
    usersToCleanup.push(oneCompUserId);

    await TestSQL.createUser({
        userId: convertUserIdToBuffer(oneCompUserId),
        firstName: 'Test',
        maxActiveCompetitions: 1,
        isPro: false,
        createdDate: new Date()
    });

    // Create a competition. This one should succeed because the user is under the limit
    const now = new Date();
    const competitionInfo1 = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        displayName: 'Test Competition',
        ianaTimezone: 'America/New_York'
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(oneCompUserId);
    const response1 = await RequestUtilities.makePostRequest('competitions', competitionInfo1, accessToken);
    expect(response1.status).toBe(200);
    expect(response1.data).toHaveProperty('competition_id');
    const createdCompetitionId: string = response1.data.competition_id;
    competitionsToCleanup.push(createdCompetitionId);

    // Create a second competition. This one should fail because the user is at the limit
    const competitionInfo2 = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        displayName: 'Test Competition 2',
        ianaTimezone: 'America/New_York'
    };

    const response2 = await RequestUtilities.makePostRequest('competitions', competitionInfo2, accessToken);
    expect(response2.status).toBe(400);
    expect(response2.data.context).toContain('User is not eligible to join a new competition');
    expect(response2.data.custom_error_code).toEqual(FWFErrorCodes.CompetitionErrorCodes.TooManyActiveCompetitions);
});

test('Create competition: display name is too long', async () => {
    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        displayName: 'a'.repeat(300), // The limit is 255 characters
        ianaTimezone: 'America/New_York'
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Display name is too long');
});

/* ───────────────────────── Scoring rules ───────────────────────── */

test('Create competition: stores default rings rule as null when scoringRules omitted', async () => {
    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7),
        displayName: 'Default Rules Competition',
        ianaTimezone: 'America/New_York',
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);
    expect(response.status).toBe(200);
    const createdCompetitionId: string = response.data.competition_id;
    competitionsToCleanup.push(createdCompetitionId);

    const rows = await TestSQL.getCompetition({ competitionId: createdCompetitionId });
    expect(rows[0].scoring_rules).toBeNull();
});

test('Create competition: free user blocked from custom rule (workouts)', async () => {
    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7),
        displayName: 'Miles Competition',
        ianaTimezone: 'America/New_York',
        scoringRules: { kind: 'workouts', metric: 'distance', activityTypes: [37] },
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);
    expect(response.status).toBe(403);
    expect(response.data.custom_error_code).toEqual(FWFErrorCodes.SubscriptionErrorCodes.ProSubscriptionRequired);
});

test('Create competition: free user blocked from rings with minGoals', async () => {
    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7),
        displayName: 'Rings with min goals',
        ianaTimezone: 'America/New_York',
        scoringRules: { kind: 'rings', minGoals: { calories: 500 } },
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);
    expect(response.status).toBe(403);
});

test('Create competition: Pro user can create a workouts-distance competition', async () => {
    const proUserId = Math.random().toString().slice(2, 8);
    usersToCleanup.push(proUserId);
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(proUserId),
        firstName: 'Pro',
        maxActiveCompetitions: 10,
        isPro: true,
        createdDate: new Date(),
    });

    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7),
        displayName: 'Running Miles',
        ianaTimezone: 'America/New_York',
        scoringRules: { kind: 'workouts', metric: 'distance', activityTypes: [37] },
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(proUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);
    expect(response.status).toBe(200);
    const createdCompetitionId: string = response.data.competition_id;
    competitionsToCleanup.push(createdCompetitionId);

    const rows = await TestSQL.getCompetition({ competitionId: createdCompetitionId });
    expect(rows[0].scoring_rules).toEqual({ kind: 'workouts', metric: 'distance', activityTypes: [37] });
});

test('Create competition: invalid scoringRules shape rejected with 400', async () => {
    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7),
        displayName: 'Bad Rules',
        ianaTimezone: 'America/New_York',
        scoringRules: { kind: 'daily', metric: 'potato' },
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);
    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Invalid scoringRules');
});

test('Create competition: dailyCap exceeds 200 × included rings is rejected', async () => {
    const proUserId = Math.random().toString().slice(2, 8);
    usersToCleanup.push(proUserId);
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(proUserId),
        firstName: 'Pro',
        maxActiveCompetitions: 10,
        isPro: true,
        createdDate: new Date(),
    });

    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7),
        displayName: 'Crazy cap',
        ianaTimezone: 'America/New_York',
        scoringRules: { kind: 'rings', includedRings: ['calories'], dailyCap: 500 },
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(proUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);
    expect(response.status).toBe(400);
    expect(response.data.context).toContain('dailyCap');
});

test('Create competition: explicit full-set includedRings is NOT treated as custom (free user allowed)', async () => {
    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7),
        displayName: 'Explicit Full Rings',
        ianaTimezone: 'America/New_York',
        // Same shape as default — Pro gate must not fire.
        scoringRules: { kind: 'rings', includedRings: ['calories', 'exercise', 'stand'] },
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);
    expect(response.status).toBe(200);
    competitionsToCleanup.push(response.data.competition_id);
});

test('Create competition: non-integer dailyCap is rejected', async () => {
    const proUserId = Math.random().toString().slice(2, 8);
    usersToCleanup.push(proUserId);
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(proUserId),
        firstName: 'Pro',
        maxActiveCompetitions: 10,
        isPro: true,
        createdDate: new Date(),
    });

    const now = new Date();
    const competitionInfo = {
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7),
        displayName: 'Fractional Cap',
        ianaTimezone: 'America/New_York',
        scoringRules: { kind: 'rings', dailyCap: 599.5 },
    };

    const accessToken = await AuthUtilities.getAccessTokenForUser(proUserId);
    const response = await RequestUtilities.makePostRequest('competitions', competitionInfo, accessToken);
    expect(response.status).toBe(400);
    expect(response.data.context).toContain('dailyCap');
});