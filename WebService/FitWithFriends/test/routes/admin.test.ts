import * as TestSQL from '../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../testUtilities/testRequestUtilities';
import * as CompetitionQueries from '../../sql/competitions.queries';
import { convertUserIdToBuffer } from '../../utilities/userHelpers';
import { v4 as uuid } from 'uuid';
import { CompetitionState } from '../../utilities/enums/CompetitionState';

/*
    Integration tests for the /admin routes
    These tests run against the actual server and database
*/

// Test user IDs 
const testUserId1 = Math.random().toString().slice(2, 8);
const testUserId2 = Math.random().toString().slice(2, 8);

// Data created during the tests that needs to be cleaned up after
var usersToCleanup: string[] = [];
var competitionsToCleanup: string[] = [];

beforeEach(async () => {
    try {
        // Clean up any public competitions left over from previous test runs
        const existingPublicCompetitions = await CompetitionQueries.getPublicCompetitions({ activeState: CompetitionState.NotStartedOrActive });
        await Promise.all(existingPublicCompetitions.map(c => TestSQL.clearDataForCompetition({ competitionId: c.competition_id })));

        // Create test users
        await TestSQL.createUser({
            userId: convertUserIdToBuffer(testUserId1),
            firstName: 'TestUser1',
            maxActiveCompetitions: 10,
            isPro: false,
            createdDate: new Date()
        });
        usersToCleanup.push(testUserId1);

        await TestSQL.createUser({
            userId: convertUserIdToBuffer(testUserId2),
            firstName: 'TestUser2',
            maxActiveCompetitions: 10,
            isPro: false,
            createdDate: new Date()
        });
        usersToCleanup.push(testUserId2);
    } catch (error) {
        console.log('Test setup failed: ' + error);
        throw error;
    }
});

afterEach(async () => {
    await Promise.all(usersToCleanup.map(userId => TestSQL.clearDataForUser({ userId: convertUserIdToBuffer(userId) })));
    await Promise.all(competitionsToCleanup.map(competitionId => TestSQL.clearDataForCompetition({ competitionId })));

    // Clean up any public competitions auto-created by performDailyTasks during tests
    const activePublicCompetitions = await CompetitionQueries.getPublicCompetitions({ activeState: CompetitionState.NotStartedOrActive });
    await Promise.all(activePublicCompetitions.map(c => TestSQL.clearDataForCompetition({ competitionId: c.competition_id })));

    usersToCleanup = [];
    competitionsToCleanup = [];
});

describe('Admin authentication', () => {
    test('missing admin authorization returns 401', async () => {
        const response = await RequestUtilities.makePostRequest('admin/performDailyTasks', {});
        expect(response.status).toBe(401);
    });

    test('invalid admin authorization returns 401', async () => {
        const response = await RequestUtilities.makePostRequest('admin/performDailyTasks', {}, 'invalid_auth_token');
        expect(response.status).toBe(401);
    });
});

describe('performDailyTasks - processesRecentlyEndedCompetitions', () => {
    test('processes competitions that recently ended', async () => {
        const competitionId = uuid();
        const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
        
        // Create a competition that ended yesterday but is still in NotStartedOrActive state
        await TestSQL.createCompetitionWithState({
            competitionId,
            displayName: 'Test Competition',
            startDate: yesterday,
            endDate: yesterday, // Ended yesterday
            adminUserId: convertUserIdToBuffer(testUserId1),
            accessToken: 'test-token',
            ianaTimezone: 'America/New_York',
            state: CompetitionState.NotStartedOrActive
        });
        competitionsToCleanup.push(competitionId);

        // Add users to the competition
        await TestSQL.addUserToCompetition({
            userId: convertUserIdToBuffer(testUserId1),
            competitionId
        });
        await TestSQL.addUserToCompetition({
            userId: convertUserIdToBuffer(testUserId2),
            competitionId
        });

        // Create push tokens for notifications
        await TestSQL.createPushToken({
            userId: convertUserIdToBuffer(testUserId1),
            pushToken: 'test-token-1',
            platform: 1,
            appInstallId: uuid()
        });
        await TestSQL.createPushToken({
            userId: convertUserIdToBuffer(testUserId2),
            pushToken: 'test-token-2',
            platform: 1,
            appInstallId: uuid()
        });

        // Run the admin task
        const response = await RequestUtilities.makeAdminPostRequest('admin/performDailyTasks', {});
        expect(response.status).toBe(200);

        // Verify the competition state was updated to ProcessingResults
        const competition = await TestSQL.getCompetition({ competitionId });
        expect(competition[0].state).toBe(CompetitionState.ProcessingResults);
    });

    test('does not process competitions that have not ended', async () => {
        const competitionId = uuid();
        const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
        
        // Create a competition that ends tomorrow
        await TestSQL.createCompetitionWithState({
            competitionId,
            displayName: 'Future Competition',
            startDate: new Date(),
            endDate: tomorrow, // Ends tomorrow
            adminUserId: convertUserIdToBuffer(testUserId1),
            accessToken: 'test-token',
            ianaTimezone: 'America/New_York',
            state: CompetitionState.NotStartedOrActive
        });
        competitionsToCleanup.push(competitionId);

        // Run the admin task
        const response = await RequestUtilities.makeAdminPostRequest('admin/performDailyTasks', {});
        expect(response.status).toBe(200);

        // Verify the competition state was NOT changed
        const competition = await TestSQL.getCompetition({ competitionId });
        expect(competition[0].state).toBe(CompetitionState.NotStartedOrActive);
    });
});

