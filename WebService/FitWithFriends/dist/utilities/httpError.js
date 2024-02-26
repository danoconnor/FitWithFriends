"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
class HttpError extends Error {
    statusCode;
    constructor(statusCode, message) {
        super(message);
        this.statusCode = statusCode;
    }
}
exports.default = HttpError;
