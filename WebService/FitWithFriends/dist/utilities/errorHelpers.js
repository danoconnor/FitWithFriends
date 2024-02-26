"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleError = void 0;
// A single entry point to decide how to respond to the client in case of an error
// It will always return the given status code to the client 
// and will optionally return the errorMessage depending on global config and the alwaysSendDetails param
function handleError(error, statusCode, errorMessage, res, alwaysSendDetails = false, customErrorCode = null) {
    res.status(statusCode);
    console.error(error != null ? error.message : errorMessage);
    if (alwaysSendDetails || sendErrorDetails) {
        res.json({
            'error_details': error != null ? error.message : null,
            'context': errorMessage,
            'custom_error_code': customErrorCode
        });
    }
    else {
        res.send();
    }
}
exports.handleError = handleError;
;
// A global config for whether to send error details to the client or not
const sendErrorDetails = true;
