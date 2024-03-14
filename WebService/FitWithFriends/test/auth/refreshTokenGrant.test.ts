import * as TestSQL from '../testUtilities/sql/testQueries.queries';
import { convertUserIdToBuffer } from '../../utilities/userHelpers';
import * as RequestUtilities from '../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../testUtilities/testAuthUtilities';

/*
    Tests the refresh token grant
*/

// The userId that will be created in the database during the test setup
const testUserId = Math.random().toString().slice(2, 8);

beforeEach(async () => {
    try {
        await TestSQL.createUser({
            userId: convertUserIdToBuffer(testUserId),
            firstName: 'Test',
            maxActiveCompetitions: 10,
            isPro: false,
            createdDate: new Date()
        });
    } catch (error) {
        console.log('Test setup failed: ' + error);
        throw error;
    }
});

afterEach(async () => {
    await TestSQL.clearDataForUser({ userId: convertUserIdToBuffer(testUserId) });
});


test('Happy path', async () => {
    // Create a refresh token in the database
    const refreshToken = 'SomeRefreshToken';
    let currentDate = new Date();
    await TestSQL.createRefreshToken({
        userId: convertUserIdToBuffer(testUserId),
        refreshToken,
        refreshTokenExpiresOn: new Date(currentDate.getTime() + 1000 * 60 * 60 * 24), // 1 days from now
        clientId: AuthUtilities.defaultClientId
    });

    // Request a new access token using the refresh token
    const response = await RequestUtilities.makePostRequest('oauth/token', {
        grant_type: 'refresh_token',
        refresh_token: refreshToken
    }, undefined, 'application/x-www-form-urlencoded');

    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('access_token');
});

test('Missing refreshToken', async () => {
    const response = await RequestUtilities.makePostRequest('oauth/token', {
        grant_type: 'refresh_token'
    }, undefined, 'application/x-www-form-urlencoded');

    expect(response.status).toBe(400);
    expect(response.data.error_description).toContain('Missing parameter');
    expect(response.data.error_description).toContain('refresh_token');
});

test('Nonexistent refreshToken', async () => {
    const response = await RequestUtilities.makePostRequest('oauth/token', {
        grant_type: 'refresh_token',
        refreshToken: '1234567890abcdef' // Does not exist in the database
    }, undefined, 'application/x-www-form-urlencoded');

    expect(response.status).toBe(400);
});

test('Expired refreshToken', async () => {
    // Create a refresh token in the database that has expired already
    const refreshToken = 'SomeRefreshToken';
    let currentDate = new Date();
    await TestSQL.createRefreshToken({
        userId: convertUserIdToBuffer(testUserId),
        refreshToken,
        refreshTokenExpiresOn: new Date(currentDate.getTime() - 1000 * 60 * 60 * 24), // 1 day in the past
        clientId: AuthUtilities.defaultClientId
    });

    // Attempt to request a new access token using the expired refresh token
    const response = await RequestUtilities.makePostRequest('oauth/token', {
        grant_type: 'refresh_token',
        refresh_token: refreshToken
    }, undefined, 'application/x-www-form-urlencoded');

    expect(response.status).toBe(400);
    expect(response.data.error_description).toContain('refresh token has expired');
});