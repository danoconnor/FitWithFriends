import * as TestSQL from '../../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../../testUtilities/testAuthUtilities';
import { convertUserIdToBuffer } from '../../../utilities/userHelpers';
import { v4 as uuid } from 'uuid';
import { ICreateCompetitionParams } from '../../../sql/competitions.queries';
import { CompetitionState } from '../../../utilities/enums/CompetitionState';
import { ICreateCompetitionWithStateParams } from '../../testUtilities/sql/testQueries.queries';

/*
    Tests the /competitions/:competitionId/overview route for getting the competition overview
*/

// The userId that will be created in the database during the test setup
// This user will be added to the test competition and marked as the admin
const testUserId = Math.random().toString().slice(2, 8);
const testUserName = 'Test User';

// The competitionId that will be created in the database during the test setup
const now = new Date();
const testCompetitionInfo: ICreateCompetitionParams = {
    competitionId: uuid(),
    adminUserId: convertUserIdToBuffer(testUserId),
    displayName: 'Test Competition',
    startDate: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 7), // 7 days ago
    endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
    accessToken: '1234',
    ianaTimezone: 'America/New_York'
};

// Data created during the tests that needs to be cleaned up after
// We don't want to drop all data in the database because tests may be running in parallel and we don't want to interfere with them
var usersToCleanup: string[] = [];
var competitionsToCleanup: string[] = [];

beforeEach(async () => {
    try {
        await TestSQL.createUser({
            userId: convertUserIdToBuffer(testUserId),
            firstName: testUserName.split(' ')[0],
            lastName: testUserName.split(' ')[1],
            maxActiveCompetitions: 10,
            isPro: false,
            createdDate: new Date()
        });
        usersToCleanup.push(testUserId);

        // Create a competition for the admin user
        const now = new Date();
        await TestSQL.createCompetition(testCompetitionInfo);
        competitionsToCleanup.push(testCompetitionInfo.competitionId);

        // Add the admin user to the competition
        await TestSQL.addUserToCompetition({
            competitionId: testCompetitionInfo.competitionId,
            userId: convertUserIdToBuffer(testUserId)
        });
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

test('Get competition overview: validate score calculation', async () => {
    // Create some activity data for the user
    const now = new Date();

    const expectedTodayScore = (100 * 250.0 / 500.0) + (100 * 30.0 / 60.0) + (100 * 6.0 / 12.0);
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: now,
        caloriesBurned: 250,
        caloriesGoal: 500,
        exerciseTime: 30,
        exerciseTimeGoal: 60,
        standTime: 6,
        standTimeGoal: 12,
    });

    const nowMinusOneDay = new Date(now.getTime() - 1000 * 60 * 60 * 24);
    const expectedNowMinusOneDayScore = (100 * 100.0 / 500.0) + (100 * 15.0 / 60.0) + (100 * 10.0 / 12.0);
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: nowMinusOneDay,
        caloriesBurned: 100,
        caloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 60,
        standTime: 10,
        standTimeGoal: 12,
    });

    const nowMinusTwoDays = new Date(now.getTime() - 1000 * 60 * 60 * 24 * 2);
    const expectedNowMinusTwoDaysScore = 600; // The maximum score per day is 600
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: nowMinusTwoDays,
        caloriesBurned: 1000,
        caloriesGoal: 500,
        exerciseTime: 300,
        exerciseTimeGoal: 60,
        standTime: 24,
        standTimeGoal: 12,
    });

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfo.competitionId}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(200);
    expect(response.data.competitionName).toBe(testCompetitionInfo.displayName);
    // expect(new Date(response.data.competitionStart).getUTCDate()).toBe(new Date(testCompetitionInfo.startDate).getUTCDate());
    // expect(new Date(response.data.competitionEnd).getUTCDate()).toBe(new Date(testCompetitionInfo.endDate).getUTCDate());
    expect(response.data.isCompetitionProcessingResults).toBe(false); // The competition is active and is not processing results

    expect(response.data).toHaveProperty('currentResults');
    expect(response.data.currentResults.length).toBe(1);
    
    const testUserResult = response.data.currentResults.find((r: any) => r.userId === testUserId);
    expect(testUserResult).not.toBeUndefined();
    expect(testUserResult.firstName).toBe(testUserName.split(' ')[0]);
    expect(testUserResult.lastName).toBe(testUserName.split(' ')[1]);
    expect(testUserResult.activityPoints).toBeCloseTo(expectedTodayScore + expectedNowMinusOneDayScore + expectedNowMinusTwoDaysScore);
    expect(testUserResult.pointsToday).toBeCloseTo(expectedTodayScore);
});

