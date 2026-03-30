// A list of specific error codes to return to the client

export default {
    CompetitionErrorCodes: {
        // The user has too many active competitions and cannot join/create a new one
        TooManyActiveCompetitions: 10001
    },

    AuthErrorCodes: {
        // The user does not exist in the database
        UserNotFound: 20001,
    },

    SubscriptionErrorCodes: {
        // The user needs an active Pro subscription to perform this action
        ProSubscriptionRequired: 30001,
        // The App Store transaction could not be validated
        InvalidTransaction: 30002,
    }
};