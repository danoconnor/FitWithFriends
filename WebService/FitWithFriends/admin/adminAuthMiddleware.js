module.exports.authenticateAdminClient = function (req, res, next) {
    if (!req.client || !req.client.authorized) {
        res.send(401);
        return;
    }

    next();
}