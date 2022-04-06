// A single entry point to decide how to respond to the client in case of an error
// It will always return the given status code to the client 
// and will optionally return the errorMessage depending on global config and the alwaysSendDetails param
module.exports.handleError = function (error, statusCode, errorMessage, res, alwaysSendDetails = false) {
    res.status(statusCode);

    if (alwaysSendDetails || sendErrorDetails) {
        res.json({
            'error': error != null ? error.message : null,
            'context': errorMessage
        });
    } else {
        res.send();
    }
};

// A global config for whether to send error details to the client or not
const sendErrorDetails = true;