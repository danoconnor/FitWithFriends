import * as ActivityDataQueries from '../sql/activityData.queries';
import * as CompetitionQueries from '../sql/competitions.queries';
import * as UserQueries from '../sql/users.queries';
import { convertUserIdToBuffer } from '../utilities/userHelpers';

export interface UserPoints {
    userId: string;
    firstName: string;
    lastName: string;
    activityPoints: number;
    pointsToday: number;
};

export async function getCompetitionStandings(
    competitionInfo: CompetitionQueries.IGetCompetitionDescriptionDetailsResult, 
    users: Array<UserQueries.IGetUsersInCompetitionResult>,
    timeZone: string): Promise<{ [userId: string]: UserPoints }> {
    // Make sure we use the date that matches the competition timezone
    let currentDateStr = new Date().toLocaleDateString('en-US', { timeZone });
    let currentDate = new Date(currentDateStr);

    var userPoints: { [userId: string]: UserPoints } = {};
    users.forEach(row => {
        userPoints[row.userId] = {
            userId: row.userId,
            firstName: row.first_name,
            lastName: row.last_name,
            activityPoints: 0,
            pointsToday: 0
        };
    });

    const userIdList = users.map(row => convertUserIdToBuffer(row.userId));
    const activitySummaries = await ActivityDataQueries.getActivitySummariesForUsers({ userIds: userIdList, startDate: competitionInfo.start_date, endDate: competitionInfo.end_date })
    
    // We allow users to score up to 600 total points per day (matching Apple's activity ring competition rules)
    // This will eventually change when we allow users to define custom scoring rules, but for now we will stick with Apple's rules
    const maxPointsPerDay = 600;
    activitySummaries.forEach(row => {
        var points = 0;

        // Avoid divide-by-zero errors
        if (row.calories_goal > 0) {
            points += row.calories_burned / row.calories_goal * 100;
        }

        if (row.exercise_time_goal > 0) {
            points += row.exercise_time / row.exercise_time_goal * 100;
        }

        if (row.stand_time_goal > 0) {
            points += row.stand_time / row.stand_time_goal * 100;
        }
        
        const pointsScoredThisDay = Math.min(points, maxPointsPerDay);
        userPoints[row.userId].activityPoints += pointsScoredThisDay;

        if (row.date.getDay() === currentDate.getDay() && row.date.getMonth() === currentDate.getMonth() && row.date.getFullYear() === currentDate.getFullYear()) {
            userPoints[row.userId].pointsToday = pointsScoredThisDay;
        }
    });

    return userPoints;
}