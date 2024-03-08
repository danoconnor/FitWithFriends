import * as TestSQL from './sql/testQueries.queries';
import * as RequestUtilities from './testUtilities/testRequestUtilities';
import * as AuthUtilities from './testUtilities/testAuthUtilities';
import { convertUserIdToBuffer } from './../utilities/userHelpers';
import { couldStartTrivia } from 'typescript';

// The userId that will be created in the database during the test setup
const testUserId = '123456';

beforeEach(async () => {
    try {
        await TestSQL.clearAllData();
        await TestSQL.createUser({
            userId: convertUserIdToBuffer(testUserId),
            firstName: 'Test',
            maxActiveCompetitions: 10,
            isPro: false,
            createdDate: new Date()
        });
    } catch (error) {
        // Handle the error here
        console.log('Test setup failed: ' + error);
        throw error;
    }
});

test('Add activityData happy path', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', {
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    },
    token);

    expect(response.status).toBe(200);
});

test('Add activityData update data for existing date', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);

    // Insert the initial data
    var response = await RequestUtilities.makePostRequest('activityData/dailySummary', {
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    },
    token);
    expect(response.status).toBe(200);

    // Send an update for the same date, the DB should update the existing data
    const newUpdateData = {
        date: '2021-01-01',
        activeCaloriesBurned: 200,
        activeCaloriesGoal: 600,
        exerciseTime: 30,
        exerciseTimeGoal: 60,
        standTime: 20,
        standTimeGoal: 24
    };

    response = await RequestUtilities.makePostRequest('activityData/dailySummary', newUpdateData, token);
    expect(response.status).toBe(200);

    // Validate that the data was updated in the database
    const activityDatas = await TestSQL.getActivitySummariesForUser({ userId: convertUserIdToBuffer(testUserId) });
    expect(activityDatas.length).toBe(1);
    
    const activityData = activityDatas[0];
    expect(activityData.calories_burned).toBe(newUpdateData.activeCaloriesBurned);
    expect(activityData.calories_goal).toBe(newUpdateData.activeCaloriesGoal);
    expect(activityData.exercise_time).toBe(newUpdateData.exerciseTime);
    expect(activityData.exercise_time_goal).toBe(newUpdateData.exerciseTimeGoal);
    expect(activityData.stand_time).toBe(newUpdateData.standTime);
    expect(activityData.stand_time_goal).toBe(newUpdateData.standTimeGoal);
});

test('Add activityData for multiple days', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);

    // Insert the data for the first day
    const firstDayData = {
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    };
    var response = await RequestUtilities.makePostRequest('activityData/dailySummary', firstDayData, token);
    expect(response.status).toBe(200);

    // Insert the data for the second day
    const secondDayData = {
        date: '2021-01-02',
        activeCaloriesBurned: 200,
        activeCaloriesGoal: 600,
        exerciseTime: 30,
        exerciseTimeGoal: 60,
        standTime: 20,
        standTimeGoal: 24
    };
    response = await RequestUtilities.makePostRequest('activityData/dailySummary', secondDayData, token);
    expect(response.status).toBe(200);

    // Validate that the data was inserted into the database
    const activityDatas = await TestSQL.getActivitySummariesForUser({ userId: convertUserIdToBuffer(testUserId) });
    expect(activityDatas.length).toBe(2);

    console.log(activityDatas[0].date.getDate());
    console.log(new Date(firstDayData.date).getDate());
    const firstDayActivityData = activityDatas.find(x => x.date.getUTCDate() === new Date(firstDayData.date).getUTCDate());
    expect(firstDayActivityData).not.toBeUndefined();
    expect(firstDayActivityData.calories_burned).toBe(firstDayData.activeCaloriesBurned);
    expect(firstDayActivityData.calories_goal).toBe(firstDayData.activeCaloriesGoal);
    expect(firstDayActivityData.exercise_time).toBe(firstDayData.exerciseTime);
    expect(firstDayActivityData.exercise_time_goal).toBe(firstDayData.exerciseTimeGoal);
    expect(firstDayActivityData.stand_time).toBe(firstDayData.standTime);
    expect(firstDayActivityData.stand_time_goal).toBe(firstDayData.standTimeGoal);
    
    const secondDayActivityData = activityDatas.find(x => x.date.getUTCDate() === new Date(secondDayData.date).getUTCDate());
    expect(secondDayActivityData).not.toBeUndefined();
    expect(secondDayActivityData.calories_burned).toBe(secondDayData.activeCaloriesBurned);
    expect(secondDayActivityData.calories_goal).toBe(secondDayData.activeCaloriesGoal);
    expect(secondDayActivityData.exercise_time).toBe(secondDayData.exerciseTime);
    expect(secondDayActivityData.exercise_time_goal).toBe(secondDayData.exerciseTimeGoal);
    expect(secondDayActivityData.stand_time).toBe(secondDayData.standTime);
    expect(secondDayActivityData.stand_time_goal).toBe(secondDayData.standTimeGoal);
});

test('Add activityData missing token', async () => {
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', {
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12,
    });

    // The OAuth middleware treats the missing token as an invalid client request
    expect(response.status).toBe(400);
});

test('Add activityData missing date', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', {
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add activityData missing activeCaloriesBurned', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', {
        date: '2021-01-01',
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add activityData missing activeCaloriesGoal', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', {
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add activityData missing exerciseTime', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', {
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add activityData missing exerciseTimeGoal', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', {
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        standTime: 10,
        standTimeGoal: 12
    },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add activityData missing standTime', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', {
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTimeGoal: 12
    },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add activityData missing standTimeGoal', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', {
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10
    },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add activityData invalid date', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', {
        date: 'invalid',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Could not parse date');
});