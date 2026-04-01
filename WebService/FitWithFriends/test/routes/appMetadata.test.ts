import * as RequestUtilities from '../testUtilities/testRequestUtilities';

/*
    Tests for GET /appMetadata/iosBuildVersions
    The server reads FWF_IOS_RECOMMENDED_BUILD and FWF_IOS_REQUIRED_BUILD from its environment.
    These are set in docker-compose-local-testing.yml for the test server:
      FWF_IOS_RECOMMENDED_BUILD=20260401.1200
      FWF_IOS_REQUIRED_BUILD=20260301.0900
*/

const testRecommendedBuild = '20260401.1200';
const testRequiredBuild = '20260301.0900';

describe('GET /appMetadata/iosBuildVersions', () => {
    test('returns 200 with correct build version data', async () => {
        const response = await RequestUtilities.makeGetRequest('appMetadata/iosBuildVersions');
        expect(response.status).toBe(200);
        expect(response.data.recommendedBuild).toBe(testRecommendedBuild);
        expect(response.data.requiredBuild).toBe(testRequiredBuild);
    });

    test('returns string values for build versions', async () => {
        const response = await RequestUtilities.makeGetRequest('appMetadata/iosBuildVersions');
        expect(response.status).toBe(200);
        expect(typeof response.data.recommendedBuild).toBe('string');
        expect(typeof response.data.requiredBuild).toBe('string');
    });

    test('is accessible without an auth token', async () => {
        const response = await RequestUtilities.makeGetRequest('appMetadata/iosBuildVersions', undefined);
        expect(response.status).toBe(200);
    });
});
