import * as RequestUtilities from '../testUtilities/testRequestUtilities';

/*
    Tests the /appstore route

    Note: Testing notification type handling (DID_RENEW, EXPIRED, etc.) requires
    a valid Apple-signed JWS payload, which is only available in Apple's sandbox
    environment. The tests here cover the error paths that can be verified without
    a real Apple JWS.
*/

describe('POST /appstore', () => {
    test('returns 400 when signedPayload is missing', async () => {
        const response = await RequestUtilities.makePostRequest('appstore', {});

        expect(response.status).toBe(400);
    });

    test('returns 200 for invalid JWS (Apple retry prevention)', async () => {
        // The route always returns 200 on verification errors to prevent Apple
        // from retrying indefinitely with a bad payload
        const response = await RequestUtilities.makePostRequest('appstore', {
            signedPayload: 'not-a-valid-jws'
        });

        expect(response.status).toBe(200);
    });

    test('returns 200 for malformed but structurally valid JWS', async () => {
        // A three-part JWS with base64-encoded parts that won't pass certificate verification
        const fakeJws = 'eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsIng1YyI6WyJmYWtlY2VydCJdfQ.eyJub3RpZmljYXRpb25UeXBlIjoiRElEX1JFTkVXIn0.fakesignature';
        const response = await RequestUtilities.makePostRequest('appstore', {
            signedPayload: fakeJws
        });

        expect(response.status).toBe(200);
    });
});
