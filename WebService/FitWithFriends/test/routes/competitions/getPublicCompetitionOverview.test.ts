import * as TestSQL from '../../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../../testUtilities/testAuthUtilities';
import { convertUserIdToBuffer } from '../../../utilities/userHelpers';
import { ICreateCompetitionParams } from '../../../sql/competitions.queries';

/*
    Tests the /competitions/:competitionId/publicOverview route, which lets a user
    preview a PUBLIC competition (scoring rules + live standings) WITHOUT being a
    member. Private competitions must never be exposed here.
*/

// The admin/member user that owns the competitions created in setup
const adminUserId = Math.random().toString().slice(2, 8);
const adminUserName = 'Admin User';

// A second user who is NOT a member of any competition - represents someone
// browsing public competitions before joining.
const nonMemberUserId = Math.random().toString().slice(2, 8);
const nonMemberUserName = 'Browser Person';

const now = new Date();

var usersToCleanup: string[] = [];
var competitionsToCleanup: string[] = [];

async function createUser(userId: string, userName: string) {
    await TestSQL.createUser({
        userId: convertUserIdToBuffer(userId),
        firstName: userName.split(' ')[0],
        lastName: userName.split(' ')[1],
        maxActiveCompetitions: 10,
        isPro: false,
        createdDate: new Date()
    });
    usersToCleanup.push(userId);
}

beforeEach(async () => {
    try {
        await createUser(adminUserId, adminUserName);
        await createUser(nonMemberUserId, nonMemberUserName);
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

async function createPublicCompetitionWithAdmin(): Promise<string> {
    const competitionId = crypto.randomUUID();
    await TestSQL.createPublicCompetition({
        competitionId,
        displayName: 'Public Test Competition',
        startDate: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 3), // 3 days ago
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 4), // 4 days from now
        adminUserId: convertUserIdToBuffer(adminUserId),
        accessToken: 'unused',
        ianaTimezone: 'America/New_York'
    });
    competitionsToCleanup.push(competitionId);

    await TestSQL.addUserToCompetition({
        competitionId,
        userId: convertUserIdToBuffer(adminUserId)
    });

    return competitionId;
}

test('Get public overview: non-member can view a public competition', async () => {
    const competitionId = await createPublicCompetitionWithAdmin();

    // Give the member some activity so the leaderboard has a real score
    const expectedTodayScore = (100 * 250.0 / 500.0) + (100 * 30.0 / 60.0) + (100 * 6.0 / 12.0);
    await TestSQL.insertActivitySummary({
        userId: convertUserIdToBuffer(adminUserId),
        date: now,
        caloriesBurned: 250,
        caloriesGoal: 500,
        exerciseTime: 30,
        exerciseTimeGoal: 60,
        standTime: 6,
        standTimeGoal: 12,
    });

    // The non-member requests the public overview
    const accessToken = await AuthUtilities.getAccessTokenForUser(nonMemberUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${competitionId}/publicOverview?timezone=America/New_York`, accessToken);

    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 200 }));
    expect(response.data.isPublic).toBe(true);
    expect(response.data.competitionName).toBe('Public Test Competition');
    expect(response.data.scoringRules).toEqual({ kind: 'rings' });
    expect(response.data.scoringUnit).toBe('points');

    // The non-member is not an admin and isn't in the standings
    expect(response.data.isUserAdmin).toBe(false);
    expect(response.data).toHaveProperty('currentResults');
    expect(response.data.currentResults.length).toBe(1);

    const memberResult = response.data.currentResults.find((r: any) => r.userId === adminUserId);
    expect(memberResult).not.toBeUndefined();
    expect(memberResult.pointsToday).toBeCloseTo(expectedTodayScore);
    expect(response.data.currentResults.find((r: any) => r.userId === nonMemberUserId)).toBeUndefined();
});

test('Get public overview: admin viewing their own public competition is flagged as admin', async () => {
    const competitionId = await createPublicCompetitionWithAdmin();

    const accessToken = await AuthUtilities.getAccessTokenForUser(adminUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${competitionId}/publicOverview?timezone=America/New_York`, accessToken);

    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 200 }));
    expect(response.data.isUserAdmin).toBe(true);
});

test('Get public overview: private competition is not exposed (returns 404)', async () => {
    // Create a PRIVATE competition owned by the admin
    const privateCompetitionInfo: ICreateCompetitionParams = {
        competitionId: crypto.randomUUID(),
        adminUserId: convertUserIdToBuffer(adminUserId),
        displayName: 'Private Competition',
        startDate: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 3),
        endDate: new Date(now.getTime() + 1000 * 60 * 60 * 24 * 3),
        accessToken: '1234',
        ianaTimezone: 'America/New_York'
    };
    await TestSQL.createCompetition(privateCompetitionInfo);
    competitionsToCleanup.push(privateCompetitionInfo.competitionId);
    await TestSQL.addUserToCompetition({
        competitionId: privateCompetitionInfo.competitionId,
        userId: convertUserIdToBuffer(adminUserId)
    });

    // Even the admin/member cannot fetch a private competition via the public route
    const accessToken = await AuthUtilities.getAccessTokenForUser(adminUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${privateCompetitionInfo.competitionId}/publicOverview?timezone=America/New_York`, accessToken);

    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 404 }));
    expect(response.data.context).toContain('Could not find competition info');
});

test('Get public overview: competition does not exist returns 404', async () => {
    const accessToken = await AuthUtilities.getAccessTokenForUser(nonMemberUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${crypto.randomUUID()}/publicOverview?timezone=America/New_York`, accessToken);

    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 404 }));
    expect(response.data.context).toContain('Could not find competition info');
});

test('Get public overview: invalid timezone returns 400', async () => {
    const competitionId = await createPublicCompetitionWithAdmin();

    const accessToken = await AuthUtilities.getAccessTokenForUser(nonMemberUserId);
    const response = await RequestUtilities.makeGetRequest(`competitions/${competitionId}/publicOverview?timezone=INVALIDTIMEZONE`, accessToken);

    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 400 }));
    expect(response.data.context).toContain('Invalid timezone query param');
});

test('Get public overview: missing access token returns 400', async () => {
    const competitionId = await createPublicCompetitionWithAdmin();

    const response = await RequestUtilities.makeGetRequest(`competitions/${competitionId}/publicOverview?timezone=America/New_York`);

    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 400 }));
});
