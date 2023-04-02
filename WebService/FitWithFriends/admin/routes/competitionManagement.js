'use strict';
const database = require('../../utilities/database');
const errorHelpers = require('../../utilities/errorHelpers');
const express = require('express');
const pushNotificationPlatform = require('../../utilities/pushNotificationPlatform');
const router = express.Router();

router.post('/updateCompletedCompetitions', function (req, res) {
    // Archive all competitions that have ended >24hrs ago
    // Send push notifications for competitions that are ended but still collecting data
    // Send push notifications for competitions that are ended and have collected data
});

module.exports = router;