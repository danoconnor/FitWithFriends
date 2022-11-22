'use strict';
var debug = require('debug');
var express = require('express');
var path = require('path');
var favicon = require('serve-favicon');
var logger = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');

var routes = require('./routes/index');
var users = require('./routes/users');
var oauth = require('./routes/auth');
const competitions = require('./routes/competitions');
const activityData = require('./routes/activityData');
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
    for (var key in req.query) {
        req.query[key.toLowerCase()] = req.query[key];
    }
    next();
});

app.use('/', routes);
app.use('/oauth', oauth);
app.use('/users', users);
app.use('/competitions', oauthServer.authenticate(), competitions);
app.use('/activityData', oauthServer.authenticate(), activityData);
app.use('/.well-known', wellKnown);

// catch 404 and forward to error handler
app.use(function (req, res, next) {
    var err = new Error('Not Found');
    err.status = 404;
    next(err);
});

// error handlers

// TODO: removed for testing
// app.use(function (err, req, res, next) {
//     res.status(err.status || 500);
//     var errorToSend = globalConfig.sendErrorDetails ? err : {};

//     res.render('error', {
//         message: err.message,
//         error: errorToSend
//     });
// });

app.set('port', process.env.PORT || 3000);

var server = app.listen(app.get('port'), function () {
    debug('Express server listening on port ' + server.address().port);
});
