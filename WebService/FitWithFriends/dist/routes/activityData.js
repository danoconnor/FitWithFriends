'use strict';
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
const errorHelpers_1 = require("../utilities/errorHelpers");
const ActivitySummaryQueries = __importStar(require("../sql/activitySummaries.queries"));
const database_1 = require("../utilities/database");
const express = __importStar(require("express"));
const router = express.Router();
router.post('/dailySummary', function (req, res) {
    const dateStr = req.body['date'];
    const caloriesBurned = req.body['activeCaloriesBurned'];
    const caloriesGoal = req.body['activeCaloriesGoal'];
    const exerciseTime = req.body['exerciseTime'];
    const exerciseTimeGoal = req.body['exerciseTimeGoal'];
    const standTime = req.body['standTime'];
    const standTimeGoal = req.body['standTimeGoal'];
    const userId = res.locals.oauth.token.user.id;
    // TODO: Other vars may be 0 - how to check that those are present?
    if (!dateStr) {
        (0, errorHelpers_1.handleError)(null, 400, 'Missing required parameter date', res);
        return;
    }
    const date = new Date(dateStr);
    if (!date) {
        (0, errorHelpers_1.handleError)(null, 400, 'Could not parse date', res);
        return;
    }
    ActivitySummaryQueries.insertActivitySummary.run({ userId, date, caloriesBurned, caloriesGoal, exerciseTime, exerciseTimeGoal, standTime, standTimeGoal }, database_1.DatabaseConnectionPool)
        .then(_result => {
        res.sendStatus(200);
    })
        .catch(error => {
        (0, errorHelpers_1.handleError)(error, 500, 'Unexpected error inserting data into database', res);
    });
});
exports.default = router;
