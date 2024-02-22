import { Response } from 'express';

// A single entry point to decide how to respond to the client in case of an error
// It will always return the given status code to the client 
// and will optionally return the errorMessage depending on global config and the alwaysSendDetails param
function handleError (error: Error | null, statusCode: number, errorMessage: string | null, res: Response<any>, alwaysSendDetails = false, customErrorCode: number | null = null) {
    res.status(statusCode);

    if (alwaysSendDetails || sendErrorDetails) {
        res.json({
            'error_details': error != null ? error.message : null,
            'context': errorMessage,
            'custom_error_code': customErrorCode
        });
    } else {
        res.send();
    }
};

// A global config for whether to send error details to the client or not
const sendErrorDetails = true;

export default handleError;