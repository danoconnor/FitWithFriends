import * as TestSQL from '../../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../../testUtilities/testAuthUtilities';
import { convertUserIdToBuffer } from '../../../utilities/userHelpers';
import { v4 as uuid } from 'uuid';
import FWFErrorCodes from '../../../utilities/enums/FWFErrorCodes';

/*
    Tests for the public competitions endpoints:
    - GET /competitions/public
    - POST /competitions/joinPublic
    - POST /admin/createPublicCompetition
*/

const testUserId = Math.random().toString().slice(2, 8);
const adminUserId = Math.random().toString().slice(2, 8);

var usersToCleanup: string[] = [];
var competitionsToCleanup: string[] = [];

beforeEach(async () => {
    try {
        // Create a regular test user (not pro, limit of 1)
        await TestSQL.createUser({
            userId: convertUserIdToBuffer(testUserId),
            firstName: 'TestUser',
            maxActiveCompetitions: 1,
            isPro: false,
            createdDate: new Date()
        });
        usersToCleanup.push(testUserId);

        // Create an admin user who will own public competitions
        await TestSQL.createUser({
            userId: convertUserIdToBuffer(adminUserId),
            firstName: 'Admin',
            maxActiveCompetitions: 10,
            isPro: false,
            createdDate: new Date()
        });
        usersToCleanup.push(adminUserId);
    } catch (error) {
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

describe('GET /competitions/public', () => {
    test('returns empty list when no public competitions exist', async () => {
        const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
        const response = await RequestUtilities.makeGetRequest('competitions/public', accessToken);

        expect(response.status).toBe(200);
        expect(response.data.competitions).toEqual([]);
        expect(response.data.isUserPro).toBe(false);
    });

    test('returns public competitions with member count', async () => {
        const competitionId = uuid();
        const now = new Date();
        const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

        await TestSQL.createPublicCompetition({
            competitionId,
            displayName: 'Weekly Challenge',
            startDate: now,
            endDate: nextWeek,
            adminUserId: convertUserIdToBuffer(adminUserId),
            accessToken: 'unused',
            ianaTimezone: 'America/New_York'
        });
        competitionsToCleanup.push(competitionId);

        // Add a user to the competition to test member count
        await TestSQL.addUserToCompetition({
            userId: convertUserIdToBuffer(adminUserId),
            competitionId
        });

        const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
        const response = await RequestUtilities.makeGetRequest('competitions/public', accessToken);

        expect(response.status).toBe(200);
        expect(response.data.competitions.length).toBe(1);
        expect(response.data.competitions[0].displayName).toBe('Weekly Challenge');
        expect(response.data.competitions[0].memberCount).toBe(1);
        expect(response.data.competitions[0].isUserMember).toBe(false);
    });

    test('shows isUserMember when user is in the competition', async () => {
        const competitionId = uuid();
        const now = new Date();
        const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

        await TestSQL.createPublicCompetition({
            competitionId,
            displayName: 'Weekly Challenge',
            startDate: now,
            endDate: nextWeek,
            adminUserId: convertUserIdToBuffer(adminUserId),
            accessToken: 'unused',
            ianaTimezone: 'America/New_York'
        });
        competitionsToCleanup.push(competitionId);

        // Add the test user to the competition
        await TestSQL.addUserToCompetition({
            userId: convertUserIdToBuffer(testUserId),
            competitionId
        });

        const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
        const response = await RequestUtilities.makeGetRequest('competitions/public', accessToken);

        expect(response.status).toBe(200);
        expect(response.data.competitions[0].isUserMember).toBe(true);
    });

    test('reflects pro status correctly', async () => {
        // Upgrade user to pro
        await TestSQL.updateUserProStatus({
            userId: convertUserIdToBuffer(testUserId),
            isPro: true,
            maxActiveCompetitions: 10
        });

        const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
        const response = await RequestUtilities.makeGetRequest('competitions/public', accessToken);

        expect(response.status).toBe(200);
        expect(response.data.isUserPro).toBe(true);
    });
});

describe('POST /competitions/joinPublic', () => {
    test('pro user can join a public competition', async () => {
        // Make user pro
        await TestSQL.updateUserProStatus({
            userId: convertUserIdToBuffer(testUserId),
            isPro: true,
            maxActiveCompetitions: 10
        });

        const competitionId = uuid();
        const now = new Date();
        const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

        await TestSQL.createPublicCompetition({
            competitionId,
            displayName: 'Weekly Challenge',
            startDate: now,
            endDate: nextWeek,
            adminUserId: convertUserIdToBuffer(adminUserId),
            accessToken: 'unused',
            ianaTimezone: 'America/New_York'
        });
        competitionsToCleanup.push(competitionId);

        const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
        const response = await RequestUtilities.makePostRequest('competitions/joinPublic', {
            competitionId
        }, accessToken);

        expect(response.status).toBe(200);
    });

    test('non-pro user cannot join a public competition', async () => {
        const competitionId = uuid();
        const now = new Date();
        const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

        await TestSQL.createPublicCompetition({
            competitionId,
            displayName: 'Weekly Challenge',
            startDate: now,
            endDate: nextWeek,
            adminUserId: convertUserIdToBuffer(adminUserId),
            accessToken: 'unused',
            ianaTimezone: 'America/New_York'
        });
        competitionsToCleanup.push(competitionId);

        const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
        const response = await RequestUtilities.makePostRequest('competitions/joinPublic', {
            competitionId
        }, accessToken);

        expect(response.status).toBe(403);
        expect(response.data.custom_error_code).toBe(FWFErrorCodes.SubscriptionErrorCodes.ProSubscriptionRequired);
    });

    test('returns 404 for non-existent public competition', async () => {
        await TestSQL.updateUserProStatus({
            userId: convertUserIdToBuffer(testUserId),
            isPro: true,
            maxActiveCompetitions: 10
        });

        const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
        const response = await RequestUtilities.makePostRequest('competitions/joinPublic', {
            competitionId: uuid()
        }, accessToken);

        expect(response.status).toBe(404);
    });

    test('returns 400 when missing competitionId', async () => {
        const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);
        const response = await RequestUtilities.makePostRequest('competitions/joinPublic', {}, accessToken);

        expect(response.status).toBe(400);
    });
});

describe('POST /admin/createPublicCompetition', () => {
    test('creates a public competition with admin auth', async () => {
        const now = new Date();
        const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

        const response = await RequestUtilities.makeAdminPostRequest('admin/createPublicCompetition', {
            startDate: now.toISOString(),
            endDate: nextWeek.toISOString(),
            displayName: 'Weekly Challenge',
            ianaTimezone: 'America/New_York',
            adminUserId: adminUserId
        });

        console.log(response);
        expect(response.status).toBe(200);
        expect(response.data.competition_id).toBeDefined();
        competitionsToCleanup.push(response.data.competition_id);

        // Verify the competition was created as public
        const competition = await TestSQL.getCompetition({ competitionId: response.data.competition_id });
        expect(competition[0].is_public).toBe(true);
    });

    test('rejects without admin auth', async () => {
        const now = new Date();
        const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

        const response = await RequestUtilities.makePostRequest('admin/createPublicCompetition', {
            startDate: now.toISOString(),
            endDate: nextWeek.toISOString(),
            displayName: 'Weekly Challenge',
            ianaTimezone: 'America/New_York',
            adminUserId: adminUserId
        });

        expect(response.status).toBe(401);
    });

    test('rejects with missing parameters', async () => {
        const response = await RequestUtilities.makeAdminPostRequest('admin/createPublicCompetition', {
            displayName: 'Weekly Challenge'
        });

        expect(response.status).toBe(400);
    });
});

describe('Public competitions and private competition limits', () => {
    test('public competitions do not count toward private competition limit', async () => {
        // Create a user with max 1 active competition
        const limitedUserId = Math.random().toString().slice(2, 8);
        await TestSQL.createUser({
            userId: convertUserIdToBuffer(limitedUserId),
            firstName: 'Limited',
            maxActiveCompetitions: 1,
            isPro: true,
            createdDate: new Date()
        });
        usersToCleanup.push(limitedUserId);

        // Add user to a public competition
        const publicCompId = uuid();
        const now = new Date();
        const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

        await TestSQL.createPublicCompetition({
            competitionId: publicCompId,
            displayName: 'Public Competition',
            startDate: now,
            endDate: nextWeek,
            adminUserId: convertUserIdToBuffer(adminUserId),
            accessToken: 'unused',
            ianaTimezone: 'America/New_York'
        });
        competitionsToCleanup.push(publicCompId);

        await TestSQL.addUserToCompetition({
            userId: convertUserIdToBuffer(limitedUserId),
            competitionId: publicCompId
        });

        // Create a private competition for the user to join
        const privateCompId = uuid();
        await TestSQL.createCompetition({
            competitionId: privateCompId,
            displayName: 'Private Competition',
            startDate: now,
            endDate: nextWeek,
            adminUserId: convertUserIdToBuffer(adminUserId),
            accessToken: 'private-token',
            ianaTimezone: 'America/New_York'
        });
        competitionsToCleanup.push(privateCompId);

        // The user should be able to join the private competition
        // even though they're already in a public competition,
        // because public competitions don't count toward the limit
        const accessToken = await AuthUtilities.getAccessTokenForUser(limitedUserId);
        const response = await RequestUtilities.makePostRequest('competitions/join', {
            competitionId: privateCompId,
            accessToken: 'private-token'
        }, accessToken);

        expect(response.status).toBe(200);
    });
});
