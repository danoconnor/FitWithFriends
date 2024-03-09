import axios from 'axios';
import * as TestSQL from '../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../testUtilities/testRequestUtilities';
import { convertUserIdToBuffer } from '../../utilities/userHelpers';

/*
    Tests the Apple idToken grant
*/

// The userId that will be created in the database during the test setup
const testUserId = '123456';

beforeEach(async () => {
    try {
        await TestSQL.clearAllData();
        await TestSQL.createUser({
            userId: convertUserIdToBuffer(testUserId),
            firstName: 'Test',
            maxActiveCompetitions: 10,
            isPro: false,
            createdDate: new Date()
        });
    } catch (error) {
        // Handle the error here
        console.log('Test setup failed: ' + error);
        throw error;
    }
});

test('Happy path', async () => {
    const response = await makeOauthRequest({
        grant_type: 'apple_id_token',
        idToken: 'test',
        userId: testUserId,
    });

    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('access_token');
    expect(response.data).toHaveProperty('refresh_token');
});

test('Missing userId', async () => {
    const response = await makeOauthRequest({
        grant_type: 'apple_id_token',
        idToken: 'test'
    });

    expect(response.status).toBe(400);
    expect(response.data.error_description).toContain('Missing parameter');
    expect(response.data.error_description).toContain('userId');
});

test('Nonexistent userId', async () => {
    const response = await makeOauthRequest({
        grant_type: 'apple_id_token',
        idToken: 'test',
        userId: '1234567890abcdef' // Does not exist in the database
    });

    expect(response.status).toBe(400);
    expect(response.data.error_description).toContain('User does not exist');
});

test('Missing idToken', async () => {
    const response = await makeOauthRequest({
        grant_type: 'apple_id_token',
        userId: testUserId
    });

    expect(response.status).toBe(400);
    expect(response.data.error_description).toContain('Missing parameter');
    expect(response.data.error_description).toContain('idToken');
});

async function makeOauthRequest(requestBody: any): Promise<axios.AxiosResponse<any, any>> {
    return await RequestUtilities.makePostRequest('oauth/token', requestBody, undefined, 'application/x-www-form-urlencoded');
}

