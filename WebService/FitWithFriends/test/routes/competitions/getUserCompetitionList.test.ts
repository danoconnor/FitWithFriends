import * as TestSQL from '../../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../../testUtilities/testAuthUtilities';
import { convertUserIdToBuffer, convertBufferToUserId } from '../../../utilities/userHelpers';
import { v4 as uuid } from 'uuid';

/*
    Tests the /competitions route for getting the user's competitions
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

test('Get user competitions: No competitions', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest('competitions', accessToken);

    // Expect a success code with an empty array
    expect(response.status).toBe(200);
    expect(response.data).toHaveLength(0);
});

test('Get user competitions: One competition', async () => {
    const competitionInfo = {
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Test Competition',
        startDate: new Date(),
        endDate: new Date(),
        competitionId: uuid(),
        accessToken: 'CompetitionsTestToken',
        ianaTimezone: 'America/New_York',
    };

    await createCompetitionWithUser(competitionInfo, testUserId);

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest('competitions', accessToken);

    // Expect a success code with an array containing the competitionIds that the user is a part of
    expect(response.status).toBe(200);
    expect(response.data).toHaveLength(1);
    expect(response.data[0]).toBe(competitionInfo.competitionId);
});

test('Get user competitions: Multiple competitions', async () => {
    const competitionInfo1 = {
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Test Competition 1',
        startDate: new Date(),
        endDate: new Date(),
        competitionId: uuid(),
        accessToken: 'CompetitionsTestToken1',
        ianaTimezone: 'America/New_York',
    };

    const competitionInfo2 = {
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Test Competition 2',
        startDate: new Date(),
        endDate: new Date(),
        competitionId: uuid(),
        accessToken: 'CompetitionsTestToken2',
        ianaTimezone: 'America/New_York',
    };

    const competitionInfo3 = {
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Test Competition 3',
        startDate: new Date(),
        endDate: new Date(),
        competitionId: uuid(),
        accessToken: 'CompetitionsTestToken3',
        ianaTimezone: 'America/New_York',
    };

    await Promise.all([
        createCompetitionWithUser(competitionInfo1, testUserId),
        createCompetitionWithUser(competitionInfo2, testUserId),
        createCompetitionWithUser(competitionInfo3, testUserId)
    ]);

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest('competitions', accessToken);

    // Expect a success code with an array containing the competitionIds that the user is a part of
    expect(response.status).toBe(200);
    expect(response.data).toHaveLength(3);
    expect(response.data).toContain(competitionInfo1.competitionId);
    expect(response.data).toContain(competitionInfo2.competitionId);
    expect(response.data).toContain(competitionInfo3.competitionId);
});

test('Get users competitions: only authenticated users competitions returned', async () => {
    // Setup a second user
    const secondUserId = '654321';
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(secondUserId),
        firstName: 'Test2',
        maxActiveCompetitions: 10,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(secondUserId);

    const competitionInfoOnlyUser1 = {
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Test Competition - only user 1',
        startDate: new Date(),
        endDate: new Date(),
        competitionId: uuid(),
        accessToken: 'CompetitionsTestToken1',
        ianaTimezone: 'America/New_York',
    };

    const competitionInfoOnlyUser2 = {
        adminUserId: convertUserIdToBuffer(secondUserId),
        displayName: 'Test Competition - only user 2',
        startDate: new Date(),
        endDate: new Date(),
        competitionId: uuid(),
        accessToken: 'CompetitionsTestToken2',
        ianaTimezone: 'America/New_York',
    };

    const competitionInfoBothUsers = {
        adminUserId: convertUserIdToBuffer(secondUserId),
        displayName: 'Test Competition - both users',
        startDate: new Date(),
        endDate: new Date(),
        competitionId: uuid(),
        accessToken: 'CompetitionsTestToken2',
        ianaTimezone: 'America/New_York',
    };

    await Promise.all([
        createCompetitionWithUser(competitionInfoOnlyUser1, testUserId),
        createCompetitionWithUser(competitionInfoOnlyUser2, secondUserId),
        // Create a competition that both users are a part of. We'll add the second user to this competition after it's created
        createCompetitionWithUser(competitionInfoBothUsers, testUserId),
    ]);

    await TestSQL.addUserToCompetition({
        competitionId: competitionInfoBothUsers.competitionId,
        userId: convertUserIdToBuffer(secondUserId)
    });

    // Make a request with our main test user. We should only get the two competitions that they are a part of
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions`, accessToken);

    expect(response.status).toBe(200);
    expect(response.data).toHaveLength(2);
    expect(response.data).toContain(competitionInfoOnlyUser1.competitionId);
    expect(response.data).toContain(competitionInfoBothUsers.competitionId);

    // Make a request with our second user. We should only get the two competitions that they are a part of
    const accessToken2 = await AuthUtilities.getAccessTokenForUser(secondUserId);
    const response2 = await RequestUtilities.makeGetRequest(`competitions`, accessToken2);

    expect(response2.status).toBe(200);
    expect(response2.data).toHaveLength(2);
    expect(response2.data).toContain(competitionInfoOnlyUser2.competitionId);
    expect(response2.data).toContain(competitionInfoBothUsers.competitionId);
});



// Helpers

async function createCompetitionWithUser(competitionInfo: TestSQL.ICreateCompetitionParams, userId: string) {
    // Create the competition
    await TestSQL.createCompetition(competitionInfo);
    
    competitionsToCleanup.push(competitionInfo.competitionId);

    // Add the user to the competition
    await TestSQL.addUserToCompetition({
        competitionId: competitionInfo.competitionId,
        userId: convertUserIdToBuffer(userId)
    });
}