test('Get competition overview: validate score calculation with no activity data', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfo.competitionId}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('currentResults');
    expect(response.data.currentResults.length).toBe(1);
    
    const testUserResult = response.data.currentResults.find((r: any) => r.userId === testUserId);
    expect(testUserResult).not.toBeUndefined();
    expect(testUserResult.firstName).toBe(testUserName.split(' ')[0]);
    expect(testUserResult.lastName).toBe(testUserName.split(' ')[1]);
    expect(testUserResult.activityPoints).toBe(0);
    expect(testUserResult.pointsToday).toBe(0);
    expect(response.data.isPublic).toBe(false);
});

test('Get competition overview: validate score calculation with no activity data for today', async () => {
    // Create some activity data for the user
    const now = new Date();

    const expectedNowMinusOneDayScore = (100 * 100.0 / 500.0) + (100 * 15.0 / 60.0) + (100 * 10.0 / 12.0);
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: new Date(now.getTime() - 1000 * 60 * 60 * 24),
        caloriesBurned: 100,
        caloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 60,
        standTime: 10,
        standTimeGoal: 12,
    });

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfo.competitionId}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('currentResults');
    expect(response.data.currentResults.length).toBe(1);
    
    const testUserResult = response.data.currentResults.find((r: any) => r.userId === testUserId);
    expect(testUserResult).not.toBeUndefined();
    expect(testUserResult.firstName).toBe(testUserName.split(' ')[0]);
    expect(testUserResult.lastName).toBe(testUserName.split(' ')[1]);
    expect(testUserResult.activityPoints).toBeCloseTo(expectedNowMinusOneDayScore);
    expect(testUserResult.pointsToday).toBe(0);
});

