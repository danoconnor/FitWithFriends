'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
var debug_1 = require("debug");
var express_1 = require("express");
var path_1 = require("path");
var morgan_1 = require("morgan");
var cookie_parser_1 = require("cookie-parser");
var body_parser_1 = require("body-parser");
var index_1 = require("./routes/index");
var users_1 = require("./routes/users");
var auth_1 = require("./routes/auth");
var competitions_1 = require("./routes/competitions");
var activityData_1 = require("./routes/activityData");
var pushNotifications_1 = require("./routes/pushNotifications");
var wellKnown_1 = require("./routes/wellKnown");
var globalConfig_1 = require("./utilities/globalConfig");
var server_1 = require("./oauth/server");
var app = (0, express_1.default)();
// view engine setup
app.set('views', path_1.default.join(__dirname, 'views'));
app.set('view engine', 'pug');
// uncomment after placing your favicon in /public
//app.use(favicon(__dirname + '/public/favicon.ico'));
app.use((0, morgan_1.default)('dev'));
app.use(body_parser_1.default.json());
app.use(body_parser_1.default.urlencoded({ extended: false }));
app.use((0, cookie_parser_1.default)());
app.use(express_1.default.static(path_1.default.join(__dirname, 'public')));
// Lowercase all query params so we don't need to worry about casing
app.use(function (req, res, next) {
    for (var key in req.query) {
        req.query[key.toLowerCase()] = req.query[key];
    }
    next();
});
app.use('/', index_1.default);
app.use('/oauth', auth_1.default);
app.use('/users', users_1.default);
app.use('/competitions', server_1.default.authenticate(), competitions_1.default);
app.use('/activityData', server_1.default.authenticate(), activityData_1.default);
app.use('/pushNotifications', server_1.default.authenticate(), pushNotifications_1.default);
app.use('/.well-known', wellKnown_1.default);
// catch 404 and forward to error handler
app.use(function (req, res, next) {
    var err = new Error('Not Found');
    err.status = 404;
    next(err);
});
// error handlers
app.use(function (err, req, res, next) {
    res.status(err.status || 500);
    var errorToSend = globalConfig_1.default.sendErrorDetails ? err : {};
    res.render('error', {
        message: err.message,
        error: errorToSend
    });
});
app.set('port', process.env.PORT || 3000);
var server = app.listen(app.get('port'), function () {
    var address = server.address();
    if (address != null && typeof address !== 'string') {
        (0, debug_1.default)('Express server listening on port ' + address.port);
    }
    else {
        (0, debug_1.default)('Express server listening on port ' + app.get('port'));
    }
});
