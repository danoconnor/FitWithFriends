// A list of specific error codes to return to the client

export default {
    CompetitionErrorCodes: {
        // The user has too many active competitions and cannot join/create a new one
        TooManyActiveCompetitions: 10001
    },

    AuthErrorCodes: {
        // The user does not exist in the database
        UserNotFound: 20001,
    }
};