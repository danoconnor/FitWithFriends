'use strict';
import debug from 'debug';
import express from 'express';
import path from 'path';
import favicon from 'serve-favicon';
import logger from 'morgan';
import cookieParser from 'cookie-parser';
import bodyParser from 'body-parser';

import routes from './routes/index';
import users from './routes/users';
import oauth from './routes/auth';
import competitions from './routes/competitions';
import activityData from './routes/activityData';
import admin from './routes/admin';
import pushNotifications from './routes/pushNotifications';
import wellKnown from './routes/wellKnown';
import { sendErrorDetails } from './utilities/errorHelpers';
import HttpError from './utilities/httpError';
import { authenticateAdmin } from './utilities/adminAuthenticator';

import oauthServer from './oauth/server';

var app = express();

// view engine setup
app.set('views', path.join(__dirname, '../views'));
app.set('view engine', 'pug');

// uncomment after placing your favicon in /public
//app.use(favicon(__dirname + '/public/favicon.ico'));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, '../public')));

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
app.use('/admin', authenticateAdmin, admin);
app.use('/.well-known', wellKnown);

// catch 404 and forward to error handler
app.use(function (req, res, next) {
    const err = new HttpError(404, 'Not Found');
    next(err);
});

// error handlers
 app.use(function (err, _req, res, next) {
    res.status(err.statusCode || 500);
    const errorToSend = sendErrorDetails ? err : {};
    console.error(err.message);

    res.render('error', {
        message: err.message,
        error: errorToSend
    });
 });

app.set('port', process.env.PORT || 3000);

const server = app.listen(app.get('port'), function () {
    const address = server.address();
    if (address != null && typeof address !== 'string') {
        console.log('Express server listening on port ' + address.port);
    } else {
        console.log('Express server listening on port ' + app.get('port'));
    }
});

