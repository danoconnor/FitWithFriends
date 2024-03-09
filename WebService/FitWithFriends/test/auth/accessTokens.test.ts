import * as TestSQL from '../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../testUtilities/testAuthUtilities';
import { convertUserIdToBuffer } from '../../utilities/userHelpers';

/*
    Tests accessing an authenticated route using access tokens
*/

// A random, authenticated route that requires an access token
const relativeUrl = 'competitions';

// The userId that will be created in the database during the test setup
const testUserId = Math.random().toString().slice(2, 8);

beforeEach(async () => {
    try {
        await TestSQL.createUser({
            userId: convertUserIdToBuffer(testUserId),
            firstName: 'Test',
            maxActiveCompetitions: 10,
            isPro: false,
            createdDate: new Date()
        });
    } catch (error) {
        console.log('Test setup failed: ' + error);
        throw error;
    }
});

afterEach(async () => {
    await TestSQL.clearDataForUser({ userId: convertUserIdToBuffer(testUserId) });
});

test('Happy path', async () => {
    // Generate a valid AT
    const accessToken = await AuthUtilities.getAccessTokenForUser(testUserId);

    // Make a request to the authenticated route
    const response = await RequestUtilities.makeGetRequest(relativeUrl, accessToken);
    expect(response.status).toBe(200);
});

test('Incorrect access token issuer', async () => {
    // This AT was signed with the wrong key, so should be rejected
    const accessTokenWithIncorrectIssuer = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3MDk5MDcwNDQsIm5iZiI6MTcwOTkwNzA0NCwiZXhwIjoxNzA5OTEwNjQ0LCJzdWIiOiIxMjM0NTYiLCJpc3MiOiJjb20uZGFub2Nvbm5vci5maXR3aXRoZnJpZW5kcyIsImNsaWVudCI6IjZhNzczYzMyLTVlYjMtNDFjOS04MDM2LWI5OTFiNTFmMTRmNyJ9.iNkX_5yeCMXssnmuMIgxdMbh4BWHfGvdmuDp3e9rduzqs_Yanwf_FfILXYaSaLpDBlLuspeNjUfyokhjw6bwsDtaH0isguwo83FdGwuWNQK_XAqSqz-c17LEfLwgKjw2QM73zRqDCEOusrGMmR6H9HQaywAGrbw_ZDXA_IC1zZbzpSwVKzr-mz9DLTyurl1tUesGxTmFos03pL3ORGqxC2EwwhY-rYCbCztmwCRILlovRedZw5DDCGXOUhNS_dsgIsXXGIySwGFz4ghdFJ3dh9pdeOlYe7cDROxaOsF85FvugjNxEBgiOWGX_iKqPWEzH3ElPICNNX8fs0W5sGr2fA';
    const response = await RequestUtilities.makeGetRequest(relativeUrl, accessTokenWithIncorrectIssuer);
    expect(response.status).toBe(401);
});

test('Expired access token', async () => {
    // This AT has expired, so should be rejected
    const expiredAccessToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3MDk5MTQwNzYsIm5iZiI6MTcwOTkxNDA3NiwiZXhwIjoxNzA5OTE3Njc2LCJzdWIiOiIxMjM0NTYiLCJpc3MiOiJjb20uZGFub2Nvbm5vci5maXR3aXRoZnJpZW5kcyIsImNsaWVudCI6IjZhNzczYzMyLTVlYjMtNDFjOS04MDM2LWI5OTFiNTFmMTRmNyJ9.VEu2RZcXrm8IbqAlloWhyLXAfdUJCeQd8Rht7lst4RYaiSkLWVmX9tp3g2Zl8WCLj5POChEovyvFdBICCesvApzhqxgtaXL6NCWsorGqVor_hK1H9ZM8sQj1rk7odIcU10pcNFYywUBUpHReXY9rfWX94qO2QG928lQRNdWcvH75jPCaG2vAjJT1AXrjrmEN0XfS3yZQ2mdJgqJe7zvWfMzRL4IdrtuUASBHzt7x0riyNCpxVYHZxK2Z4Yh5GBQuUUC1R-VxEZuG5lKAsUm9KlWQhzK8Ly5vaVikni7VyUHHOy_5eG-r_oOmV-UoS1TN9jdgoLzqelemntmWSPnfd2FHabK0PszkJFI6BIfUmGfLaQhcHnXV9xa_7D12FfoRpxN0g1n405LTmkHl9s6Mny648W6HkgwFghJ2XiDiCUcqeBzMI3Dd2Ilf5Z1wn0b9Jr8zkroqkV8znEz_QIK30fbl-6oPmmbaQzL8a9Mlk-Rs0HpJk9Lq3yXV6WYX_cmPo7IZHqIMXE6ZPF1KvOFKqVaeIrYDJ3oUNiR27okX2uysQXr2O1Fe9B0YzvWvmrAImiPvuLgKduRzsLO1I5aRjmhJtGdxQOtjqd9Mp3rBAPoTpHKD9ImjAExbz2WwheW8TJwU7FtUo0yHXWTbZTOB57nVFJw3OwhdI1wFHjHT36Y';
    const response = await RequestUtilities.makeGetRequest(relativeUrl, expiredAccessToken);
    expect(response.status).toBe(401);
});