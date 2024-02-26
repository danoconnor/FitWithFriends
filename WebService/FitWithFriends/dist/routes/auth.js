"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const server_js_1 = __importDefault(require("../oauth/server.js"));
const router = express_1.default.Router(); // Instantiate a new router
router.post('/token', (_req, _res, next) => {
    next();
}, server_js_1.default.token({
    // Send back extra properties that the model sets on the created token
    // We want this so user ID is returned with the token
    allowExtendedTokenAttributes: true
}));
exports.default = router;
