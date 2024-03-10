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
const testUserName = 'Test User';

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

test('Get competition detail: user is member of competition', async () => {
    const now = new Date();
    const competitionAccessToken = 'CompetitionsTestToken';
    const competitionId = uuid();
    const competitionInfo = {
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Test Competition',
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        competitionId: competitionId,
        accessToken: competitionAccessToken,
        ianaTimezone: 'America/New_York',
    };
    await TestSQL.createCompetition(competitionInfo);
    competitionsToCleanup.push(competitionInfo.competitionId);

    await TestSQL.addUserToCompetition({ userId: convertUserIdToBuffer(testUserId), competitionId: competitionInfo.competitionId });

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest(`competitions/description`, {
            competitionId: competitionId,
            competitionAccessToken: competitionAccessToken
        },
        accessToken);

    // Expect a success code with the competition details
    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('competitionName', competitionInfo.displayName);
    expect(response.data).toHaveProperty('competitionStart');
    expect(new Date(response.data.competitionStart).getUTCDate()).toBe(competitionInfo.startDate.getDate());
    expect(response.data).toHaveProperty('competitionEnd');
    expect(new Date(response.data.competitionEnd).getUTCDate()).toBe(competitionInfo.endDate.getDate());
    expect(response.data).toHaveProperty('adminName', testUserName);
    expect(response.data).toHaveProperty('numMembers', 1); // Expect the competition to only have 1 member (the admin)
});

test('Get competition detail: user is not member of competition', async () => {
    const now = new Date();
    const competitionAccessToken = 'CompetitionsTestToken';
    const competitionId = uuid();
    const competitionInfo = {
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Test Competition',
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        competitionId: competitionId,
        accessToken: competitionAccessToken,
        ianaTimezone: 'America/New_York',
    };
    await TestSQL.createCompetition(competitionInfo);
    competitionsToCleanup.push(competitionInfo.competitionId);

    // Add the main test user to the competition
    await TestSQL.addUserToCompetition({ userId: convertUserIdToBuffer(testUserId), competitionId: competitionInfo.competitionId });

    // Create a user that is not a member of the competition
    const otherUserId = Math.random().toString().slice(2, 8);
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(otherUserId),
        firstName: 'Other',
        lastName: 'User',
        maxActiveCompetitions: 10,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(otherUserId);

    // Send the description request as the other user
    const accessToken = await AuthUtilities.getAccessTokenForUser(otherUserId);
    const response = await RequestUtilities.makePostRequest(`competitions/description`, {
            competitionId: competitionId,
            competitionAccessToken: competitionAccessToken
        },
        accessToken);

    // Expect a success code with the competition details
    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('competitionName', competitionInfo.displayName);
    expect(response.data).toHaveProperty('competitionStart');
    expect(new Date(response.data.competitionStart).getUTCDate()).toBe(competitionInfo.startDate.getDate());
    expect(response.data).toHaveProperty('competitionEnd');
    expect(new Date(response.data.competitionEnd).getUTCDate()).toBe(competitionInfo.endDate.getDate());
    expect(response.data).toHaveProperty('adminName', testUserName);
    expect(response.data).toHaveProperty('numMembers', 1); // Expect the competition to only have 1 member (the admin)
});

test('Get competition detail: multiple users in competition', async () => {
    const now = new Date();
    const competitionAccessToken = 'CompetitionsTestToken';
    const competitionId = uuid();
    const competitionInfo = {
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Test Competition',
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        competitionId: competitionId,
        accessToken: competitionAccessToken,
        ianaTimezone: 'America/New_York',
    };
    await TestSQL.createCompetition(competitionInfo);
    competitionsToCleanup.push(competitionInfo.competitionId);

    // Create a second test user
    const otherUserId = Math.random().toString().slice(2, 8);
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(otherUserId),
        firstName: 'Other',
        lastName: 'User',
        maxActiveCompetitions: 10,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(otherUserId);

    // Add the main test user to the competition
    await Promise.all([
        TestSQL.addUserToCompetition({ userId: convertUserIdToBuffer(testUserId), competitionId: competitionInfo.competitionId }),
        TestSQL.addUserToCompetition({ userId: convertUserIdToBuffer(otherUserId), competitionId: competitionInfo.competitionId })
    ]);

    // Send the description request as the other user
    const accessToken = await AuthUtilities.getAccessTokenForUser(otherUserId);
    const response = await RequestUtilities.makePostRequest(`competitions/description`, {
            competitionId: competitionId,
            competitionAccessToken: competitionAccessToken
        },
        accessToken);

    // Expect a success code with the competition details
    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('competitionName', competitionInfo.displayName);
    expect(response.data).toHaveProperty('competitionStart');
    expect(new Date(response.data.competitionStart).getUTCDate()).toBe(competitionInfo.startDate.getDate());
    expect(response.data).toHaveProperty('competitionEnd');
    expect(new Date(response.data.competitionEnd).getUTCDate()).toBe(competitionInfo.endDate.getDate());
    expect(response.data).toHaveProperty('adminName', testUserName);
    expect(response.data).toHaveProperty('numMembers', 2); // Expect the competition to have two members
});

