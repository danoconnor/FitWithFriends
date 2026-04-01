'use strict';

import express = require('express');
const router = express.Router();
import { verifyAndDecodeTransaction } from '../utilities/appleTransactionVerifier';
import { handleError } from '../utilities/errorHelpers';
import FWFErrorCodes from '../utilities/enums/FWFErrorCodes';
import * as UserQueries from '../sql/users.queries';
import { convertUserIdToBuffer } from '../utilities/userHelpers';

const expectedProductId = process.env.FWF_PRO_SUBSCRIPTION_PRODUCT_ID ?? 'com.danoconnor.FitWithFriends.pro.monthly';
const expectedBundleId = 'com.danoconnor.FitWithFriends';

// Validates a StoreKit 2 signed transaction JWS from the iOS client and updates the user's pro subscription status.
// Expects a signedTransaction in the request body.
router.post('/validateTransaction', async function (req, res) {
    const signedTransaction: string = req.body['signedTransaction'];
    if (!signedTransaction) {
        handleError(null, 400, 'Missing required parameter: signedTransaction', res);
        return;
    }

    let transactionPayload;
    try {
        transactionPayload = await verifyAndDecodeTransaction(signedTransaction);
    } catch (error) {
        handleError(error, 400, 'Failed to verify transaction', res, true, FWFErrorCodes.SubscriptionErrorCodes.InvalidTransaction);
        return;
    }

    if (transactionPayload.bundleId !== expectedBundleId || transactionPayload.productId !== expectedProductId) {
        handleError(null, 400, 'Transaction bundle ID or product ID does not match expected values', res, true, FWFErrorCodes.SubscriptionErrorCodes.InvalidTransaction);
        return;
    }

    const userId: string = res.locals.oauth.token.user.id;
    const userIdBuffer = convertUserIdToBuffer(userId);

    try {
        await UserQueries.updateUserSubscriptionInfo({
            userId: userIdBuffer,
            isPro: true,
            maxActiveCompetitions: 10,
            originalTransactionId: transactionPayload.originalTransactionId,
            expiresDate: transactionPayload.expiresDate ? new Date(transactionPayload.expiresDate) : null
        });
    } catch (error) {
        handleError(error, 500, 'Failed to update user subscription info', res);
        return;
    }

    res.json({ isPro: true, maxActiveCompetitions: 10 });
});

export default router;
