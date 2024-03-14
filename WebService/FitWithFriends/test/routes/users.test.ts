import { convertUserIdToBuffer } from "../../utilities/userHelpers";
import * as TestSQL from "../testUtilities/sql/testQueries.queries";
import * as RequestUtilities from "../testUtilities/testRequestUtilities";

/*
    Tests the /users routes
*/

// The ID we get from Apple has '.' chars in it, which are removed when we store it in the database
const appleUserId = '002261.d372c8cb204940c02479ef472f717857.2341';
const expectedUserId = appleUserId.replaceAll('.', '');

afterEach(async () => {
    await TestSQL.clearDataForUser({ userId: convertUserIdToBuffer(expectedUserId) });
});

test('userFromAppleID happy path', async () => {
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
        userId: appleUserId,
        lastName: 'User',
        idToken: 'some_token'
    });

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('userFromAppleID missing lastName', async () => {
    const response = await RequestUtilities.makePostRequest('users/userFromAppleID', {
        userId: appleUserId,
        firstName: 'Test',
        idToken: 'some_token'
    });

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('userFromAppleID missing idToken', async () => {
    const response = await RequestUtilities.makePostRequest('users/userFromAppleID', {
        userId: appleUserId,
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
        userId: appleUserId,
        firstName: 'a'.repeat(256),
        lastName: 'User',
        idToken: 'some_token'
    });

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Parameter too long');
});

test('userFromAppleID lastName too long', async () => {
    const response = await RequestUtilities.makePostRequest('users/userFromAppleID', {
        userId: appleUserId,
        firstName: 'Test',
        lastName: 'a'.repeat(256),
        idToken: 'some_token'
    });

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Parameter too long');
});

test('userFromAppleID idToken too long', async () => {
    const response = await RequestUtilities.makePostRequest('users/userFromAppleID', {
        userId: appleUserId,
        firstName: 'Test',
        lastName: 'User',
        idToken: 'a'.repeat(256)
    });

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Parameter too long');
});