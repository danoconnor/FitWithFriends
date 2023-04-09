'use strict';
const debug = require('debug');
const express = require('express');
const path = require('path');
const favicon = require('serve-favicon');
const logger = require('morgan');
const cookieParser = require('cookie-parser');
const bodyParser = require('body-parser');

const routes = require('./routes/index');
const users = require('./routes/users');
const oauth = require('./routes/auth');
const competitions = require('./routes/competitions');
const activityData = require('./routes/activityData');
const pushNotifications = require('./routes/pushNotifications');
const wellKnown = require('./routes/wellKnown');
const globalConfig = require('./utilities/globalConfig')

const oauthServer = require('./oauth/server');
const config = require('./utilities/globalConfig');

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');

// uncomment after placing your favicon in /public
//app.use(favicon(__dirname + '/public/favicon.ico'));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

// Lowercase all query params so we don't need to worry about casing
app.use(function (req, res, next) {
    for (const key in req.query) {
        req.query[key.toLowerCase()] = req.query[key];
    }
    next();
});

app.use('/', routes);
app.use('/oauth', oauth);
app.use('/users', users);
app.use('/competitions', oauthServer.authenticate(), competitions);
app.use('/activityData', oauthServer.authenticate(), activityData);
app.use('/pushNotifications', oauthServer.authenticate(), pushNotifications);
app.use('/.well-known', wellKnown);

// catch 404 and forward to error handler
app.use(function (req, res, next) {
    const err = new Error('Not Found');
    err.status = 404;
    next(err);
});

// error handlers

 app.use(function (err, req, res, next) {
     res.status(err.status || 500);
     const errorToSend = globalConfig.sendErrorDetails ? err : {};

     res.render('error', {
         message: err.message,
         error: errorToSend
     });
 });

app.set('port', process.env.PORT || 3000);

const server = app.listen(app.get('port'), function () {
    debug('Express server listening on port ' + server.address().port);
});

