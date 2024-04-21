import * as TestSQL from '../testUtilities/sql/testQueries.queries';
import * as RequestUtilities from '../testUtilities/testRequestUtilities';
import * as AuthUtilities from '../testUtilities/testAuthUtilities';
import { convertUserIdToBuffer } from '../../utilities/userHelpers';

/*
    Tests the /activityData routes
*/

// The userId that will be created in the database during the test setup
const testUserId = Math.random().toString().slice(2, 8);

beforeEach(async () => {
    try {
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

afterEach(async () => {
    await TestSQL.clearDataForUser({ userId: convertUserIdToBuffer(testUserId) });
});

test('Add activityData happy path', async () => {
    const expectedData = {
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    };

    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', { values: [expectedData] }, token);
    expect(response.status).toBe(200);
    
    // Validate that the data was inserted into the database
    const activityDatas = await TestSQL.getActivitySummariesForUser({ userId: convertUserIdToBuffer(testUserId) });
    expect(activityDatas.length).toBe(1);

    const activityData = activityDatas[0];
    expect(activityData).not.toBeUndefined();
    compareActivityDataResultToExpected(activityData, expectedData);
});

test('Add activityData update data for existing date', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);

    // Insert the initial data
    var response = await RequestUtilities.makePostRequest('activityData/dailySummary', { values: [{
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    }] },
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

    response = await RequestUtilities.makePostRequest('activityData/dailySummary', { values: [newUpdateData] }, token);
    expect(response.status).toBe(200);

    // Validate that the data was updated in the database
    const activityDatas = await TestSQL.getActivitySummariesForUser({ userId: convertUserIdToBuffer(testUserId) });
    expect(activityDatas.length).toBe(1);
    
    const activityData = activityDatas[0];
    compareActivityDataResultToExpected(activityData, newUpdateData);
});

test('Add activityData for multiple days', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);

    const firstDayExpectedData = {
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    };
    const secondDayExpectedData = {
        date: '2021-01-02',
        activeCaloriesBurned: 200,
        activeCaloriesGoal: 600,
        exerciseTime: 30,
        exerciseTimeGoal: 60,
        standTime: 20,
        standTimeGoal: 24
    };

    var response = await RequestUtilities.makePostRequest('activityData/dailySummary', { values: [firstDayExpectedData, secondDayExpectedData] }, token);
    expect(response.status).toBe(200);

    // Validate that the data was inserted into the database
    const activityDatas = await TestSQL.getActivitySummariesForUser({ userId: convertUserIdToBuffer(testUserId) });
    expect(activityDatas.length).toBe(2);

    const firstDayActivityDataResult = activityDatas.find(x => x.date.getUTCDate() === new Date(firstDayExpectedData.date).getUTCDate());
    expect(firstDayActivityDataResult).not.toBeUndefined();
    compareActivityDataResultToExpected(firstDayActivityDataResult, firstDayExpectedData);
    
    const secondDayActivityDataResult = activityDatas.find(x => x.date.getUTCDate() === new Date(secondDayExpectedData.date).getUTCDate());
    expect(secondDayActivityDataResult).not.toBeUndefined();
    compareActivityDataResultToExpected(secondDayActivityDataResult, secondDayExpectedData);
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
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', { values: [{
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    }] },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add activityData missing activeCaloriesBurned', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', { values: [{
        date: '2021-01-01',
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    }] },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add activityData missing activeCaloriesGoal', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', { values: [{
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    }] },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add activityData missing exerciseTime', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', { values: [{
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    }] },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add activityData missing exerciseTimeGoal', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', { values: [{
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        standTime: 10,
        standTimeGoal: 12
    }] },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add activityData missing standTime', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', { values: [{
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTimeGoal: 12
    }] },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add activityData missing standTimeGoal', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', { values: [{
        date: '2021-01-01',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10
    }] },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add activityData invalid date', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/dailySummary', { values: [{
        date: 'invalid',
        activeCaloriesBurned: 100,
        activeCaloriesGoal: 500,
        exerciseTime: 15,
        exerciseTimeGoal: 30,
        standTime: 10,
        standTimeGoal: 12
    }] },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Could not parse date');
});

test('Add one workout', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);

    const expectedData = {
        startDate: '2021-01-01',
        duration: 60 * 60,
        appleActivityTypeRawValue: 1,
        caloriesBurned: 123,
        distance: 5,
        unit: 1
    };

    const response = await RequestUtilities.makePostRequest('activityData/workouts', { values: [expectedData] }, token);
    expect(response.status).toBe(200);

    // Validate that the data was inserted into the database
    const workouts = await TestSQL.getWorkoutsForUser({ userId: convertUserIdToBuffer(testUserId) });
    expect(workouts.length).toBe(1);

    const workout = workouts[0];
    expect(workout).not.toBeUndefined();
    compareWorkoutResultToExpected(workout, expectedData);
});