test('Get competition overview: validate score calculation for multiple users', async () => {
    // Create another user and add them to the competition
    const testUserId2 = Math.random().toString().slice(2, 8);
    const testUserName2 = 'Test2 User2';
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(testUserId2),
        firstName: testUserName2.split(' ')[0],
        lastName: testUserName2.split(' ')[1],
        maxActiveCompetitions: 10,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(testUserId2);

    await TestSQL.addUserToCompetition({
        competitionId: testCompetitionInfo.competitionId,
        userId: convertUserIdToBuffer(testUserId2)
    });

    // Create some activity data for both users
    const now = new Date();

    const expectedTodayScoreUser1 = (100 * 250.0 / 500.0) + (100 * 30.0 / 60.0) + (100 * 6.0 / 12.0);
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: now,
        caloriesBurned: 250,
        caloriesGoal: 500,
        exerciseTime: 30,
        exerciseTimeGoal: 60,
        standTime: 6,
        standTimeGoal: 12,
    });

    // Activity data was reported, but the user had no activity
    const expectedTodayScoreUser2 = 0;
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId2),
        date: now,
        caloriesBurned: 0,
        caloriesGoal: 500,
        exerciseTime: 0,
        exerciseTimeGoal: 60,
        standTime: 0,
        standTimeGoal: 12,
    });

    const nowMinusOneDay = new Date(now.getTime() - 1000 * 60 * 60 * 24);
    const expectedNowMinusOneDayScoreUser1 = (100 * 100.0 / 500.0) + (100 * 15.0 / 60.0) + (100 * 10.0 / 12.0);
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: nowMinusOneDay,
        caloriesBurned: 100,
        caloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 60,
        standTime: 10,
        standTimeGoal: 12,
    });

    const expectedNowMinusOneDayScoreUser2 = (100 * 600.0 / 500.0) + (100 * 30.0 / 60.0) + (100 * 8.0 / 12.0);
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId2),
        date: nowMinusOneDay,
        caloriesBurned: 600,
        caloriesGoal: 500,
        exerciseTime: 30,
        exerciseTimeGoal: 60,
        standTime: 8,
        standTimeGoal: 12,
    });

    const nowMinusTwoDays = new Date(now.getTime() - 1000 * 60 * 60 * 24 * 2);
    const expectedNowMinusTwoDaysScoreUser1 = 600; // The maximum score per day is 600
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: nowMinusTwoDays,
        caloriesBurned: 1000,
        caloriesGoal: 500,
        exerciseTime: 300,
        exerciseTimeGoal: 60,
        standTime: 24,
        standTimeGoal: 12,
    });

    const expectedNowMinusTwoDaysScoreUser2 = (100 * 100.0 / 500.0) + (100 * 20.0 / 60.0) + (100 * 2.0 / 12.0);
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId2),
        date: nowMinusTwoDays,
        caloriesBurned: 100,
        caloriesGoal: 500,
        exerciseTime: 20,
        exerciseTimeGoal: 60,
        standTime: 2,
        standTimeGoal: 12,
    });

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfo.competitionId}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('currentResults');
    expect(response.data.currentResults.length).toBe(2);
    
    const testUser1Result = response.data.currentResults.find((r: any) => r.userId === testUserId);
    expect(testUser1Result).not.toBeUndefined();
    expect(testUser1Result.firstName).toBe(testUserName.split(' ')[0]);
    expect(testUser1Result.lastName).toBe(testUserName.split(' ')[1]);
    expect(testUser1Result.activityPoints).toBeCloseTo(expectedTodayScoreUser1 + expectedNowMinusOneDayScoreUser1 + expectedNowMinusTwoDaysScoreUser1);
    expect(testUser1Result.pointsToday).toBeCloseTo(expectedTodayScoreUser1);

    const testUser2Result = response.data.currentResults.find((r: any) => r.userId === testUserId2);
    expect(testUser2Result).not.toBeUndefined();
    expect(testUser2Result.firstName).toBe(testUserName2.split(' ')[0]);
    expect(testUser2Result.lastName).toBe(testUserName2.split(' ')[1]);
    expect(testUser2Result.activityPoints).toBeCloseTo(expectedTodayScoreUser2 + expectedNowMinusOneDayScoreUser2 + expectedNowMinusTwoDaysScoreUser2);
    expect(testUser2Result.pointsToday).toBeCloseTo(expectedTodayScoreUser2);
});

test('Get competition overview: no activity data for users', async () => {
    // Do not setup any activity data for the competition users

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfo.competitionId}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('currentResults');
    expect(response.data.currentResults.length).toBe(1);

    const testUserResult = response.data.currentResults.find((r: any) => r.userId === testUserId);
    expect(testUserResult).not.toBeUndefined();
    expect(testUserResult.firstName).toBe(testUserName.split(' ')[0]);
    expect(testUserResult.lastName).toBe(testUserName.split(' ')[1]);
    expect(testUserResult.activityPoints).toBe(0);
    expect(testUserResult.pointsToday).toBe(0);
});

test('Get competition overview: does not include users who are not in the competition', async () => {
    // Create a second user but do not add them to the competition
    const testUserId2 = Math.random().toString().slice(2, 8);
    const testUserName2 = 'Test2 User2';
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(testUserId2),
        firstName: testUserName2.split(' ')[0],
        lastName: testUserName2.split(' ')[1],
        maxActiveCompetitions: 10,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(testUserId2);

    // Create some activity data for the user
    const now = new Date();
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId2),
        date: now,
        caloriesBurned: 300,
        caloriesGoal: 500,
        exerciseTime: 30,
        exerciseTimeGoal: 60,
        standTime: 5,
        standTimeGoal: 12,
    });

    // Create some activity for the user in the competition
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: now,
        caloriesBurned: 100,
        caloriesGoal: 500,
        exerciseTime: 12,
        exerciseTimeGoal: 60,
        standTime: 7,
        standTimeGoal: 12,
    });

    // Get the competition overwiew and validate that it only includes results for the user in the competition
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfo.competitionId}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('currentResults');
    expect(response.data.currentResults.length).toBe(1);
    expect(response.data.currentResults.find((r: any) => r.userId === testUserId)).not.toBeUndefined();
    expect(response.data.currentResults.find((r: any) => r.userId === testUserId2)).toBeUndefined();
});

