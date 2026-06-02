import * as TestSQL from '../../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../../testUtilities/testAuthUtilities';
import { convertUserIdToBuffer } from '../../../utilities/userHelpers';
import { CompetitionState } from '../../../utilities/enums/CompetitionState';

/*
    Tests for POST /competitions/:competitionId/notificationsSeen
    The client calls this when it shows the end-of-competition screen so the server
    does not also send the (now-redundant) push at the user's local 8am.
*/

const memberId = Math.random().toString().slice(2, 10);
const nonMemberId = Math.random().toString().slice(2, 10);

let competitionsToCleanup: string[] = [];

beforeEach(async () => {
    await TestSQL.createUser({ userId: convertUserIdToBuffer(memberId), firstName: 'Member', maxActiveCompetitions: 5, isPro: false, createdDate: new Date() });
    await TestSQL.createUser({ userId: convertUserIdToBuffer(nonMemberId), firstName: 'NonMember', maxActiveCompetitions: 5, isPro: false, createdDate: new Date() });
});

afterEach(async () => {
    await TestSQL.clearDataForUser({ userId: convertUserIdToBuffer(memberId) });
    await TestSQL.clearDataForUser({ userId: convertUserIdToBuffer(nonMemberId) });
    await Promise.all(competitionsToCleanup.map(competitionId => TestSQL.clearDataForCompetition({ competitionId })));
    competitionsToCleanup = [];
});

async function createCompetitionWithMember(): Promise<string> {
    const competitionId = crypto.randomUUID();
    await TestSQL.createCompetitionWithState({
        competitionId,
        displayName: 'Seen Competition',
        startDate: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() - 24 * 60 * 60 * 1000),
        adminUserId: convertUserIdToBuffer(memberId),
        accessToken: 'tok-' + competitionId.slice(0, 8),
        ianaTimezone: 'America/New_York',
        state: CompetitionState.Archived
    });
    competitionsToCleanup.push(competitionId);
    await TestSQL.addUserToCompetition({ userId: convertUserIdToBuffer(memberId), competitionId });
    return competitionId;
}

async function flagsFor(competitionId: string, userId: string) {
    const rows = await TestSQL.getUsersInCompetition({ competitionId });
    return rows.find(r => r.user_id.equals(convertUserIdToBuffer(userId)))!;
}

test('marks both notification flags for a member', async () => {
    const competitionId = await createCompetitionWithMember();
    const accessToken = await AuthUtilities.getAccessTokenForUser(memberId);

    const response = await RequestUtilities.makePostRequest(`competitions/${competitionId}/notificationsSeen`, {}, accessToken);
    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 200 }));

    const flags = await flagsFor(competitionId, memberId);
    expect(flags.sent_complete_notification).toBe(true);
    expect(flags.sent_processing_notification).toBe(true);
});

test('returns 401 for a non-member', async () => {
    const competitionId = await createCompetitionWithMember();
    const accessToken = await AuthUtilities.getAccessTokenForUser(nonMemberId);

    const response = await RequestUtilities.makePostRequest(`competitions/${competitionId}/notificationsSeen`, {}, accessToken);
    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 401 }));

    // The member's flags are untouched
    const flags = await flagsFor(competitionId, memberId);
    expect(flags.sent_complete_notification).toBe(false);
});