describe('performDailyTasks - archiveCompetitions', () => {
    test('archives competitions in ProcessingResults state for over 24 hours', async () => {
        const competitionId = uuid();
        const twoDaysAgo = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000);
        
        // Create a competition that has been in ProcessingResults state for over 24 hours
        await TestSQL.createCompetitionWithState({
            competitionId,
            displayName: 'Archive Competition',
            startDate: twoDaysAgo,
            endDate: twoDaysAgo, // Ended 2 days ago
            adminUserId: convertUserIdToBuffer(testUserId1),
            accessToken: 'test-token',
            ianaTimezone: 'America/New_York',
            state: CompetitionState.ProcessingResults
        });
        competitionsToCleanup.push(competitionId);

        // Add users to the competition  
        await TestSQL.addUserToCompetition({
            userId: convertUserIdToBuffer(testUserId1),
            competitionId
        });
        await TestSQL.addUserToCompetition({
            userId: convertUserIdToBuffer(testUserId2),
            competitionId
        });

        // Add activity data for scoring
        await TestSQL.insertActivitySummary({
            userId: convertUserIdToBuffer(testUserId1),
            date: twoDaysAgo,
            caloriesBurned: 500,
            caloriesGoal: 400,
            exerciseTime: 30,
            exerciseTimeGoal: 30,
            standTime: 12,
            standTimeGoal: 12
        });
        await TestSQL.insertActivitySummary({
            userId: convertUserIdToBuffer(testUserId2),
            date: twoDaysAgo,
            caloriesBurned: 300,
            caloriesGoal: 400,
            exerciseTime: 20,
            exerciseTimeGoal: 30,
            standTime: 8,
            standTimeGoal: 12
        });

        // Create push tokens for notifications
        await TestSQL.createPushToken({
            userId: convertUserIdToBuffer(testUserId1),
            pushToken: 'test-token-1',
            platform: 1,
            appInstallId: uuid()
        });
        await TestSQL.createPushToken({
            userId: convertUserIdToBuffer(testUserId2),
            pushToken: 'test-token-2',
            platform: 1,
            appInstallId: uuid()
        });

        // Run the admin task
        const response = await RequestUtilities.makeAdminPostRequest('admin/performDailyTasks', {});
        expect(response.status).toBe(200);

        // Verify the competition state was updated to Archived
        const competition = await TestSQL.getCompetition({ competitionId });
        expect(competition[0].state).toBe(CompetitionState.Archived);
    });

    test('does not archive competitions in ProcessingResults state for less than 24 hours', async () => {
        const competitionId = uuid();
        const twelveHoursAgo = new Date(Date.now() - 12 * 60 * 60 * 1000);
        
        // Create a competition that has been in ProcessingResults state for only 12 hours
        await TestSQL.createCompetitionWithState({
            competitionId,
            displayName: 'Recent Processing Competition',
            startDate: twelveHoursAgo,
            endDate: twelveHoursAgo,
            adminUserId: convertUserIdToBuffer(testUserId1),
            accessToken: 'test-token',
            ianaTimezone: 'America/New_York',
            state: CompetitionState.ProcessingResults
        });
        competitionsToCleanup.push(competitionId);

        // Run the admin task
        const response = await RequestUtilities.makeAdminPostRequest('admin/performDailyTasks', {});
        expect(response.status).toBe(200);

        // Verify the competition state was NOT changed
        const competition = await TestSQL.getCompetition({ competitionId });
        expect(competition[0].state).toBe(CompetitionState.ProcessingResults);
    });

    test('handles competitions with no users gracefully', async () => {
        const competitionId = uuid();
        const twoDaysAgo = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000);
        
        // Create a competition with no users
        await TestSQL.createCompetitionWithState({
            competitionId,
            displayName: 'Empty Competition',
            startDate: twoDaysAgo,
            endDate: twoDaysAgo,
            adminUserId: convertUserIdToBuffer(testUserId1),
            accessToken: 'test-token',
            ianaTimezone: 'America/New_York',
            state: CompetitionState.ProcessingResults
        });
        competitionsToCleanup.push(competitionId);

        // Run the admin task (should not crash)
        const response = await RequestUtilities.makeAdminPostRequest('admin/performDailyTasks', {});
        expect(response.status).toBe(200);

        // Competition should still be archived even with no users
        const competition = await TestSQL.getCompetition({ competitionId });
        expect(competition[0].state).toBe(CompetitionState.Archived);
    });
});

