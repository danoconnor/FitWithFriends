import * as TestSQL from '../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../testUtilities/testAuthUtilities';
import { convertUserIdToBuffer } from '../../utilities/userHelpers';
import PushNotificationPlatform from '../../utilities/PushNotificationPlatform';
import { v4 as uuid } from 'uuid';

/*
    Tests the /pushNotifications routes
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
        // Handle the error here
        console.log('Test setup failed: ' + error);
        throw error;
    }
});

afterEach(async () => {
    await TestSQL.clearDataForUser({ userId: convertUserIdToBuffer(testUserId) });
});

test('Register: happy path', async () => {
    const pushToken = '1234';
    const platform = PushNotificationPlatform.iOS;
    const appInstallId = uuid();

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const resposne = await RequestUtilities.makePostRequest('pushNotifications/register', {
        pushToken,
        platform,
        appInstallId
    }, accessToken);

    expect(resposne.status).toBe(200);

    // Check the database to make sure that the push token was saved
    const pushTokens = await TestSQL.getPushTokenForUser({ userId: convertUserIdToBuffer(testUserId) });
    expect(pushTokens.length).toBe(1);
    expect(pushTokens[0].push_token).toBe(pushToken);
    expect(pushTokens[0].platform).toBe(platform);
    expect(pushTokens[0].app_install_id).toBe(appInstallId);
});

test('Register: update existing push token', async () => {
    const pushToken = '1234';
    const platform = PushNotificationPlatform.iOS;
    const appInstallId = uuid();

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const resposne = await RequestUtilities.makePostRequest('pushNotifications/register', {
        pushToken,
        platform,
        appInstallId
    }, accessToken);

    expect(resposne.status).toBe(200);

    // Register a new push token for the same user/appInstallId
    const newPushToken = '5678';
    const newResponse = await RequestUtilities.makePostRequest('pushNotifications/register', {
        pushToken: newPushToken,
        platform,
        appInstallId
    }, accessToken);

    expect(newResponse.status).toBe(200);

    // Validate that the database has the new push token
    const pushTokens = await TestSQL.getPushTokenForUser({ userId: convertUserIdToBuffer(testUserId) });
    expect(pushTokens.length).toBe(1);
    expect(pushTokens[0].push_token).toBe(newPushToken);
    expect(pushTokens[0].platform).toBe(platform);
    expect(pushTokens[0].app_install_id).toBe(appInstallId);
});

test('Register: push tokens for multiple app intsallations', async () => {
    const platform = PushNotificationPlatform.iOS;
    const pushToken1 = '1234';
    const appInstallId1 = uuid();

    const pushToken2 = '5678';
    const appInstallId2 = uuid();

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response1 = await RequestUtilities.makePostRequest('pushNotifications/register', {
        pushToken: pushToken1,
        platform,
        appInstallId: appInstallId1
    }, accessToken);

    expect(response1.status).toBe(200);

    const response2 = await RequestUtilities.makePostRequest('pushNotifications/register', {
        pushToken: pushToken2,
        platform,
        appInstallId: appInstallId2
    }, accessToken);

    expect(response2.status).toBe(200);

    // Validate that both push tokens are in the database
    const pushTokens = await TestSQL.getPushTokenForUser({ userId: convertUserIdToBuffer(testUserId) });
    expect(pushTokens.length).toBe(2);

    const pushToken1Result = pushTokens.find(token => token.app_install_id === appInstallId1);
    expect(pushToken1Result).toBeDefined();
    expect(pushToken1Result.push_token).toBe(pushToken1);
    expect(pushToken1Result.platform).toBe(platform);
    
    const pushToken2Result = pushTokens.find(token => token.app_install_id === appInstallId2);
    expect(pushToken2Result).toBeDefined();
    expect(pushToken2Result.push_token).toBe(pushToken2);
    expect(pushToken2Result.platform).toBe(platform);
});

test('Register: missing push token', async () => {
    const platform = PushNotificationPlatform.iOS;
    const appInstallId = uuid();

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('pushNotifications/register', {
        platform,
        appInstallId
    }, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Register: missing platform', async () => {
    const pushToken = '1234';
    const appInstallId = uuid();

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('pushNotifications/register', {
        appInstallId,
        pushToken
    }, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Register: missing app install id', async () => {
    const platform = PushNotificationPlatform.iOS;
    const pushToken = '1234';

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('pushNotifications/register', {
        platform,
        pushToken
    }, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Register: invalid app install id', async () => {
    const platform = PushNotificationPlatform.iOS;
    const pushToken = '1234';
    const appInstallId = 'invalid';

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('pushNotifications/register', {
        platform,
        pushToken,
        appInstallId
    }, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Invalid UUID');
});

test('Register: invalid platform', async () => {
    const platform = 999; // Invalid platform
    const pushToken = '1234';
    const appInstallId = uuid();

    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('pushNotifications/register', {
        platform,
        pushToken,
        appInstallId
    }, accessToken);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Invalid platform');
});

test('Register: missing access token', async () => {
    const response = await RequestUtilities.makePostRequest('pushNotifications/register', {
        platform: PushNotificationPlatform.iOS,
        pushToken: '1234',
        appInstallId: uuid()
    });

    // The auth middleware treats a missing token as a bad request
    expect(response.status).toBe(400);
});