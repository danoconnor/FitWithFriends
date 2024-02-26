'use strict';
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const path_1 = __importDefault(require("path"));
const morgan_1 = __importDefault(require("morgan"));
const cookie_parser_1 = __importDefault(require("cookie-parser"));
const body_parser_1 = __importDefault(require("body-parser"));
const index_1 = __importDefault(require("./routes/index"));
const users_1 = __importDefault(require("./routes/users"));
const auth_1 = __importDefault(require("./routes/auth"));
const competitions_1 = __importDefault(require("./routes/competitions"));
const activityData_1 = __importDefault(require("./routes/activityData"));
const pushNotifications_1 = __importDefault(require("./routes/pushNotifications"));
const wellKnown_1 = __importDefault(require("./routes/wellKnown"));
const errorHelpers_1 = require("./utilities/errorHelpers");
const httpError_1 = __importDefault(require("./utilities/httpError"));
const server_1 = __importDefault(require("./oauth/server"));
var app = (0, express_1.default)();
// view engine setup
app.set('views', path_1.default.join(__dirname, '../views'));
app.set('view engine', 'pug');
// uncomment after placing your favicon in /public
//app.use(favicon(__dirname + '/public/favicon.ico'));
app.use((0, morgan_1.default)('dev'));
app.use(body_parser_1.default.json());
app.use(body_parser_1.default.urlencoded({ extended: false }));
app.use((0, cookie_parser_1.default)());
app.use(express_1.default.static(path_1.default.join(__dirname, '../public')));
// Lowercase all query params so we don't need to worry about casing
app.use(function (req, res, next) {
    for (const key in req.query) {
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
    const err = new httpError_1.default(404, 'Not Found');
    next(err);
});
// error handlers
app.use(function (err, _req, res, next) {
    res.status(err.statusCode || 500);
    const errorToSend = errorHelpers_1.sendErrorDetails ? err : {};
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
    }
    else {
        console.log('Express server listening on port ' + app.get('port'));
    }
});
