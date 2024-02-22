"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
// A single entry point to decide how to respond to the client in case of an error
// It will always return the given status code to the client 
// and will optionally return the errorMessage depending on global config and the alwaysSendDetails param
function handleError(error, statusCode, errorMessage, res, alwaysSendDetails, customErrorCode) {
    if (alwaysSendDetails === void 0) { alwaysSendDetails = false; }
    if (customErrorCode === void 0) { customErrorCode = null; }
    res.status(statusCode);
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
;
// A global config for whether to send error details to the client or not
var sendErrorDetails = true;
exports.default = handleError;
