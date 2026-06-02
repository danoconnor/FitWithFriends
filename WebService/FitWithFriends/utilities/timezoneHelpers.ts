'use strict';

// Whether the given string is an IANA timezone the runtime can resolve. Used to
// validate client-reported timezones before storing them, and as a guard before
// scheduling notifications so a bad value can't crash the daily task.
export function isValidTimeZone(timeZone: string): boolean {
    try {
        new Intl.DateTimeFormat('en-US', { timeZone });
        return true;
    } catch {
        return false;
    }
}

// Returns the hour-of-day (0-23) at the given instant in the given IANA timezone.
// Uses hourCycle 'h23' so midnight is 0 (not 24) and the result is always 0-23.
export function getLocalHour(date: Date, timeZone: string): number {
    const hourStr = new Intl.DateTimeFormat('en-US', {
        hour: '2-digit',
        hourCycle: 'h23',
        timeZone
    }).format(date);
    return parseInt(hourStr, 10);
}

// The morning window (local time) during which end-of-competition notifications
// are delivered. Sending only within a window — rather than "any time after 8am" —
// guarantees a morning delivery: if a competition changes state during the user's
// evening/night, the notification waits for the next morning instead of firing late.
// The window also gives the hourly cron several retry attempts (e.g. for APNs
// throttling) before the morning passes.
export const NOTIFICATION_START_HOUR = 8;
export const NOTIFICATION_END_HOUR = 12;

// Whether it is currently within the morning notification window in the given
// timezone — i.e. whether an end-of-competition notification may be sent now.
export function isWithinNotificationWindow(date: Date, timeZone: string): boolean {
    const hour = getLocalHour(date, timeZone);
    return hour >= NOTIFICATION_START_HOUR && hour < NOTIFICATION_END_HOUR;
}
