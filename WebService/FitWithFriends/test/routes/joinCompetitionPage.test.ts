import * as RequestUtilities from '../testUtilities/testRequestUtilities';

/*
    Tests the GET /joinCompetition web page route.
    This page is shown when a user opens a competition invite link on a device
    that does not automatically deep-link into the app.
*/

const VALID_PARAMS = 'joinCompetition?competitionid=abc123&competitiontoken=tok456';

const USER_AGENTS = {
    iPhone: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
    // iPadOS 13+ intentionally reports as macOS to request desktop sites
    iPadOS13: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',
    mac: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    android: 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.6367.82 Mobile Safari/537.36',
    windows: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
};

// ── Parameter validation ──────────────────────────────────────────────────────

test('Returns 400 when competitionId is missing', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(
        'joinCompetition?competitiontoken=tok456',
        USER_AGENTS.iPhone
    );
    expect(response.status).toBe(400);
});

test('Returns 400 when competitionToken is missing', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(
        'joinCompetition?competitionid=abc123',
        USER_AGENTS.iPhone
    );
    expect(response.status).toBe(400);
});

// ── iOS devices: should see the App Store CTA ─────────────────────────────────

test('iPhone: shows App Store button and deep link', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(VALID_PARAMS, USER_AGENTS.iPhone);
    expect(response.status).toBe(200);
    expect(response.data).toContain('appstore-btn');
    expect(response.data).toContain('Download on the App Store');
    expect(response.data).toContain('Open Fit With Friends');
    expect(response.data).not.toContain('ios-only-banner');
});

// iPadOS 13+ sends a macOS UA, so we treat macOS as potentially iOS to avoid
// falsely blocking iPad users.
test('macOS/iPadOS UA: shows App Store button (treated as potentially iOS)', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(VALID_PARAMS, USER_AGENTS.iPadOS13);
    expect(response.status).toBe(200);
    expect(response.data).toContain('appstore-btn');
    expect(response.data).not.toContain('ios-only-banner');
});

// ── Non-iOS devices: should see the blocking error ───────────────────────────

test('Android: shows iOS-only banner, no App Store button', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(VALID_PARAMS, USER_AGENTS.android);
    expect(response.status).toBe(200);
    expect(response.data).toContain('ios-only-banner');
    expect(response.data).not.toContain('appstore-btn');
});

test('Windows: shows iOS-only banner, no App Store button', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(VALID_PARAMS, USER_AGENTS.windows);
    expect(response.status).toBe(200);
    expect(response.data).toContain('ios-only-banner');
    expect(response.data).not.toContain('appstore-btn');
});

test('No User-Agent: shows iOS-only banner, no App Store button', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(VALID_PARAMS, '');
    expect(response.status).toBe(200);
    expect(response.data).toContain('ios-only-banner');
    expect(response.data).not.toContain('appstore-btn');
});
