import * as TestSQL from '../../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../../testUtilities/testAuthUtilities';
import { convertBufferToUserId, convertUserIdToBuffer } from '../../../utilities/userHelpers';
import { v4 as uuid } from 'uuid';
import { ICreateCompetitionParams } from '../../../sql/competitions.queries';

/*
    Tests the /competitions/leave route for removing the current user or other user from the competition
*/

// The userId that will be created in the database during the test setup
// This user will be added to the test competition and marked as the admin
const adminTestUserId = Math.random().toString().slice(2, 8);
const testUserName = 'Test User';

// Create a second user that will be added to the competition
const secondUserId = Math.random().toString().slice(2, 8);

// The competitionId that will be created in the database during the test setup
const now = new Date();
const testCompetitionInfo: ICreateCompetitionParams = {
    competitionId: uuid(),
    adminUserId: convertUserIdToBuffer(adminTestUserId),
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
            userId: convertUserIdToBuffer(adminTestUserId),
            firstName: testUserName.split(' ')[0],
            lastName: testUserName.split(' ')[1],
            maxActiveCompetitions: 10,
            isPro: false,
            createdDate: new Date()
        });
        usersToCleanup.push(adminTestUserId);

        await TestSQL.createUser({
            userId: convertUserIdToBuffer(secondUserId),
            firstName: 'Second',
            lastName: 'User',
            maxActiveCompetitions: 10,
            isPro: false,
            createdDate: new Date()
        });
        usersToCleanup.push(secondUserId);

        // Create a competition for the admin user
        const now = new Date();
        await TestSQL.createCompetition(testCompetitionInfo);
        competitionsToCleanup.push(testCompetitionInfo.competitionId);

        // Add the admin user to the competition
        await TestSQL.addUserToCompetition({
            competitionId: testCompetitionInfo.competitionId,
            userId: convertUserIdToBuffer(adminTestUserId)
        });

        // Add the second user to the competition
        await TestSQL.addUserToCompetition({
            competitionId: testCompetitionInfo.competitionId,
            userId: convertUserIdToBuffer(secondUserId)
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

test('Leave competition: user removes their self', async () => {
    // Make the leave request as the second user
    // It should succeed since they are trying to remove themselves
    const accessToken = await AuthUtilities.getAccessTokenForUser(secondUserId);
    const response = await RequestUtilities.makePostRequest('competitions/leave', {
            competitionId: testCompetitionInfo.competitionId ,
            userId: secondUserId
        }, accessToken);

    expect(response.status).toBe(200);

    // Validate that the user has been removed from the competition
    const competitionUsers = await TestSQL.getUsersInCompetition({ competitionId: testCompetitionInfo.competitionId });
    
    // The admin user should still be in the competition
    // But our second user should have been removed
    expect(competitionUsers.length).toBe(1);
    expect(convertBufferToUserId(competitionUsers[0].user_id)).toBe(adminTestUserId);

    // Validate that the user removing themself has not changed the competition access token
    const competitions = await TestSQL.getCompetition({ competitionId: testCompetitionInfo.competitionId });
    expect(competitions.length).toBe(1);
    expect(competitions[0].access_token).toBe(testCompetitionInfo.accessToken);
});

test('Leave competition: admin removes another user', async () => {
    // Make the leave request as the admin user to remove the second user
    // It should succeed because the admin has the ability to remove other users
    const accessToken = await AuthUtilities.getAccessTokenForUser(adminTestUserId);
    const response = await RequestUtilities.makePostRequest('competitions/leave', {
            competitionId: testCompetitionInfo.competitionId ,
            userId: secondUserId
        }, accessToken);

    expect(response.status).toBe(200);

    // Validate that the user has been removed from the competition
    const competitionUsers = await TestSQL.getUsersInCompetition({ competitionId: testCompetitionInfo.competitionId });
    
    // The admin user should still be in the competition
    // But our second user should have been removed
    expect(competitionUsers.length).toBe(1);
    expect(convertBufferToUserId(competitionUsers[0].user_id)).toBe(adminTestUserId);

    // Validate that the competition access token has been changed (which should happen when the admin removes a user)
    const competitions = await TestSQL.getCompetition({ competitionId: testCompetitionInfo.competitionId });
    expect(competitions.length).toBe(1);
    expect(competitions[0].access_token).not.toBe(testCompetitionInfo.accessToken);
});

test('Leave competition: admin removes themself', async () => {
    // Make the leave request as the admin user to remove themself
    // It should fail because the admin user cannot remove themself
    const accessToken = await AuthUtilities.getAccessTokenForUser(adminTestUserId);
    const response = await RequestUtilities.makePostRequest('competitions/leave', {
            competitionId: testCompetitionInfo.competitionId ,
            userId: adminTestUserId
        }, accessToken);

    expect(response.status).toBe(400);

    // Validate that the admin user and the second user are still in the competition
    const competitionUsers = await TestSQL.getUsersInCompetition({ competitionId: testCompetitionInfo.competitionId });
    expect(competitionUsers.length).toBe(2);
    expect(competitionUsers.map(user => convertBufferToUserId(user.user_id))).toContain(adminTestUserId);

    // Validate that the competition access token has not been changed
    const competitions = await TestSQL.getCompetition({ competitionId: testCompetitionInfo.competitionId });
    expect(competitions.length).toBe(1);
    expect(competitions[0].access_token).toBe(testCompetitionInfo.accessToken);
});

test('Leave competition: user removes another user', async () => {
    // Create a third member of the competition that is not the admin user
    const thirdUserId = Math.random().toString().slice(2, 8);
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(thirdUserId),
        firstName: 'Third',
        maxActiveCompetitions: 10,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(thirdUserId);

    // Add the third user to the competition
    await TestSQL.addUserToCompetition({
        competitionId: testCompetitionInfo.competitionId,
        userId: convertUserIdToBuffer(thirdUserId)
    });

    // Make the leave request as the second user to remove the third user
    // It should fail because the second user does not have the ability to remove other users
    const accessToken = await AuthUtilities.getAccessTokenForUser(secondUserId);
    const response = await RequestUtilities.makePostRequest('competitions/leave', {
            competitionId: testCompetitionInfo.competitionId ,
            userId: thirdUserId
        }, accessToken);

    expect(response.status).toBe(401);

    // Validate that the third user is still in the competition
    const competitionUsers = await TestSQL.getUsersInCompetition({ competitionId: testCompetitionInfo.competitionId });
    expect(competitionUsers.length).toBe(3);
    expect(competitionUsers.map(user => convertBufferToUserId(user.user_id))).toContain(thirdUserId);

    // Validate that the competition access token has not been changed
    const competitions = await TestSQL.getCompetition({ competitionId: testCompetitionInfo.competitionId });
    expect(competitions.length).toBe(1);
    expect(competitions[0].access_token).toBe(testCompetitionInfo.accessToken);
});

test('Leave competition: admin removes user not in competition', async () => {
    // Create a user that is not in the competition
    const notAMemberUserId = Math.random().toString().slice(2, 8);
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(notAMemberUserId),
        firstName: 'Second',
        maxActiveCompetitions: 10,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(notAMemberUserId);

    // Make the leave request as the admin user to remove the second user, even though the second user is not in the competition
    const accessToken = await AuthUtilities.getAccessTokenForUser(adminTestUserId);
    const response = await RequestUtilities.makePostRequest('competitions/leave', {
            competitionId: testCompetitionInfo.competitionId ,
            userId: notAMemberUserId
        }, accessToken);
    
    // We return a success code even if the target user is not in the competition
    expect(response.status).toBe(200);

    // Validate that the competition has not changed
    const competitionUsers = await TestSQL.getUsersInCompetition({ competitionId: testCompetitionInfo.competitionId });
    expect(competitionUsers.length).toBe(2);
    expect(competitionUsers.map(user => convertBufferToUserId(user.user_id))).toContain(adminTestUserId);
    expect(competitionUsers.map(user => convertBufferToUserId(user.user_id))).toContain(secondUserId);
});

test('Leave competition: missing competitionId', async () => {
    // Make the leave request as the second user
    // It should fail because the competitionId is missing
    const accessToken = await AuthUtilities.getAccessTokenForUser(secondUserId);
    const response = await RequestUtilities.makePostRequest('competitions/leave', {
            userId: secondUserId
        }, accessToken);

    expect(response.status).toBe(400);
});

test('Leave competition: missing userId', async () => {
    // Make the leave request as the admin user
    // It should fail because the userId is missing
    const accessToken = await AuthUtilities.getAccessTokenForUser(adminTestUserId);
    const response = await RequestUtilities.makePostRequest('competitions/leave', {
            competitionId: testCompetitionInfo.competitionId
        }, accessToken);

    expect(response.status).toBe(400);
});

test('Leave competition: invalid competitionId', async () => {
    // Make the leave request as the second user
    // It should fail because the competitionId is invalid
    const accessToken = await AuthUtilities.getAccessTokenForUser(secondUserId);
    const response = await RequestUtilities.makePostRequest('competitions/leave', {
            competitionId: uuid(),
            userId: secondUserId
        }, accessToken);

    expect(response.status).toBe(404);
});

test('Leave competition: missing access token', async () => {
    // Make the leave request without an access token
    const response = await RequestUtilities.makePostRequest('competitions/leave', {
        competitionId: uuid(),
        userId: secondUserId
    });

    // The auth middleware treats the missing access token as a bad request
    expect(response.status).toBe(400);
});