test('Get competition overview: user is not part of competition', async () => {
    // Create a second user but do not add them to the competition
    const testUserId2 = Math.random().toString().slice(2, 8);
    const testUserName2 = 'Test2 User2';
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(testUserId2),
        firstName: testUserName2.split(' ')[0],
        lastName: testUserName2.split(' ')[1],
        maxActiveCompetitions: 10,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(testUserId2);

    // Get the competition overwiew and validate that it only includes results for the user in the competition
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId2);
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfo.competitionId}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(401);
    expect(response.data.context).toContain('User is not a member of the competition');
});

test('Get competition overview: competition does not exist', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${uuid()}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(404);
    expect(response.data.context).toContain('Could not find competition info');
});

test('Get competition overview: invalid timezone', async () => {
    // Send the request with a timezone that is not in the list of known IANA timezones
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfo.competitionId}/overview?timezone=INVALIDTIMEZONE`, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Invalid timezone query param');
});

test('Get competition overview: returns isPublic true for public competition', async () => {
    // Create a public competition and add the test user to it
    const publicCompetitionId = uuid();
    const now = new Date();
    await TestSQL.createPublicCompetition({
        competitionId: publicCompetitionId,
        displayName: 'Public Test Competition',
        startDate: now,
        endDate: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000),
        adminUserId: convertUserIdToBuffer(testUserId),
        accessToken: 'unused',
        ianaTimezone: 'America/New_York'
    });
    competitionsToCleanup.push(publicCompetitionId);

    await TestSQL.addUserToCompetition({
        competitionId: publicCompetitionId,
        userId: convertUserIdToBuffer(testUserId)
    });

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${publicCompetitionId}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(200);
    expect(response.data.isPublic).toBe(true);
});

test('Get competition overview: missing access token', async () => {
    // Send a request without an access token
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfo.competitionId}/overview?timezone=America/New_York`);

    // The auth middleware treats the missing AT as a bad request
    expect(response.status).toBe(400);
});

test('Get competition overview: competition is processing results', async () => {
    // Create a competition that recently ended (within the past 24hrs, since that is how long we wait to process results)
    // Competition processing is based off UTC dates
    const now = new Date();
    const testCompetitionInfoProcessing: ICreateCompetitionWithStateParams = {
        competitionId: uuid(),
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Test Competition Processing Results',
        startDate: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 7).toUTCString(), // 7 days ago
        endDate: now.toUTCString(), // Ends now
        accessToken: '1234',
        ianaTimezone: 'America/New_York',
        state: CompetitionState.ProcessingResults
    };
    competitionsToCleanup.push(testCompetitionInfoProcessing.competitionId);

    await TestSQL.createCompetitionWithState(testCompetitionInfoProcessing);

    // Add the user to the competition
    await TestSQL.addUserToCompetition({
        competitionId: testCompetitionInfoProcessing.competitionId,
        userId: convertUserIdToBuffer(testUserId)
    });

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfoProcessing.competitionId}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(200);
    expect(response.data.competitionName).toBe(testCompetitionInfoProcessing.displayName);
    expect(new Date(response.data.competitionStart).getUTCDate()).toBe(new Date(testCompetitionInfoProcessing.startDate).getUTCDate());
    expect(new Date(response.data.competitionEnd).getUTCDate()).toBe(new Date(testCompetitionInfoProcessing.endDate).getUTCDate());
    expect(response.data.isCompetitionProcessingResults).toBe(true); // The competition has finished but is processing final results
});