test('Get competition detail: competition does not exist', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest(`competitions/description`, {
            competitionId: uuid(),
            competitionAccessToken: 'CompetitionsTestToken'
        },
        accessToken);

    // Expect a 404 error
    expect(response.status).toBe(404);
});

test('Get competition detail: competition access token is incorrect', async () => {
    const now = new Date();
    const competitionAccessToken = 'CompetitionsTestToken';
    const competitionId = uuid();
    const competitionInfo = {
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Test Competition',
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        competitionId: competitionId,
        accessToken: competitionAccessToken,
        ianaTimezone: 'America/New_York',
    };
    await TestSQL.createCompetition(competitionInfo);
    competitionsToCleanup.push(competitionInfo.competitionId);

    // Add the main test user to the competition
    await TestSQL.addUserToCompetition({ userId: convertUserIdToBuffer(testUserId), competitionId: competitionInfo.competitionId });

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest(`competitions/description`, {
            competitionId: competitionId,
            competitionAccessToken: 'IncorrectToken'
        },
        accessToken);

    // Expect a 404 error because the token is incorrect
    expect(response.status).toBe(404);
});

test('Get competition detail: user is not authenticated', async () => {
    const now = new Date();
    const competitionAccessToken = 'CompetitionsTestToken';
    const competitionId = uuid();
    const competitionInfo = {
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Test Competition',
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        competitionId: competitionId,
        accessToken: competitionAccessToken,
        ianaTimezone: 'America/New_York',
    };
    await TestSQL.createCompetition(competitionInfo);
    competitionsToCleanup.push(competitionInfo.competitionId);

    // Add the main test user to the competition
    await TestSQL.addUserToCompetition({ userId: convertUserIdToBuffer(testUserId), competitionId: competitionInfo.competitionId });

    // No access token on the request
    const response = await RequestUtilities.makePostRequest(`competitions/description`, {
            competitionId: competitionId,
            competitionAccessToken: competitionAccessToken
        });

    // Expect a 400 error because the user is not authenticated
    expect(response.status).toBe(400);
});

test('Get competition detail: missing competitionId', async () => {
    const now = new Date();
    const competitionAccessToken = 'CompetitionsTestToken';
    const competitionId = uuid();
    const competitionInfo = {
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Test Competition',
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        competitionId: competitionId,
        accessToken: competitionAccessToken,
        ianaTimezone: 'America/New_York',
    };
    await TestSQL.createCompetition(competitionInfo);
    competitionsToCleanup.push(competitionInfo.competitionId);

    // Add the main test user to the competition
    await TestSQL.addUserToCompetition({ userId: convertUserIdToBuffer(testUserId), competitionId: competitionInfo.competitionId });

    // Missing competitionId on the request
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest(`competitions/description`, {
            competitionAccessToken: 'CompetitionsTestToken'
        },
        accessToken);

    // Expect a 400 error because the competitionId is missing
    expect(response.status).toBe(400);
});

test('Get competition detail: missing competitionAccessToken', async () => {
    const now = new Date();
    const competitionAccessToken = 'CompetitionsTestToken';
    const competitionId = uuid();
    const competitionInfo = {
        adminUserId: convertUserIdToBuffer(testUserId),
        displayName: 'Test Competition',
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        competitionId: competitionId,
        accessToken: competitionAccessToken,
        ianaTimezone: 'America/New_York',
    };
    await TestSQL.createCompetition(competitionInfo);
    competitionsToCleanup.push(competitionInfo.competitionId);

    // Add the main test user to the competition
    await TestSQL.addUserToCompetition({ userId: convertUserIdToBuffer(testUserId), competitionId: competitionInfo.competitionId });

    // Missing competitionAccessToken on the request
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest(`competitions/description`, {
            competitionId
        },
        accessToken);

    // Expect a 400 error because the competitionAccessToken is missing
    expect(response.status).toBe(400);
});