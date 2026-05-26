'use strict';
import { handleError } from '../utilities/errorHelpers';
import express from 'express';
import { UAParser } from 'ua-parser-js';
import * as CompetitionQueries from '../sql/competitions.queries';
import { parseScoringRules } from '../utilities/competitionStandingsHelper';
import { humanReadableScoring } from '../utilities/humanReadableScoring';

const router = express.Router();

/* GET home page. */
router.get('/', function (req, res) {
const appStoreUrl = 'https://itunes.apple.com/app/apple-store/id1620795451';
    res.render('index', { title: 'Fit With Friends', appStoreUrl });
});

router.get('/privacyPolicy', function (req, res) {
    res.render('privacyPolicy', { title: 'Fit With Friends Privacy Policy' });
});

router.get('/support', function (req, res) {
    res.render('support', { title: 'Fit With Friends Support' });
});

router.get('/joinCompetition', async function (req, res) {
    // All incoming query params are lowercased
    const competitionID = req.query['competitionid'];
    const competitionToken = req.query['competitiontoken'];

    if (!competitionID || typeof competitionID !== 'string' ||
        !competitionToken || typeof competitionToken !== 'string') {
        handleError(null, 400, 'Missing required query param', res, true);
        return;
    }

    const ua = UAParser(req.headers['user-agent'] ?? '');
    const os = ua.os.name ?? '';
    // iPadOS 13+ reports the same UA as macOS, so treat Mac as potentially iOS
    const isIOS = os === 'iOS' || os === 'macOS';

    const appStoreUrl = 'itms-apps://itunes.apple.com/app/apple-store/id1620795451';
    const appDeeplink = 'fitwithfriends://joinCompetition?competitionToken=' + competitionToken + '&competitionId=' + competitionID;

    // Try to expand the token into competition metadata. On failure (bad token,
    // database error) fall back to the anonymous version so the link still
    // takes the visitor to the App Store.
    const competition = await loadCompetitionInvite(competitionID, competitionToken);

    if (!competition) {
        res.render('joinCompetition', {
            title: 'Fit With Friends',
            isIOS,
            appStoreUrl,
            appDeeplink,
            // No competition context — template falls back to a generic hero.
            inviterName: null,
            inviterInitials: null,
            competitionName: null,
            dateRange: null,
            visibility: null,
            scoringLabel: null,
            members: [],
            membersExtra: 0,
            memberCount: 0,
        });
        return;
    }

    res.render('joinCompetition', {
        title: 'Fit With Friends',
        isIOS,
        appStoreUrl,
        appDeeplink,
        inviterName: competition.inviterName,
        inviterInitials: competition.inviterInitials,
        competitionName: competition.competitionName,
        dateRange: competition.dateRange,
        visibility: competition.visibility,
        scoringLabel: competition.scoringLabel,
        members: competition.previewMembers,
        membersExtra: competition.membersExtra,
        memberCount: competition.memberCount,
    });
});

interface CompetitionInvite {
    inviterName: string;
    inviterInitials: string;
    competitionName: string;
    dateRange: string;
    visibility: 'Public' | 'Private';
    scoringLabel: string;
    previewMembers: Array<{ firstName: string; initials: string }>;
    membersExtra: number;
    memberCount: number;
}

/**
 * Looks up the competition referenced by `competitionId` + `accessToken` and
 * returns the metadata needed to render the new invite page. Returns null when
 * the token is invalid or the database call fails — callers should fall back
 * to the anonymous template in that case.
 */
async function loadCompetitionInvite(competitionId: string, accessToken: string): Promise<CompetitionInvite | null> {
    try {
        const rows = await CompetitionQueries.getCompetitionInviteDetails({
            competitionId,
            competitionAccessToken: accessToken,
        });
        if (rows.length === 0) return null;
        const row = rows[0];

        const isPublic: boolean = row.is_public === true;
        const startDate = new Date(row.start_date);
        const endDate = new Date(row.end_date);
        const dateRange = formatDateRange(startDate, endDate);
        const scoringLabel = humanReadableScoring(parseScoringRules(row.scoring_rules));

        const adminFirst = row.admin_first_name ?? '';
        const adminLast = row.admin_last_name ?? '';
        const inviterName = [adminFirst, adminLast].filter(s => s.length > 0).join(' ') || adminFirst;

        const memberRows = Array.isArray(row.members)
            ? (row.members as Array<{ firstName: string; lastName: string | null }>)
            : [];
        const previewMembers = memberRows.slice(0, 5).map(m => ({
            firstName: m.firstName,
            initials: initialsFor(m.firstName, m.lastName ?? ''),
        }));
        const memberCount = typeof row.member_count === 'number' ? row.member_count : memberRows.length;

        return {
            inviterName,
            inviterInitials: initialsFor(adminFirst, adminLast),
            competitionName: row.display_name,
            dateRange,
            visibility: isPublic ? 'Public' : 'Private',
            scoringLabel,
            previewMembers,
            membersExtra: Math.max(0, memberCount - previewMembers.length),
            memberCount,
        };
    } catch (err) {
        console.error('Failed to load competition invite details', err);
        return null;
    }
}

function initialsFor(first: string, last: string): string {
    const a = first.trim().charAt(0).toUpperCase();
    const b = last.trim().charAt(0).toUpperCase();
    return `${a}${b}`;
}

function formatDateRange(start: Date, end: Date): string {
    const opts: Intl.DateTimeFormatOptions = { month: 'short', day: 'numeric' };
    const startStr = start.toLocaleDateString('en-US', opts);
    const endStr = end.toLocaleDateString('en-US', opts);
    return `${startStr} → ${endStr}`;
}

export default router;