describe('performDailyTasks - deleteExpiredRefreshTokens', () => {
    test('deletes expired refresh tokens', async () => {
        const expiredDate = new Date(Date.now() - 24 * 60 * 60 * 1000); // 24 hours ago
        const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000);  // 24 hours from now

        // Create expired refresh token
        await TestSQL.createRefreshToken({
            refreshToken: 'expired-token',
            refreshTokenExpiresOn: expiredDate,
            userId: convertUserIdToBuffer(testUserId1),
            clientId: '6A773C32-5EB3-41C9-8036-B991B51F14F7'
        });

        // Create valid refresh token (should not be deleted)
        await TestSQL.createRefreshToken({
            refreshToken: 'valid-token',
            refreshTokenExpiresOn: futureDate,
            userId: convertUserIdToBuffer(testUserId2),
            clientId: '6A773C32-5EB3-41C9-8036-B991B51F14F7'
        });

        // Run the admin task
        const response = await RequestUtilities.makeAdminPostRequest('admin/performDailyTasks', {});
        expect(response.status).toBe(200);

        // Verify our specific tokens - expired token should be gone, valid token should remain
        const remainingTokens = await TestSQL.getRefreshTokens();
        const expiredTokenExists = remainingTokens.some(t => t.refresh_token === 'expired-token');
        const validTokenExists = remainingTokens.some(t => t.refresh_token === 'valid-token');
        
        expect(expiredTokenExists).toBe(false);
        expect(validTokenExists).toBe(true);
    });

    test('handles case with no expired tokens', async () => {
        const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000);

        // Create only valid refresh tokens
        await TestSQL.createRefreshToken({
            refreshToken: 'valid-token-1',
            refreshTokenExpiresOn: futureDate,
            userId: convertUserIdToBuffer(testUserId1),
            clientId: '6A773C32-5EB3-41C9-8036-B991B51F14F7'
        });
        await TestSQL.createRefreshToken({
            refreshToken: 'valid-token-2',
            refreshTokenExpiresOn: futureDate,
            userId: convertUserIdToBuffer(testUserId2),
            clientId: '6A773C32-5EB3-41C9-8036-B991B51F14F7'
        });

        // Run the admin task
        const response = await RequestUtilities.makeAdminPostRequest('admin/performDailyTasks', {});
        expect(response.status).toBe(200);

        // Verify our specific tokens still exist (should not be deleted)
        const remainingTokens = await TestSQL.getRefreshTokens();
        const validToken1Exists = remainingTokens.some(t => t.refresh_token === 'valid-token-1');
        const validToken2Exists = remainingTokens.some(t => t.refresh_token === 'valid-token-2');
        
        expect(validToken1Exists).toBe(true);
        expect(validToken2Exists).toBe(true);
    });
});

const isSunOrMon = [0, 1].includes(new Date().getUTCDay());

