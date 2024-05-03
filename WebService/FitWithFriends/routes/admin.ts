'use strict';
import * as express from 'express';
import * as CompetitionQueries from '../sql/competitions.queries';
import { CompetitionState } from '../utilities/enums/competitionState';
import { handleError } from '../utilities/errorHelpers';

const router = express.Router();

router.post('/performDailyTasks', function (req, res) {
    // TODO: Cleanup expired tokens
    const processCompetitionsTask = processesRecentlyEndedCompetitions();
    const archiveCompetitionsTask = archiveCompetitions();
    
    Promise.all([processCompetitionsTask, archiveCompetitionsTask])
        .then(() => {
            console.log('Daily tasks completed');
            res.sendStatus(200);
        })
        .catch(err => {
            handleError(err, 500, 'Error performing daily tasks', res);
        });
});

// Get recently ended competitions
// Move them to the processing state
// Send push notifications to users
async function processesRecentlyEndedCompetitions() {
    const now = new Date();
    const competitionsToMoveToProcessing = await CompetitionQueries.getCompetitionsInState({ 
        state: CompetitionState.NotStartedOrActive, 
        finishedBeforeDate: now
     });
}

// Get competitions that have been in the processing state for more than 24 hours
// Move them to the archived state and archive results
// Send final results push notifications
async function archiveCompetitions() {
    const now = new Date();
    const olderThan24Hrs = new Date(now.getTime() - (24 * 60 * 60 * 1000));
     const competitionsToArchive = await CompetitionQueries.getCompetitionsInState({ 
        state: CompetitionState.ProcessingResults,
        finishedBeforeDate: olderThan24Hrs
     });
}

export default router;