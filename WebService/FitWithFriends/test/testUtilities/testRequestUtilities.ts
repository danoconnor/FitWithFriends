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

export async function makeGetRequest(relativeUrl: string, authToken: string | undefined = undefined, contentType: string | undefined = undefined): Promise<any> {
    try {
        const response = await axios.get('http://localhost:3000/' + relativeUrl,
        {
            headers: getHeaders(authToken, contentType)
        });
        return response;
    } catch (error) {
        return error.response;
    }
}

// Admin request helpers that use the special admin authorization header
export async function makeAdminPostRequest(relativeUrl: string, requestBody: any, contentType: string | undefined = undefined): Promise<any> {
    try {
        const response = await axios.post('http://localhost:3000/' + relativeUrl, requestBody,
        {
            headers: getAdminHeaders(contentType)
        });
        return response;
    } catch (error) {
        return error.response;
    }
}

export async function makeAdminGetRequest(relativeUrl: string, contentType: string | undefined = undefined): Promise<any> {
    try {
        const response = await axios.get('http://localhost:3000/' + relativeUrl,
        {
            headers: getAdminHeaders(contentType)
        });
        return response;
    } catch (error) {
        return error.response;
    }
}

function getAdminHeaders(contentType: string | undefined): any {
    return {
        'Authorization': 'some_admin_secret', // Use the admin secret that is hardcoded in the .env file
        'Content-Type': contentType ? contentType : 'application/json'
    };
}

function getHeaders(authToken: string | undefined, contentType: string | undefined): any {
    return {
        // If no auth token provided for this request, use client authentication with the default client secret that is setup in the SetupTestData.sql file
        'Authorization': authToken ? 'Bearer ' + authToken : 'Basic NkE3NzNDMzItNUVCMy00MUM5LTgwMzYtQjk5MUI1MUYxNEY3OjExMjc5RUQ0LTI2ODctNDA4RC05QUU3LTIyQUIzQ0E0MTIxOQ==',
        'Content-Type': contentType ? contentType : 'application/json'
    };
}