describe('performDailyTasks - createWeeklyPublicCompetition', () => {
    (isSunOrMon ? test : test.skip)('creates a weekly public competition on Sunday or Monday when none exists', async () => {
        const response = await RequestUtilities.makeAdminPostRequest('admin/performDailyTasks', {});
        expect(response.status).toBe(200);

        const publicCompetitions = await CompetitionQueries.getPublicCompetitions({
            activeState: CompetitionState.NotStartedOrActive
        });
        expect(publicCompetitions.length).toBe(1);

        const competition = publicCompetitions[0];
        competitionsToCleanup.push(competition.competition_id);

        const startDate = new Date(competition.start_date);
        expect(startDate.getUTCDay()).toBe(1); // starts on Monday

        const durationDays = (new Date(competition.end_date).getTime() - startDate.getTime()) / (24 * 60 * 60 * 1000);
        expect(durationDays).toBe(7);

        expect(competition.display_name).toBe('Weekly challenge - see how you stack up');
    });

    (!isSunOrMon ? test : test.skip)('does not create a competition on weekdays', async () => {
        const response = await RequestUtilities.makeAdminPostRequest('admin/performDailyTasks', {});
        expect(response.status).toBe(200);

        const publicCompetitions = await CompetitionQueries.getPublicCompetitions({
            activeState: CompetitionState.NotStartedOrActive
        });
        expect(publicCompetitions.length).toBe(0);
    });

    test('does not create a duplicate when a competition for the upcoming week already exists', async () => {
        const competitionId = uuid();
        const now = new Date();
        const dayOfWeek = now.getUTCDay();
        const daysUntilMonday = dayOfWeek === 1 ? 0 : (8 - dayOfWeek) % 7;
        const startDate = new Date(now);
        startDate.setUTCDate(now.getUTCDate() + daysUntilMonday);
        startDate.setUTCHours(0, 0, 0, 0);
        const endDate = new Date(startDate);
        endDate.setUTCDate(startDate.getUTCDate() + 7);

        await TestSQL.createPublicCompetition({
            competitionId,
            displayName: 'Existing Weekly Challenge',
            startDate,
            endDate,
            adminUserId: convertUserIdToBuffer(testUserId1),
            accessToken: 'test-access-token',
            ianaTimezone: 'UTC'
        });
        competitionsToCleanup.push(competitionId);

        const response = await RequestUtilities.makeAdminPostRequest('admin/performDailyTasks', {});
        expect(response.status).toBe(200);

        const publicCompetitions = await CompetitionQueries.getPublicCompetitions({
            activeState: CompetitionState.NotStartedOrActive
        });
        expect(publicCompetitions.length).toBe(1); // still only the one we pre-created
    });
});

describe('performDailyTasks - comprehensive integration', () => {
    test('handles multiple operations in single run', async () => {
        // Set up test data for all three operations
        
        // 1. Competition to process (recently ended)
        const processingCompetitionId = uuid();
        const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
        await TestSQL.createCompetitionWithState({
            competitionId: processingCompetitionId,
            displayName: 'Processing Competition',
            startDate: yesterday,
            endDate: yesterday,
            adminUserId: convertUserIdToBuffer(testUserId1),
            accessToken: 'test-token-1',
            ianaTimezone: 'America/New_York',
            state: CompetitionState.NotStartedOrActive
        });
        competitionsToCleanup.push(processingCompetitionId);

        // 2. Competition to archive (in processing for over 24 hours)
        const archiveCompetitionId = uuid();
        const twoDaysAgo = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000);
        await TestSQL.createCompetitionWithState({
            competitionId: archiveCompetitionId,
            displayName: 'Archive Competition',
            startDate: twoDaysAgo,
            endDate: twoDaysAgo,
            adminUserId: convertUserIdToBuffer(testUserId1),
            accessToken: 'test-token-2',
            ianaTimezone: 'America/New_York',
            state: CompetitionState.ProcessingResults
        });
        competitionsToCleanup.push(archiveCompetitionId);

        // Add users to archive competition for scoring
        await TestSQL.addUserToCompetition({
            userId: convertUserIdToBuffer(testUserId1),
            competitionId: archiveCompetitionId
        });

        // Add activity data
        await TestSQL.insertActivitySummary({
            userId: convertUserIdToBuffer(testUserId1),
            date: twoDaysAgo,
            caloriesBurned: 500,
            caloriesGoal: 400,
            exerciseTime: 30,
            exerciseTimeGoal: 30,
            standTime: 12,
            standTimeGoal: 12
        });

        // 3. Expired refresh token
        const expiredDate = new Date(Date.now() - 24 * 60 * 60 * 1000);
        await TestSQL.createRefreshToken({
            refreshToken: 'expired-test-token',
            refreshTokenExpiresOn: expiredDate,
            userId: convertUserIdToBuffer(testUserId1),
            clientId: '6A773C32-5EB3-41C9-8036-B991B51F14F7'
        });

        // Run the admin task
        const response = await RequestUtilities.makeAdminPostRequest('admin/performDailyTasks', {});
        expect(response.status).toBe(200);

        // Verify all operations completed successfully
        
        // 1. Processing competition should be moved to ProcessingResults
        const processingComp = await TestSQL.getCompetition({ competitionId: processingCompetitionId });
        expect(processingComp[0].state).toBe(CompetitionState.ProcessingResults);

        // 2. Archive competition should be moved to Archived
        const archiveComp = await TestSQL.getCompetition({ competitionId: archiveCompetitionId });
        expect(archiveComp[0].state).toBe(CompetitionState.Archived);

        // 3. Expired refresh token should be deleted
        const remainingTokens = await TestSQL.getRefreshTokens();
        expect(remainingTokens.filter(t => t.refresh_token === 'expired-test-token')).toHaveLength(0);
    });
});
