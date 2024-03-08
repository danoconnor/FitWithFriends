import axios from 'axios';

export async function makePostRequest(relativeUrl: string, requestBody: any, authToken: string | undefined = undefined, contentType: string | undefined = undefined): Promise<any> {
    try {
        const response = await axios.post('http://localhost:3000/' + relativeUrl, requestBody,
        {
            headers: getHeaders(authToken, contentType)
        });
        return response;
    } catch (error) {
        return error.response;
    }
}

function getHeaders(authToken: string | undefined, contentType: string | undefined): any {
    return {
        // If no auth token provided for this request, use client authentication with the default client secret that is setup in the SetupTestData.sql file
        'Authorization': authToken ? 'Bearer ' + authToken : 'Basic NkE3NzNDMzItNUVCMy00MUM5LTgwMzYtQjk5MUI1MUYxNEY3OjExMjc5RUQ0LTI2ODctNDA4RC05QUU3LTIyQUIzQ0E0MTIxOQ==',
        'Content-Type': contentType ? contentType : 'application/json'
    };
}