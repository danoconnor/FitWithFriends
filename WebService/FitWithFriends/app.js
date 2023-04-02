'use strict';
const debug = require('debug');
const express = require('express');
const path = require('path');
const favicon = require('serve-favicon');
const logger = require('morgan');
const cookieParser = require('cookie-parser');
const bodyParser = require('body-parser');
const https = require('https');
const fs = require('fs');
const { DefaultAzureCredential } = require('@azure/identity');
const { CertificateClient } = require("@azure/keyvault-certificates");
const { SecretClient } = require('@azure/keyvault-secrets');

const routes = require('./routes/index');
const users = require('./routes/users');
const oauth = require('./routes/auth');
const competitions = require('./routes/competitions');
const activityData = require('./routes/activityData');
const pushNotifications = require('./routes/pushNotifications');
const wellKnown = require('./routes/wellKnown');
const globalConfig = require('./utilities/globalConfig')

// Admin routes
const adminAuthMiddleware = require('./admin/adminAuthMiddleware');
const activityDataManagement = require('./admin/routes/activityDataManagement');
const competitionManagement = require('./admin/routes/competitionManagement');
const tokenManagement = require('./admin/routes/tokenManagement');

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

// Admin routes
app.use('/admin/activityData', adminAuthMiddleware.authenticateAdminClient, activityDataManagement);
app.use('/admin/competitions', adminAuthMiddleware.authenticateAdminClient, competitionManagement);
app.use('/admin/tokens', adminAuthMiddleware.authenticateAdminClient, tokenManagement);

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

// Require client TLS for some requests related to admin commands
// Because our app service in Azure will shutdown when there is no traffic,
// we cannot rely on the app service to run our cron jobs.
// Instead, we've created some admin endpoints that can be called by an external server
// to handle cron job type tasks like sending push notifications, archiving completed competitions, cleaning up expired tokens, etc.
// Any client calling these admin commands will need to authenticate with a client certificate so we can ensure that the request
// is coming from a trusted device.

// Need to get HTTPS cert/key and the CA for the client
const vaultUrl = process.env.AZURE_KEYVAULT_URL;
const credential = new DefaultAzureCredential();
const certClient = new CertificateClient(vaultUrl, credential);
certClient.getCertificate(process.env.HTTPS_CERT_NAME)
    .then(httpsCertSecret => {
        console.log('Cert fetch complete, fetching private key');

        // Convert HTTPS cert to PEM format
        const certBase64 = httpsCertSecret.cer.toString('base64');
        const httpsCertPem = '-----BEGIN CERTIFICATE-----\n' +
            certBase64.match(/.{1,64}/g).join('\n') +
            '\n-----END CERTIFICATE-----';

        // Parse the url to get the secret name and version
        const secretNameVersionRegex = 'https:\/\/.*\/secrets\/(.*)\/(.*)\?'
        const regexResults = httpsCertSecret.secretId.match(secretNameVersionRegex);
        const httpsKeySecretName = regexResults[1];
        const httpsKeySecretVersion = regexResults[2];

        const secretClient = new SecretClient(vaultUrl, credential);
        secretClient.getSecret(httpsKeySecretName, httpsKeySecretVersion)
            .then(httpsPrivateKeySecret => {
                console.log('HTTPS private key fetch complete');

                const clientTLSOptions = {
                    key: httpsPrivateKeySecret.value,
                    cert: httpsCertPem,
                    ca: fs.readFileSync('admin\\FWFClientTLSCA.pem'),
                    requestCert: true,
                    rejectUnauthorized: true
                };
                const clientTLSServer = https.createServer(clientTLSOptions, app);
                clientTLSServer.listen(3001);
            })
            .catch(error => {
                 console.error('Error fetching HTTPS private key on app launch: ', error);
            });
    })
    .catch(error => {
        console.error('Error fetching HTTPS cert on app launch: ', error);
    });

