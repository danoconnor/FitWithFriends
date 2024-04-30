export enum CompetitionState {
    // The competition has not started yet or is currently active
    // This is the default state when a new competition is created
    NotStartedOrActive = 1,

    // The competition has recently ended and the results are being processed
    // We set this state when our daily cron job sends the push notifications to users
    // telling them that the competition has ended
    ProcessingResults = 2,

    // The competition has ended and the results are available
    // The results have been moved to the archive table in the database
    // We set this state when our daily cron job sends the final results push notifications
    Archived = 3
}