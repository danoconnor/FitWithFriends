import * as TestSQL from '../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../testUtilities/testAuthUtilities';
import { convertUserIdToBuffer } from '../../utilities/userHelpers';
import FWFErrorCodes from '../../utilities/enums/FWFErrorCodes';

/*
    Tests the /subscriptions routes
*/

// The userId that will be created in the database during the test setup
const testUserId = Math.random().toString().slice(2, 8);

// Data created during the tests that needs to be cleaned up after
// We don't want to drop all data in the database because tests may be running in parallel and we don't want to interfere with them
var usersToCleanup: string[] = [];

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

    usersToCleanup = [];
});

describe('POST /subscriptions/validateTransaction', () => {
    test('returns 400 when signedTransaction is missing', async () => {
        const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
        const response = await RequestUtilities.makePostRequest('subscriptions/validateTransaction', {}, accessToken);

        expect(response.status).toBe(400);
        expect(response.data.context).toContain('Missing required parameter');
    });

    test('returns 400 with InvalidTransaction error for malformed JWS', async () => {
        const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
        const response = await RequestUtilities.makePostRequest('subscriptions/validateTransaction', {
            signedTransaction: 'not-a-valid-jws'
        }, accessToken);

        expect(response.status).toBe(400);
        expect(response.data.custom_error_code).toBe(FWFErrorCodes.SubscriptionErrorCodes.InvalidTransaction);
    });

    test('returns 400 for unauthenticated request', async () => {
        // The auth middleware treats a missing token as a bad request
        const response = await RequestUtilities.makePostRequest('subscriptions/validateTransaction', {
            signedTransaction: 'not-a-valid-jws'
        });

        expect(response.status).toBe(400);
    });
});
