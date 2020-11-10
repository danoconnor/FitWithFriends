'use strict';
var express = require('express');
var router = express.Router();

/* GET users listing. */
router.get('/', function (req, res) {
    res.send('respond with a resource');
});

router.get('/:userId', function (req, res) {
    if (res.locals.oauth.token.user.id !== req.params.userId) {
        res.sendStatus(401)
        return
    }

    res.send('User ID: ' + req.params.userId)
})

module.exports = router;