test('Get competition overview: competition is archived', async () => {
    // Create a competition that has been archived with final points stored
    const now = new Date();
    const testCompetitionInfoArchived: ICreateCompetitionWithStateParams = {
        competitionId: uuid(),
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Test Competition Archived',
        startDate: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 14).toUTCString(), // 14 days ago
        endDate: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 7).toUTCString(), // 7 days ago
        accessToken: '5678',
        ianaTimezone: 'America/New_York',
        state: CompetitionState.Archived
    };
    competitionsToCleanup.push(testCompetitionInfoArchived.competitionId);

    await TestSQL.createCompetitionWithState(testCompetitionInfoArchived);

    // Add the user to the competition
    await TestSQL.addUserToCompetition({
        competitionId: testCompetitionInfoArchived.competitionId,
        userId: convertUserIdToBuffer(testUserId)
    });

    // Create activity data that should NOT be used for scoring (since competition is archived)
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 8), // 8 days ago (within competition range)
        caloriesBurned: 1000, // High values that would result in high scores
        caloriesGoal: 500,
        exerciseTime: 300,
        exerciseTimeGoal: 60,
        standTime: 24,
        standTimeGoal: 12,
    });

    // Set final points for the user in the archived competition (simulates the admin archiving process)
    const expectedFinalPoints = 450.5;
    await TestSQL.updateUserCompetitionFinalPoints({
        userId: convertUserIdToBuffer(testUserId),
        competitionId: testCompetitionInfoArchived.competitionId,
        finalPoints: expectedFinalPoints
    });
    
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfoArchived.competitionId}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(200);
    expect(response.data.competitionName).toBe(testCompetitionInfoArchived.displayName);
    expect(new Date(response.data.competitionStart).getUTCDate()).toBe(new Date(testCompetitionInfoArchived.startDate).getUTCDate());
    expect(new Date(response.data.competitionEnd).getUTCDate()).toBe(new Date(testCompetitionInfoArchived.endDate).getUTCDate());
    expect(response.data.isCompetitionProcessingResults).toBe(false); // Archived competitions are not processing results

    expect(response.data).toHaveProperty('currentResults');
    expect(response.data.currentResults.length).toBe(1);
    
    const testUserResult = response.data.currentResults.find((r: any) => r.userId === testUserId);
    expect(testUserResult).not.toBeUndefined();
    expect(testUserResult.firstName).toBe(testUserName.split(' ')[0]);
    expect(testUserResult.lastName).toBe(testUserName.split(' ')[1]);
    
    // For archived competitions, should return final_points instead of calculating from activity data
    // If it were calculating from activity data, the score would be 600 (max daily score)
    expect(testUserResult.activityPoints).toBe(expectedFinalPoints); // Should use stored final_points
    expect(testUserResult.pointsToday).toBe(0); // No points today for archived competitions
});

/* ───────────────────────── Scoring rules ───────────────────────── */

test('Get competition overview: default rule returns rings/points and rule object', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfo.competitionId}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(200);
    // Legacy competitions store NULL → response should fall back to the default rings rule.
    expect(response.data.scoringRules).toEqual({ kind: 'rings' });
    expect(response.data.scoringUnit).toBe('points');
});

test('Get competition overview: workouts-distance rule scores from workouts and reports meters', async () => {
    // Create a separate competition with the workouts-distance rule.
    const competitionId = uuid();
    const start = new Date(now.getTime() - 1000 * 60 * 60 * 24 * 3);
    const end = new Date(now.getTime() + 1000 * 60 * 60 * 24 * 3);
    await TestSQL.createCompetition({
        competitionId,
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Distance Comp',
        startDate: start,
        endDate: end,
        accessToken: 'wkt',
        ianaTimezone: 'America/New_York',
        scoringRules: { kind: 'workouts', metric: 'distance', activityTypes: [37] },
    });
    competitionsToCleanup.push(competitionId);
    await TestSQL.addUserToCompetition({ competitionId, userId: convertUserIdToBuffer(testUserId) });

    // Today: 5 mile run (workout_type 37 = walking, used in catalog as a stand-in)
    await TestSQL.insertWorkout({
        userId: convertUserIdToBuffer(testUserId),
        startDate: now,
        caloriesBurned: 500,
        workoutType: 37,
        duration: 1800,
        distance: 5,
        unit: 1, // miles
    });
    // Yesterday: 2000 m of the same activity type
    const yesterday = new Date(now.getTime() - 1000 * 60 * 60 * 24);
    await TestSQL.insertWorkout({
        userId: convertUserIdToBuffer(testUserId),
        startDate: yesterday,
        caloriesBurned: 200,
        workoutType: 37,
        duration: 900,
        distance: 2000,
        unit: 2, // meters
    });
    // Cycling workout (type 13) — should be filtered out by activityTypes.
    await TestSQL.insertWorkout({
        userId: convertUserIdToBuffer(testUserId),
        startDate: now,
        caloriesBurned: 600,
        workoutType: 13,
        duration: 3600,
        distance: 30000,
        unit: 2,
    });

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${competitionId}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(200);
    expect(response.data.scoringUnit).toBe('meters');
    expect(response.data.scoringRules).toMatchObject({ kind: 'workouts', metric: 'distance' });

    const userResult = response.data.currentResults.find((r: any) => r.userId === testUserId);
    expect(userResult).not.toBeUndefined();
    // 5 miles + 2000 m = 5*1609.344 + 2000 ≈ 10046.72 m. Cycling excluded.
    expect(userResult.activityPoints).toBeCloseTo(5 * 1609.344 + 2000, 1);
    expect(userResult.pointsToday).toBeCloseTo(5 * 1609.344, 1);
});

