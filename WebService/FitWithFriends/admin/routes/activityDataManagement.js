'use strict';
const database = require('../../utilities/database');
const errorHelpers = require('../../utilities/errorHelpers');
const express = require('express');
const router = express.Router();

router.get('/test', function (req, res) {
    res.send('Hello world');
});

router.post('/cleanup', function (req, res) {
    
});

module.exports = router;