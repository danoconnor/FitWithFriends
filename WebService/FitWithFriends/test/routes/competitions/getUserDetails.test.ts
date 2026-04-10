import * as TestSQL from '../../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../../testUtilities/testAuthUtilities';
import { convertUserIdToBuffer } from '../../../utilities/userHelpers';
import { v4 as uuid } from 'uuid';
import { ICreateCompetitionParams } from '../../../sql/competitions.queries';
import { CompetitionState } from '../../../utilities/enums/CompetitionState';
import { ICreateCompetitionWithStateParams } from '../../testUtilities/sql/testQueries.queries';

/*
    Tests the /competitions/:competitionId/userDetails/:userId route for getting a user's daily activity details
*/

const testUserId = Math.random().toString().slice(2, 8);
const testUserName = 'Test User';

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

        await TestSQL.createCompetition(testCompetitionInfo);
        competitionsToCleanup.push(testCompetitionInfo.competitionId);

        await TestSQL.addUserToCompetition({
            competitionId: testCompetitionInfo.competitionId,
            userId: convertUserIdToBuffer(testUserId)
        });
    } catch (error) {
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

test('Get user details: returns daily summaries with correct points', async () => {
    const now = new Date();

    // Insert 3 days of activity data
    const day1 = new Date(now.getTime() - 1000 * 60 * 60 * 24 * 2);
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: day1,
        caloriesBurned: 250,
        caloriesGoal: 500,
        exerciseTime: 30,
        exerciseTimeGoal: 60,
        standTime: 6,
        standTimeGoal: 12,
    });

    const day2 = new Date(now.getTime() - 1000 * 60 * 60 * 24);
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: day2,
        caloriesBurned: 400,
        caloriesGoal: 500,
        exerciseTime: 45,
        exerciseTimeGoal: 60,
        standTime: 10,
        standTimeGoal: 12,
    });

    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: now,
        caloriesBurned: 300,
        caloriesGoal: 500,
        exerciseTime: 20,
        exerciseTimeGoal: 60,
        standTime: 8,
        standTimeGoal: 12,
    });

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(
        `competitions/${testCompetitionInfo.competitionId}/userDetails/${testUserId}?timezone=America/New_York`,
        accessToken
    );

    expect(response.status).toBe(200);
    expect(response.data.userId).toBe(testUserId);
    expect(response.data.firstName).toBe('Test');
    expect(response.data.lastName).toBe('User');
    expect(response.data.competitionId).toBe(testCompetitionInfo.competitionId);
    expect(response.data.dailySummaries).toHaveLength(3);

    // Verify each daily summary has the expected fields and correct points
    for (const summary of response.data.dailySummaries) {
        expect(summary).toHaveProperty('date');
        expect(summary).toHaveProperty('caloriesBurned');
        expect(summary).toHaveProperty('caloriesGoal');
        expect(summary).toHaveProperty('exerciseTime');
        expect(summary).toHaveProperty('exerciseTimeGoal');
        expect(summary).toHaveProperty('standTime');
        expect(summary).toHaveProperty('standTimeGoal');
        expect(summary).toHaveProperty('points');
    }

    // Verify the points are correct for today's data (300/500*100 + 20/60*100 + 8/12*100)
    // Find the summary for today by matching the most recent entry (last inserted)
    const todaySummary = response.data.dailySummaries.find((s: any) => s.caloriesBurned === 300 && s.exerciseTime === 20 && s.standTime === 8);
    expect(todaySummary).not.toBeUndefined();
    const expectedTodayPoints = (300 / 500 * 100) + (20 / 60 * 100) + (8 / 12 * 100);
    expect(todaySummary.points).toBeCloseTo(expectedTodayPoints);
    expect(todaySummary.caloriesBurned).toBe(300);
    expect(todaySummary.caloriesGoal).toBe(500);
    expect(todaySummary.exerciseTime).toBe(20);
    expect(todaySummary.exerciseTimeGoal).toBe(60);
    expect(todaySummary.standTime).toBe(8);
    expect(todaySummary.standTimeGoal).toBe(12);
});

test('Get user details: no activity data returns empty dailySummaries', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(
        `competitions/${testCompetitionInfo.competitionId}/userDetails/${testUserId}?timezone=America/New_York`,
        accessToken
    );

    expect(response.status).toBe(200);
    expect(response.data.userId).toBe(testUserId);
    expect(response.data.dailySummaries).toHaveLength(0);
});

test('Get user details: points capped at 600 per day', async () => {
    const now = new Date();

    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: now,
        caloriesBurned: 1000,
        caloriesGoal: 500,
        exerciseTime: 300,
        exerciseTimeGoal: 60,
        standTime: 24,
        standTimeGoal: 12,
    });

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(
        `competitions/${testCompetitionInfo.competitionId}/userDetails/${testUserId}?timezone=America/New_York`,
        accessToken
    );

    expect(response.status).toBe(200);
    expect(response.data.dailySummaries).toHaveLength(1);
    expect(response.data.dailySummaries[0].points).toBe(600);
});

test('Get user details: only returns data within competition date range', async () => {
    const now = new Date();

    // Insert data WITHIN the competition date range (1 day ago - within 7 days ago to 7 days from now)
    const withinRange = new Date(now.getTime() - 1000 * 60 * 60 * 24);
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: withinRange,
        caloriesBurned: 300,
        caloriesGoal: 500,
        exerciseTime: 30,
        exerciseTimeGoal: 60,
        standTime: 8,
        standTimeGoal: 12,
    });

    // Insert data OUTSIDE the competition date range (30 days ago)
    const outsideRange = new Date(now.getTime() - 1000 * 60 * 60 * 24 * 30);
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: outsideRange,
        caloriesBurned: 999,
        caloriesGoal: 500,
        exerciseTime: 999,
        exerciseTimeGoal: 60,
        standTime: 99,
        standTimeGoal: 12,
    });

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(
        `competitions/${testCompetitionInfo.competitionId}/userDetails/${testUserId}?timezone=America/New_York`,
        accessToken
    );

    expect(response.status).toBe(200);
    // Only the data within the range should be returned
    expect(response.data.dailySummaries).toHaveLength(1);
    expect(response.data.dailySummaries[0].caloriesBurned).toBe(300);
});