test('Get competition overview: daily steps rule reads step_count column', async () => {
    const competitionId = uuid();
    const start = new Date(now.getTime() - 1000 * 60 * 60 * 24 * 3);
    const end = new Date(now.getTime() + 1000 * 60 * 60 * 24 * 3);
    await TestSQL.createCompetition({
        competitionId,
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Step Challenge',
        startDate: start,
        endDate: end,
        accessToken: 'stp',
        ianaTimezone: 'America/New_York',
        scoringRules: { kind: 'daily', metric: 'steps' },
    });
    competitionsToCleanup.push(competitionId);
    await TestSQL.addUserToCompetition({ competitionId, userId: convertUserIdToBuffer(testUserId) });

    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: now,
        caloriesBurned: 0, caloriesGoal: 500,
        exerciseTime: 0, exerciseTimeGoal: 30,
        standTime: 0, standTimeGoal: 12,
        stepCount: 9000,
        distanceWalkingRunningMeters: 4000,
        flightsClimbed: 5,
    });
    const yesterday = new Date(now.getTime() - 1000 * 60 * 60 * 24);
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: yesterday,
        caloriesBurned: 0, caloriesGoal: 500,
        exerciseTime: 0, exerciseTimeGoal: 30,
        standTime: 0, standTimeGoal: 12,
        stepCount: 6500,
        distanceWalkingRunningMeters: 3000,
        flightsClimbed: 3,
    });

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${competitionId}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(200);
    expect(response.data.scoringUnit).toBe('steps');
    expect(response.data.scoringRules).toMatchObject({ kind: 'daily', metric: 'steps' });

    const userResult = response.data.currentResults.find((r: any) => r.userId === testUserId);
    expect(userResult.activityPoints).toBe(15500);
    expect(userResult.pointsToday).toBe(9000);
});

test('Get competition overview: rings rule with minGoal floors the per-ring percentage', async () => {
    const competitionId = uuid();
    const start = new Date(now.getTime() - 1000 * 60 * 60 * 24 * 3);
    const end = new Date(now.getTime() + 1000 * 60 * 60 * 24 * 3);
    await TestSQL.createCompetition({
        competitionId,
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Min-Goal Comp',
        startDate: start,
        endDate: end,
        accessToken: 'mg',
        ianaTimezone: 'America/New_York',
        scoringRules: { kind: 'rings', minGoals: { calories: 500 } },
    });
    competitionsToCleanup.push(competitionId);
    await TestSQL.addUserToCompetition({ competitionId, userId: convertUserIdToBuffer(testUserId) });

    // User set a trivial calorie goal of 1 to game the score, burned only 1 calorie.
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: now,
        caloriesBurned: 1, caloriesGoal: 1,
        exerciseTime: 0, exerciseTimeGoal: 30,
        standTime: 0, standTimeGoal: 12,
    });

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${competitionId}/overview?timezone=America/New_York`, accessToken);

    expect(response.status).toBe(200);
    const userResult = response.data.currentResults.find((r: any) => r.userId === testUserId);
    // With minGoal: 1/500 * 100 = 0.2 pts (legacy would have given 100).
    expect(userResult.activityPoints).toBeCloseTo(0.2, 5);
});