import * as TestSQL from '../../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../../testUtilities/testAuthUtilities';
import { convertUserIdToBuffer, convertBufferToUserId } from '../../../utilities/userHelpers';
import { v4 as uuid } from 'uuid';
import FWFErrorCodes from '../../../utilities/enums/FWFErrorCodes';

/*
    Tests the /competitions/join route for joining an existing competition
*/

// The userId that will be created in the database during the test setup
const testUserId = Math.random().toString().slice(2, 8);

// The competitionId that will be created in the database during the test setup
const testCompetitionId = uuid();
const testCompetitionAccessCode = '1234';

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

        // Create a second user who will be the admin of the competition
        const adminUserId = Math.random().toString().slice(2, 8);
        await TestSQL.createUser({
            userId: convertUserIdToBuffer(adminUserId),
            firstName: 'Admin',
            maxActiveCompetitions: 10,
            isPro: false,
            createdDate: new Date()
        });
        usersToCleanup.push(adminUserId);

        // Create a competition for the admin user
        const now = new Date();
        await TestSQL.createCompetition({
            competitionId: testCompetitionId,
            adminUserId: convertUserIdToBuffer(adminUserId),
            displayName: 'Test Competition',
            startDate: now,
            endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
            accessToken: testCompetitionAccessCode,
            ianaTimezone: 'America/New_York'
        });
        competitionsToCleanup.push(testCompetitionId);

        // Add the admin user to the competition
        await TestSQL.addUserToCompetition({
            competitionId: testCompetitionId,
            userId: convertUserIdToBuffer(adminUserId)
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

test('Join competition with valid access code', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions/join', {
        competitionId: testCompetitionId,
        accessToken: testCompetitionAccessCode
    }, accessToken);

    expect(response.status).toBe(200);
});

test('Join competition with invalid access code', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions/join', {
        competitionId: testCompetitionId,
        accessToken: 'not the right access code'
    }, accessToken);

    // We expect a 404 because the access code is invalid
    expect(response.status).toBe(404);
});

test('Join competition with missing access code', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);

    // Missing the access code in the request body
    const response = await RequestUtilities.makePostRequest('competitions/join', {
        competitionId: testCompetitionId,
    }, accessToken);

    // We expect a 404 because the access code is invalid
    expect(response.status).toBe(400);
});

test('Join competition with invalid competitionId', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions/join', {
        competitionId: uuid(), // A competition that doesn't exist
        accessToken: testCompetitionAccessCode
    }, accessToken);

    // We expect a 404 because the competitionId is invalid
    expect(response.status).toBe(404);
});

test('Join competition with missing competitionId', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);

    // Missing the competitionId in the request body
    const response = await RequestUtilities.makePostRequest('competitions/join', {
        accessToken: testCompetitionAccessCode
    }, accessToken);

    // We expect a 404 because the competitionId is invalid
    expect(response.status).toBe(400);
});

test('Join competition with user already in competition', async () => {
    // Manually add the test user to the competition
    await TestSQL.addUserToCompetition({
        competitionId: testCompetitionId,
        userId: convertUserIdToBuffer(testUserId)
    });

    // Make the join competition request
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('competitions/join', {
        competitionId: testCompetitionId,
        accessToken: testCompetitionAccessCode
    }, accessToken);

    // Should still get a successs response because the user is in the competition
    expect(response.status).toBe(200);
});

test('Join competition with user already at competition limit', async () => {
    // Create a new test user who can only join 1 competition
    const testUserId2 = Math.random().toString().slice(2, 8);
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(testUserId2),
        firstName: 'Test2',
        maxActiveCompetitions: 1,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(testUserId2);

    // Create a second test competition that is currently active
    const testCompetitionId2 = uuid();
    const now = new Date();
    await TestSQL.createCompetition({
        competitionId: testCompetitionId2,
        adminUserId: convertUserIdToBuffer(testUserId2),
        displayName: 'Test Competition 2',
        startDate: now,
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 7), // 7 days from now
        accessToken: '5678',
        ianaTimezone: 'America/New_York'
    });
    competitionsToCleanup.push(testCompetitionId2);

    // Add the new user to the second competition
    await TestSQL.addUserToCompetition({
        competitionId: testCompetitionId2,
        userId: convertUserIdToBuffer(testUserId2)
    });

    // Make the request to have testUser2 join the main test competition
    // It should be rejected because testUser2 is already at their max active competition limit
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId2);
    const response = await RequestUtilities.makePostRequest('competitions/join', {
        competitionId: testCompetitionId,
        accessToken: testCompetitionAccessCode
    }, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.custom_error_code).toBe(FWFErrorCodes.CompetitionErrorCodes.TooManyActiveCompetitions);
});

/** Validate that past competitions do not count towards the competition limit when joining a new competition */
test('Join competition with user who has joined past competitions', async () => {
    // Create a new test user who can only join 1 competition
    const testUserId2 = Math.random().toString().slice(2, 8);
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(testUserId2),
        firstName: 'Test2',
        maxActiveCompetitions: 1,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(testUserId2);

    // Create a second test competition that has already completed
    const testCompetitionId2 = uuid();
    const now = new Date();
    await TestSQL.createCompetition({
        competitionId: testCompetitionId2,
        adminUserId: convertUserIdToBuffer(testUserId2),
        displayName: 'Test Competition 2',
        startDate: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 7), // 7 days ago
        endDate: new Date(now.getTime() - 1000 * 60 * 60 * 24), // 1 day ago
        accessToken: '5678',
        ianaTimezone: 'America/New_York'
    });
    competitionsToCleanup.push(testCompetitionId2);

    // Add the new user to the second competition
    await TestSQL.addUserToCompetition({
        competitionId: testCompetitionId2,
        userId: convertUserIdToBuffer(testUserId2)
    });

    // Make the request to have testUser2 join the main test competition
    // It should be allowed because the testCompetition2 is in the past and should not count towards the competition limit
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId2);
    const response = await RequestUtilities.makePostRequest('competitions/join', {
        competitionId: testCompetitionId,
        accessToken: testCompetitionAccessCode
    }, accessToken);

    expect(response.status).toBe(200);
});