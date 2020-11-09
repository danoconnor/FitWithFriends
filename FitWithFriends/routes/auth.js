const path = require('path') // has path and __dirname
const express = require('express')
const oauthServer = require('../oauth/server.js')


const router = express.Router() // Instantiate a new router

router.get('/', (req, res) => {  // send back a simple form for the oauth
    res.render('login', { title: 'Login' })
})


router.post('/authorize', (req, res, next) => {
    const { username, password } = req.body
    //if (username === 'test' && password === 'test') {
    //    req.body.user = { user: 1 }
    //    return next()
    //}
    return next();

    //const params = [ // Send params back down
    //    'client_id',
    //    'redirect_uri',
    //    'response_type',
    //    'grant_type',
    //    'state',
    //]
    //    .map(a => `${a}=${req.body[a]}`)
    //    .join('&')
    //return res.redirect(`/oauth?success=false&${params}`)
}, (req, res, next) => { // sends us to our redirect with an authorization code in our url
    return next()
}, oauthServer.authorize())

router.post('/token', (req, res, next) => {
    next()
}, oauthServer.token({
    requireClientAuthentication: { // whether client needs to provide client_secret
        'authorization_code': true,
    },
}))  // Sends back token


module.exports = router