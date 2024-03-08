import * as RequestUtilities from './testRequestUtilities';
import * as TestSQL from '../sql/testQueries.queries';
import { convertUserIdToBuffer } from '../../utilities/userHelpers';

/** The clientId that is setup by default in the SetupTestData.sql file */
export const defaultClientId = "6a773c32-5eb3-41c9-8036-b991b51f14f7";

/**  Expects that the user has already been created */
export async function getAccessTokenForUser(userId: string): Promise<string> {
    // Add a new refresh token in the database, then use it to get an access token
    const refreshToken = 'test_refresh_token';
    const now = new Date();
    await TestSQL.createRefreshToken({
        userId: convertUserIdToBuffer(userId),
        refreshToken,
        refreshTokenExpiresOn: new Date(now.getTime() + 1000 * 60 * 60 * 24), // 1 day from now
        clientId: defaultClientId
    });

    const response = await RequestUtilities.makePostRequest('oauth/token', {
        grant_type: 'refresh_token',
        refresh_token: refreshToken
    }, undefined, 'application/x-www-form-urlencoded');

    return response.data.access_token;
}