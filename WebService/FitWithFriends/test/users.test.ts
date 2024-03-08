import { convertUserIdToBuffer } from "../utilities/userHelpers";
import * as TestSQL from "./sql/testQueries.queries";
import * as RequestUtilities from "./testUtilities/testRequestUtilities";

beforeEach(async () => {
    try {
        await TestSQL.clearAllData();
    } catch (error) {
        // Handle the error here
        console.log('Test setup failed: ' + error);
        throw error;
    }
});

test('userFromAppleID happy path', async () => {
    // The ID we get from Apple has '.' chars in it, which are removed when we store it in the database
    const appleUserId = '002261.d372c8cb204940c02479ef472f717857.2341';
    const expectedUserId = appleUserId.replaceAll('.', '');

    const response = await RequestUtilities.makePostRequest('users/userFromAppleID', {
        userId: appleUserId,
        firstName: 'Test',
        lastName: 'User',
        idToken: 'some_token' // Local testing skips validating the Apple idToken
    });

    expect(response.status).toBe(200);

    // Validate that the user was created in the database
    const user = await TestSQL.getUser({ userId: convertUserIdToBuffer(expectedUserId) });
    expect(user.length).toBe(1);
});

test('userFromAppleID missing userId', async () => {
    const response = await RequestUtilities.makePostRequest('users/userFromAppleID', {
        firstName: 'Test',
        lastName: 'User',
        idToken: 'some_token'
    });

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('userFromAppleID missing firstName', async () => {
    const response = await RequestUtilities.makePostRequest('users/userFromAppleID', {
        userId: '002261.d372c8cb204940c02479ef472f717857.2341',
        lastName: 'User',
        idToken: 'some_token'
    });

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('userFromAppleID missing lastName', async () => {
    const response = await RequestUtilities.makePostRequest('users/userFromAppleID', {
        userId: '002261.d372c8cb204940c02479ef472f717857.2341',
        firstName: 'Test',
        idToken: 'some_token'
    });

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('userFromAppleID missing idToken', async () => {
    const response = await RequestUtilities.makePostRequest('users/userFromAppleID', {
        userId: '002261.d372c8cb204940c02479ef472f717857.2341',
        firstName: 'Test',
        lastName: 'User'
    });

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('userFromAppleID userId too long', async () => {
    const response = await RequestUtilities.makePostRequest('users/userFromAppleID', {
        userId: 'a'.repeat(256),
        firstName: 'Test',
        lastName: 'User',
        idToken: 'some_token'
    });

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Parameter too long');
});

test('userFromAppleID firstName too long', async () => {
    const response = await RequestUtilities.makePostRequest('users/userFromAppleID', {
        userId: '002261.d372c8cb204940c02479ef472f717857.2341',
        firstName: 'a'.repeat(256),
        lastName: 'User',
        idToken: 'some_token'
    });

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Parameter too long');
});

test('userFromAppleID lastName too long', async () => {
    const response = await RequestUtilities.makePostRequest('users/userFromAppleID', {
        userId: '002261.d372c8cb204940c02479ef472f717857.2341',
        firstName: 'Test',
        lastName: 'a'.repeat(256),
        idToken: 'some_token'
    });

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Parameter too long');
});

test('userFromAppleID idToken too long', async () => {
    const response = await RequestUtilities.makePostRequest('users/userFromAppleID', {
        userId: '002261.d372c8cb204940c02479ef472f717857.2341',
        firstName: 'Test',
        lastName: 'User',
        idToken: 'a'.repeat(256)
    });

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Parameter too long');
});