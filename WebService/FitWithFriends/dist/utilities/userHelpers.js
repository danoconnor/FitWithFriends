"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.convertBufferToUserId = exports.convertUserIdToBuffer = void 0;
function convertUserIdToBuffer(userId) {
    return Buffer.from(userId, 'hex');
}
exports.convertUserIdToBuffer = convertUserIdToBuffer;
function convertBufferToUserId(userId) {
    return userId.toString('hex');
}
exports.convertBufferToUserId = convertBufferToUserId;