test('Get user details: requesting user is not a competition member', async () => {
    // Create a second user who is NOT in the competition
    const testUserId2 = Math.random().toString().slice(2, 8);
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(testUserId2),
        firstName: 'NonMember',
        lastName: 'User',
        maxActiveCompetitions: 10,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(testUserId2);

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId2);
    const response = await RequestUtilities.makeGetRequest(
        `competitions/${testCompetitionInfo.competitionId}/userDetails/${testUserId}?timezone=America/New_York`,
        accessToken
    );

    expect(response.status).toBe(401);
    expect(response.data.context).toContain('User is not a member of the competition');
});

test('Get user details: target user is not a competition member', async () => {
    // Create a second user who is NOT in the competition
    const testUserId2 = Math.random().toString().slice(2, 8);
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(testUserId2),
        firstName: 'NonMember',
        lastName: 'User',
        maxActiveCompetitions: 10,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(testUserId2);

    // Request as the competition member, but target a non-member user
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(
        `competitions/${testCompetitionInfo.competitionId}/userDetails/${testUserId2}?timezone=America/New_York`,
        accessToken
    );

    expect(response.status).toBe(404);
    expect(response.data.context).toContain('Target user is not a member of the competition');
});

test('Get user details: competition does not exist', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(
        `competitions/${uuid()}/userDetails/${testUserId}?timezone=America/New_York`,
        accessToken
    );

    expect(response.status).toBe(404);
    expect(response.data.context).toContain('Could not find competition info');
});

test('Get user details: invalid timezone', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(
        `competitions/${testCompetitionInfo.competitionId}/userDetails/${testUserId}?timezone=INVALIDTIMEZONE`,
        accessToken
    );

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Invalid timezone query param');
});

test('Get user details: archived competition still returns daily activity data', async () => {
    const now = new Date();
    const archivedCompetitionInfo: ICreateCompetitionWithStateParams = {
        competitionId: uuid(),
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Archived Competition',
        startDate: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 14).toUTCString(), // 14 days ago
        endDate: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 7).toUTCString(), // 7 days ago
        accessToken: '5678',
        ianaTimezone: 'America/New_York',
        state: CompetitionState.Archived
    };
    competitionsToCleanup.push(archivedCompetitionInfo.competitionId);

    await TestSQL.createCompetitionWithState(archivedCompetitionInfo);
    await TestSQL.addUserToCompetition({
        competitionId: archivedCompetitionInfo.competitionId,
        userId: convertUserIdToBuffer(testUserId)
    });

    // Insert activity data within the archived competition date range
    const activityDate = new Date(now.getTime() - 1000 * 60 * 60 * 24 * 10); // 10 days ago (within 14-7 days ago range)
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId),
        date: activityDate,
        caloriesBurned: 400,
        caloriesGoal: 500,
        exerciseTime: 45,
        exerciseTimeGoal: 60,
        standTime: 10,
        standTimeGoal: 12,
    });

    // Set final points (like the archive process would)
    await TestSQL.updateUserCompetitionFinalPoints({
        userId: convertUserIdToBuffer(testUserId),
        competitionId: archivedCompetitionInfo.competitionId,
        finalPoints: 450.5
    });

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(
        `competitions/${archivedCompetitionInfo.competitionId}/userDetails/${testUserId}?timezone=America/New_York`,
        accessToken
    );

    expect(response.status).toBe(200);
    expect(response.data.dailySummaries).toHaveLength(1);

    // Should return the actual daily activity data, not just final_points
    const expectedPoints = (400 / 500 * 100) + (45 / 60 * 100) + (10 / 12 * 100);
    expect(response.data.dailySummaries[0].points).toBeCloseTo(expectedPoints);
    expect(response.data.dailySummaries[0].caloriesBurned).toBe(400);
});

test('Get user details: user can view another user in the same competition', async () => {
    // Create a second user and add them to the competition
    const testUserId2 = Math.random().toString().slice(2, 8);
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(testUserId2),
        firstName: 'Other',
        lastName: 'Member',
        maxActiveCompetitions: 10,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(testUserId2);

    await TestSQL.addUserToCompetition({
        competitionId: testCompetitionInfo.competitionId,
        userId: convertUserIdToBuffer(testUserId2)
    });

    // Insert activity data for user2
    const now = new Date();
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(testUserId2),
        date: now,
        caloriesBurned: 350,
        caloriesGoal: 400,
        exerciseTime: 25,
        exerciseTimeGoal: 30,
        standTime: 11,
        standTimeGoal: 12,
    });

    // User1 requests user2's details
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(
        `competitions/${testCompetitionInfo.competitionId}/userDetails/${testUserId2}?timezone=America/New_York`,
        accessToken
    );

    expect(response.status).toBe(200);
    expect(response.data.userId).toBe(testUserId2);
    expect(response.data.firstName).toBe('Other');
    expect(response.data.lastName).toBe('Member');
    expect(response.data.dailySummaries).toHaveLength(1);

    const expectedPoints = (350 / 400 * 100) + (25 / 30 * 100) + (11 / 12 * 100);
    expect(response.data.dailySummaries[0].points).toBeCloseTo(expectedPoints);
});
