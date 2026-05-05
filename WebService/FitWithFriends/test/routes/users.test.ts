import { convertUserIdToBuffer } from "../../utilities/userHelpers";
import * as TestSQL from "../testUtilities/sql/testQueries.queries";
import * as RequestUtilities from "../testUtilities/testRequestUtilities";
import * as AuthUtilities from "../testUtilities/testAuthUtilities";

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

// MARK: - DELETE /users/me

describe('DELETE /users/me', () => {
    const testUserId = Math.random().toString().slice(2, 10);
    const userIdBuffer = convertUserIdToBuffer(testUserId);

    beforeEach(async () => {
        await TestSQL.createUser({
            userId: userIdBuffer,
            firstName: 'Delete',
            maxActiveCompetitions: 1,
            isPro: false,
            createdDate: new Date()
        });
    });

    afterEach(async () => {
        await TestSQL.clearDataForUser({ userId: userIdBuffer });
    });

    test('happy path - deletes user and returns 200', async () => {
        const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);

        const response = await RequestUtilities.makeDeleteRequest('users/me', accessToken);

        expect(response.status).toBe(200);
        const user = await TestSQL.getUser({ userId: userIdBuffer });
        expect(user.length).toBe(0);
    });

    test('cascades - removes associated activity summaries', async () => {
        await TestSQL.insertActivitySummary({
            userId: userIdBuffer,
            date: new Date(),
            caloriesBurned: 300,
            caloriesGoal: 500,
            exerciseTime: 30,
            exerciseTimeGoal: 30,
            standTime: 10,
            standTimeGoal: 12
        });

        const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
        const response = await RequestUtilities.makeDeleteRequest('users/me', accessToken);

        expect(response.status).toBe(200);
        const summaries = await TestSQL.getActivitySummariesForUser({ userId: userIdBuffer });
        expect(summaries.length).toBe(0);
    });

    test('unauthenticated - returns 400 and does not delete user', async () => {
        const response = await RequestUtilities.makeDeleteRequest('users/me');

        expect(response.status).toBe(400);
        const user = await TestSQL.getUser({ userId: userIdBuffer });
        expect(user.length).toBe(1);
    });
});