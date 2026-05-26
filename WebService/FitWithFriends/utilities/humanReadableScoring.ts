import { ScoringRules } from './competitionStandingsHelper';

/**
 * Short human-readable label for a scoring rule, used by the /joinCompetition
 * web page to populate the scoring chip on the invite hero. Mirrors the iOS
 * `ScoringRules.humanReadableDescription` style but kept to a single phrase
 * so it fits on a chip.
 */
export function humanReadableScoring(rules: ScoringRules): string {
    switch (rules.kind) {
        case 'rings':
            return 'Activity rings';
        case 'workouts':
            switch (rules.metric) {
                case 'duration': return 'Tracked workouts · minutes';
                case 'calories': return 'Tracked workouts · calories';
                case 'distance': return 'Tracked workouts · distance';
            }
            // exhaustive
            return 'Tracked workouts';
        case 'daily':
            return rules.metric === 'steps' ? 'Daily steps' : 'Daily distance';
    }
}
