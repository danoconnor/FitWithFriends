import axios from 'axios';

test('Happy path', async () => {
    const response = await makeOauthRequest({
        grant_type: 'apple_id_token',
        idToken: 'test',
        userId: '123456',
    });

    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('access_token');
    expect(response.data).toHaveProperty('refresh_token');
});

test('Missing userId', async () => {
    const response = await makeOauthRequest({
        grant_type: 'apple_id_token',
        idToken: 'test'
    });

    expect(response.status).toBe(400);
    expect(response.data.error_description).toContain('Missing parameter');
    expect(response.data.error_description).toContain('userId');
});

test('Nonexistent userId', async () => {
    const response = await makeOauthRequest({
        grant_type: 'apple_id_token',
        idToken: 'test',
        userId: '1234567890abcdef' // Does not exist in the database
    });

    expect(response.status).toBe(400);
    expect(response.data.error_description).toContain('Missing parameter');
    expect(response.data.error_description).toContain('userId');
});

async function makeOauthRequest(requestBody: any): Promise<axios.AxiosResponse<any, any>> {
    try {
        const response = await axios.post('http://localhost:3000/oauth/token', requestBody, 
        {
            headers: {
                'Authorization': 'Basic NkE3NzNDMzItNUVCMy00MUM5LTgwMzYtQjk5MUI1MUYxNEY3OjExMjc5RUQ0LTI2ODctNDA4RC05QUU3LTIyQUIzQ0E0MTIxOQ==',
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        });
        return response;
    } catch (error) {
        return error.response;
    }
}

