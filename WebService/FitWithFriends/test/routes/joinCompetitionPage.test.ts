import * as RequestUtilities from '../testUtilities/testRequestUtilities';

/*
    Tests the GET /joinCompetition web page route.
    This page is shown when a user opens a competition invite link on a device
    that does not automatically deep-link into the app.

    Class names + headline copy updated for the redesign (cta-primary instead of
    appstore-btn, "Get FitWithFriends" instead of "Download on the App Store",
    ios-banner instead of ios-only-banner).
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
    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 400 }));
});

test('Returns 400 when competitionToken is missing', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(
        'joinCompetition?competitionid=abc123',
        USER_AGENTS.iPhone
    );
    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 400 }));
});

// ── iOS devices: should see the App Store CTA ─────────────────────────────────

test('iPhone: shows App Store CTA and deeplink', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(VALID_PARAMS, USER_AGENTS.iPhone);
    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 200 }));
    expect(response.data).toContain('cta-primary');
    expect(response.data).toContain('Get FitWithFriends');
    // Deeplink CTA is also wired up for users who already have the app
    expect(response.data).toContain('Already have the app');
    expect(response.data).toContain('fitwithfriends://joinCompetition');
    expect(response.data).not.toContain('ios-banner');
});

// iPadOS 13+ sends a macOS UA, so we treat macOS as potentially iOS to avoid
// falsely blocking iPad users.
test('macOS/iPadOS UA: shows App Store CTA (treated as potentially iOS)', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(VALID_PARAMS, USER_AGENTS.iPadOS13);
    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 200 }));
    expect(response.data).toContain('cta-primary');
    expect(response.data).not.toContain('ios-banner');
});

// ── Non-iOS devices: should see the blocking banner ──────────────────────────

test('Android: shows iOS-only banner, no App Store CTA', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(VALID_PARAMS, USER_AGENTS.android);
    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 200 }));
    expect(response.data).toContain('ios-banner');
    expect(response.data).not.toContain('cta-primary');
});

test('Windows: shows iOS-only banner, no App Store CTA', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(VALID_PARAMS, USER_AGENTS.windows);
    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 200 }));
    expect(response.data).toContain('ios-banner');
    expect(response.data).not.toContain('cta-primary');
});

test('No User-Agent: shows iOS-only banner, no App Store CTA', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(VALID_PARAMS, '');
    expect({ status: response.status, body: response.data }).toEqual(expect.objectContaining({ status: 200 }));
    expect(response.data).toContain('ios-banner');
    expect(response.data).not.toContain('cta-primary');
});

// ── Anonymous fallback (invalid token) still renders the editorial chrome ────

test('Invalid token still renders an editorial fallback page', async () => {
    const response = await RequestUtilities.makeGetRequestWithUserAgent(
        'joinCompetition?competitionid=00000000-0000-0000-0000-000000000000&competitiontoken=invalid',
        USER_AGENTS.iPhone
    );
    expect(response.status).toBe(200);
    // Anonymous version still leads with the editorial "you've been invited" headline
    expect(response.data).toContain("You've been invited");
});
