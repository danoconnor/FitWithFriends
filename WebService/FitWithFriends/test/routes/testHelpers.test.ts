import express from 'express';
import axios from 'axios';
import testHelpersRouter from '../../routes/testHelpers';

/*
    Unit tests for the /testHelpers route guard.

    These spin up a lightweight in-process Express server (not the Docker integration
    server) so FWF_ENABLE_TEST_HELPERS can be freely toggled between tests.  The guard
    middleware reads the env var at request time, so toggling process.env before each
    request is sufficient to exercise both branches without restarting any server.

    The "enabled" tests only verify that the guard lets the request through (non-401).
    The route logic will return 400 for the empty request bodies, which is fine — we are
    not testing the endpoint behaviour here, only the guard.
*/

describe('testHelpers route guard', () => {
    let baseUrl: string;
    let server: ReturnType<typeof app.listen>;

    const app = express();
    app.use(express.json());
    app.use('/testHelpers', testHelpersRouter);

    const savedEnv = process.env.FWF_ENABLE_TEST_HELPERS;

    beforeAll(done => {
        server = app.listen(0, () => {
            const addr = server.address() as { port: number };
            baseUrl = `http://localhost:${addr.port}/testHelpers`;
            done();
        });
    });

    afterAll(done => {
        restoreEnv();
        server.close(done);
    });

    afterEach(() => {
        restoreEnv();
    });

    function restoreEnv() {
        if (savedEnv === undefined) {
            delete process.env.FWF_ENABLE_TEST_HELPERS;
        } else {
            process.env.FWF_ENABLE_TEST_HELPERS = savedEnv;
        }
    }

    describe('when FWF_ENABLE_TEST_HELPERS is not set', () => {
        beforeEach(() => {
            delete process.env.FWF_ENABLE_TEST_HELPERS;
        });

        test('setUserProStatus returns 401', async () => {
            const response = await axios.post(`${baseUrl}/setUserProStatus`, {}, { validateStatus: () => true });
            expect(response.status).toBe(401);
        });

        test('seedCompetitionUsers returns 401', async () => {
            const response = await axios.post(`${baseUrl}/seedCompetitionUsers`, {}, { validateStatus: () => true });
            expect(response.status).toBe(401);
        });
    });

    describe('when FWF_ENABLE_TEST_HELPERS is set to a non-true value', () => {
        beforeEach(() => {
            process.env.FWF_ENABLE_TEST_HELPERS = 'false';
        });

        test('setUserProStatus returns 401', async () => {
            const response = await axios.post(`${baseUrl}/setUserProStatus`, {}, { validateStatus: () => true });
            expect(response.status).toBe(401);
        });

        test('seedCompetitionUsers returns 401', async () => {
            const response = await axios.post(`${baseUrl}/seedCompetitionUsers`, {}, { validateStatus: () => true });
            expect(response.status).toBe(401);
        });
    });

    describe('when FWF_ENABLE_TEST_HELPERS=true', () => {
        beforeEach(() => {
            process.env.FWF_ENABLE_TEST_HELPERS = 'true';
        });

        test('setUserProStatus passes the guard (returns non-401)', async () => {
            const response = await axios.post(`${baseUrl}/setUserProStatus`, {}, { validateStatus: () => true });
            expect(response.status).not.toBe(401);
        });

        test('seedCompetitionUsers passes the guard (returns non-401)', async () => {
            const response = await axios.post(`${baseUrl}/seedCompetitionUsers`, {}, { validateStatus: () => true });
            expect(response.status).not.toBe(401);
        });
    });
});
