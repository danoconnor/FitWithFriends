'use strict';
import { handleError } from '../utilities/errorHelpers';
import { verifyAndDecodeNotification, verifyAndDecodeTransaction } from '../utilities/appleTransactionVerifier';
import * as UserQueries from '../sql/users.queries';
import * as express from 'express';
import { convertBufferToUserId } from '../utilities/userHelpers';
const router = express.Router();

// Received when Apple sends a subscription state change notification
// No authentication middleware — Apple sends this as a webhook directly to the server
// We should always return 200 to Apple, even on internal errors, to prevent Apple from retrying indefinitely
router.post('/', function (req, res) {
    const signedPayload: string | undefined = req.body['signedPayload'];
    if (!signedPayload) {
        handleError(null, 400, 'Missing required parameter: signedPayload', res);
        return;
    }

    verifyAndDecodeNotification(signedPayload)
        .then(notification => {
            return verifyAndDecodeTransaction(notification.data.signedTransactionInfo)
                .then(transactionPayload => {
                    return UserQueries.getUserByOriginalTransactionId({ originalTransactionId: transactionPayload.originalTransactionId })
                        .then(users => {
                            if (!users || users.length === 0) {
                                console.warn(`App Store notification received for unknown originalTransactionId: ${transactionPayload.originalTransactionId}`);
                                res.sendStatus(200);
                                return;
                            }

                            const userIdBuffer = users[0].user_id;
                            const userId = convertBufferToUserId(userIdBuffer);
                            const notificationType = notification.notificationType;

                            if (notificationType === 'DID_RENEW') {
                                const expiresDate = transactionPayload.expiresDate != null
                                    ? new Date(transactionPayload.expiresDate)
                                    : null;

                                return UserQueries.updateUserSubscriptionInfo({
                                    userId: userIdBuffer,
                                    isPro: true,
                                    maxActiveCompetitions: 10,
                                    originalTransactionId: transactionPayload.originalTransactionId,
                                    expiresDate: expiresDate
                                }).then(() => {
                                    console.log(`Subscription renewed for user ${userId}`);
                                    res.sendStatus(200);
                                });
                            } else if (notificationType === 'EXPIRED' || notificationType === 'REVOKE' || notificationType === 'REFUND') {
                                return UserQueries.updateUserSubscriptionInfo({
                                    userId: userIdBuffer,
                                    isPro: false,
                                    maxActiveCompetitions: 1,
                                    originalTransactionId: transactionPayload.originalTransactionId,
                                    expiresDate: null
                                }).then(() => {
                                    console.log(`Subscription ended (${notificationType}) for user ${userId}`);
                                    res.sendStatus(200);
                                });
                            } else if (notificationType === 'DID_CHANGE_RENEWAL_STATUS') {
                                console.log(`Received DID_CHANGE_RENEWAL_STATUS for user ${userId} — no action taken, subscription active until expiry`);
                                res.sendStatus(200);
                            } else {
                                console.log(`Received unhandled App Store notification type: ${notificationType}`);
                                res.sendStatus(200);
                            }
                        });
                });
        })
        .catch(error => {
            // Log the error but always return 200 to prevent Apple from retrying indefinitely
            console.error('Unexpected error handling App Store notification:', error);
            res.sendStatus(200);
        });
});

export default router;