test('Add multiple workouts', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);

    const expectedData = [
        {
            startDate: '2021-01-01',
            duration: 60 * 60,
            appleActivityTypeRawValue: 1,
            caloriesBurned: 354,
            distance: 5,
            unit: 1
        },
        {
            startDate: '2021-01-01',
            duration: 60 * 30,
            caloriesBurned: 200,
            appleActivityTypeRawValue: 2
        }
    ];

    const response = await RequestUtilities.makePostRequest('activityData/workouts', { values: expectedData }, token);
    expect(response.status).toBe(200);

    // Validate that the data was inserted into the database
    const workouts = await TestSQL.getWorkoutsForUser({ userId: convertUserIdToBuffer(testUserId) });
    expect(workouts.length).toBe(2);

    const firstWorkout = workouts.find(x => x.workout_type === expectedData[0].appleActivityTypeRawValue);
    expect(firstWorkout).not.toBeUndefined();
    compareWorkoutResultToExpected(firstWorkout, expectedData[0]);

    const secondWorkout = workouts.find(x => x.workout_type === expectedData[1].appleActivityTypeRawValue);
    expect(secondWorkout).not.toBeUndefined();
    compareWorkoutResultToExpected(secondWorkout, expectedData[1]);
});

test('Add workout missing token', async () => {
    // No token on the request
    const response = await RequestUtilities.makePostRequest('activityData/workouts', { values: [{
        startDate: '2021-01-01',
        duration: 60 * 60,
        appleActivityTypeRawValue: 1,
        caloriesBurned: 123,
        distance: 5,
        unit: 1
    }] });

    // The OAuth middleware treats the missing token as an invalid client request
    expect(response.status).toBe(400);
});

test('Add workout missing startDate', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/workouts', { values: [{
        duration: 60 * 60,
        appleActivityTypeRawValue: 1,
        caloriesBurned: 123,
        distance: 5,
        unit: 1
    }] },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add workout malformed start date', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/workouts', { values: [{
        startDate: 'invalid',
        duration: 60 * 60,
        appleActivityTypeRawValue: 1,
        caloriesBurned: 123,
        distance: 5,
        unit: 1
    }] },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Could not parse date');
});

test('Add workout missing duration', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/workouts', { values: [{
        startDate: '2021-01-01',
        appleActivityTypeRawValue: 1,
        caloriesBurned: 123,
        distance: 5,
        unit: 1
    }] },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add workout missing appleActivityTypeRawValue', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/workouts', { values: [{
        startDate: '2021-01-01',
        duration: 60 * 60,
        caloriesBurned: 123,
        distance: 5,
        unit: 1
    }] },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add workout missing caloriesBurned', async () => {
    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/workouts', { values: [{
        startDate: '2021-01-01',
        duration: 60 * 60,
        appleActivityTypeRawValue: 1,
        distance: 5,
        unit: 1
    }] },
    token);

    expect(response.status).toBe(400);
    expect(response.data.context).toContain('Missing required parameter');
});

test('Add workout missing distance', async () => {
    const expectedData = {
        startDate: '2021-01-01',
        duration: 60 * 60,
        appleActivityTypeRawValue: 1,
        caloriesBurned: 123,
        unit: 1
    };

    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/workouts', { values: [expectedData] },
    token);

    // Should succeed because distance is optional
    expect(response.status).toBe(200);

    // Validate that the data was inserted into the database
    const workouts = await TestSQL.getWorkoutsForUser({ userId: convertUserIdToBuffer(testUserId) });
    expect(workouts.length).toBe(1);
    compareWorkoutResultToExpected(workouts[0], expectedData);
});

test('Add workout missing unit', async () => {

    const expectedData = {
        startDate: '2021-01-01',
        duration: 60 * 60,
        appleActivityTypeRawValue: 1,
        caloriesBurned: 123,
        distance: 5
    };

    const token = await AuthUtilities.getAccessTokenForUser(testUserId);
    const response = await RequestUtilities.makePostRequest('activityData/workouts', { values: [expectedData] },
    token);

    // Should succeed because unit is optional
    expect(response.status).toBe(200);

    // Validate that the data was inserted into the database
    const workouts = await TestSQL.getWorkoutsForUser({ userId: convertUserIdToBuffer(testUserId) });
    expect(workouts.length).toBe(1);
    compareWorkoutResultToExpected(workouts[0], expectedData);
});

// Helpers

function compareActivityDataResultToExpected(result: TestSQL.IGetActivitySummariesForUserResult, expected: any) {
    expect(result.calories_burned).toBe(expected.activeCaloriesBurned);
    expect(result.calories_goal).toBe(expected.activeCaloriesGoal);
    expect(result.exercise_time).toBe(expected.exerciseTime);
    expect(result.exercise_time_goal).toBe(expected.exerciseTimeGoal);
    expect(result.stand_time).toBe(expected.standTime);
    expect(result.stand_time_goal).toBe(expected.standTimeGoal);
}

function compareWorkoutResultToExpected(result: TestSQL.IGetWorkoutsForUserResult, expected: any) {
    expect(result.duration).toBe(expected.duration);
    expect(result.workout_type).toBe(expected.appleActivityTypeRawValue);
    expect(result.calories_burned).toBe(expected.caloriesBurned);

    // The db returns null for distance and unit if they are not provided
    // so we need to check for undefined in the expected data
    expect(result.distance).toBe(expected.distance == undefined ? null : expected.distance);
    expect(result.unit).toBe(expected.unit == undefined ? null : expected.unit);
}