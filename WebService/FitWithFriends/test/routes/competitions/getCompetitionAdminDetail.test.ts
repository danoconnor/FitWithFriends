import * as TestSQL from '../../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../../testUtilities/testAuthUtilities';
import { convertUserIdToBuffer } from '../../../utilities/userHelpers';
import { v4 as uuid } from 'uuid';

/*
    Tests the /competitions/:competitionId/adminDetail route for getting the admin-only details of the competition
*/

// The userId that will be created in the database during the test setup
const adminUserId = Math.random().toString().slice(2, 8);

// The competitionId that will be created in the database during the test setup
// The competitionId that will be created in the database during the test setup
const now = new Date();
const testCompetitionInfo: TestSQL.ICreateCompetitionParams = {
    competitionId: uuid(),
    adminUserId: convertUserIdToBuffer(adminUserId),
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
            userId: convertUserIdToBuffer(adminUserId),
            firstName: 'Test',
            lastName: 'Admin',
            maxActiveCompetitions: 10,
            isPro: false,
            createdDate: new Date()
        });
        usersToCleanup.push(adminUserId);

        await TestSQL.createCompetition(testCompetitionInfo);
        competitionsToCleanup.push(testCompetitionInfo.competitionId);

        // Add the admin to the competition
        await TestSQL.addUserToCompetition({
            userId: convertUserIdToBuffer(adminUserId),
            competitionId: testCompetitionInfo.competitionId
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

test('Get admin detail: admin user makes request', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(adminUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfo.competitionId}/adminDetail`, accessToken);

    expect(response.status).toBe(200);
    expect(response.data).toEqual({
        competitionId: testCompetitionInfo.competitionId,
        competitionAccessToken: testCompetitionInfo.accessToken
    });
});

test('Get admin detail: non-admin user makes request', async () => {
    const nonAdminUserId = Math.random().toString().slice(2, 8);
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(nonAdminUserId),
        firstName: 'Test',
        lastName: 'NonAdmin',
        maxActiveCompetitions: 10,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(nonAdminUserId);

    const accessToken = await AuthUtilities.getAccessTokenForUser(nonAdminUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfo.competitionId}/adminDetail`, accessToken);

    expect(response.status).toBe(404);
    expect(response.data.context).toContain('Competition not found or user is not admin');
});

test('Get admin detial: missing access token', async () => {
    // Send the request with an access token
    const response = await RequestUtilities.makeGetRequest(`competitions/${testCompetitionInfo.competitionId}/adminDetail`);

    // The auth middleware treats a missing token as a bad request
    expect(response.status).toBe(400);
});

test('Get admin detail: invalid competitionId', async () => {
    // Make the request for a competition that doesn't exist
    const accessToken = await AuthUtilities.getAccessTokenForUser(adminUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${uuid()}/adminDetail`, accessToken);

    expect(response.status).toBe(404);
    expect(response.data.context).toContain('Competition not found or user is not admin');
});