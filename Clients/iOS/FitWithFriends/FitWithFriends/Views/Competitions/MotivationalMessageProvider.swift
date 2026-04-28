//
//  MotivationalMessageProvider.swift
//  FitWithFriends
//

import Foundation

enum MotivationalMessageProvider {

    private enum TimeOfDay: Int {
        case morning   // 5–11
        case afternoon // 12–16
        case evening   // 17–20
        case night     // 21–4

        static func current() -> TimeOfDay {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 5..<12:  return .morning
            case 12..<17: return .afternoon
            case 17..<21: return .evening
            default:      return .night
            }
        }
    }

    private enum ActivityLevel {
        case low    // < 200 pts  (~0–33 % of daily max)
        case medium // 200–400 pts
        case high   // > 400 pts

        static func from(points: Double) -> ActivityLevel {
            switch points {
            case ..<200:  return .low
            case ..<400:  return .medium
            default:      return .high
            }
        }
    }

    /// Returns a message that is stable for the current calendar day and activity bucket,
    /// rotating through the pool day-over-day so it doesn't feel stale.
    static func message(activityPoints: Double) -> String {
        let time = TimeOfDay.current()
        let level = ActivityLevel.from(points: activityPoints)
        let pool = messages(time: time, level: level)
        let dayIndex = Int(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970 / 86400)
        return pool[dayIndex % pool.count]
    }

    // MARK: - Message pools

    private static func messages(time: TimeOfDay, level: ActivityLevel) -> [String] {
        switch (time, level) {

        // MARK: Morning · Low
        case (.morning, .low):
            return [
                "Rise and shine — your rings are waiting.",
                "A new day, a clean slate. Let's go.",
                "Every great day starts with a single step.",
                "Morning energy is the best energy. Use it.",
                "The early mover wins. Time to start.",
                "Today is yours — kick it off right.",
                "Your body is ready. Your rings are waiting.",
                "Small moves in the morning add up fast.",
                "A little effort now saves regret tonight.",
                "No better time than right now.",
            ]

        // MARK: Morning · Medium
        case (.morning, .medium):
            return [
                "Solid start this morning. Keep it going.",
                "Already moving — now finish what you started.",
                "Nice early work. The day is on your side.",
                "You're ahead of yesterday. Build on it.",
                "Morning hustle is real. Don't stop now.",
                "Off to a great start — keep climbing.",
                "Good momentum. Don't waste it.",
                "This is the version of you that wins. Stay here.",
                "You're putting in the work. The rings see it.",
                "Morning energy locked in. Carry it forward.",
            ]

        // MARK: Morning · High
        case (.morning, .high):
            return [
                "Absolutely crushing it before noon.",
                "Most people are still warming up. You're done.",
                "Top-of-the-morning energy and you're delivering.",
                "The day hasn't peaked and you already have.",
                "Elite morning energy. The rings can barely keep up.",
                "You're lapping the field. Keep going.",
                "Morning legend behaviour.",
                "The competition checked their rings and panicked.",
                "This is what a head start looks like.",
                "Before breakfast. Impressive.",
            ]

        // MARK: Afternoon · Low
        case (.afternoon, .low):
            return [
                "The afternoon is calling. Time to move.",
                "Plenty of day left — make it count.",
                "Your rings aren't going to close themselves.",
                "A walk, a workout, anything — just go.",
                "The best time to start was this morning. Second best is now.",
                "Afternoon slump? Beat it with movement.",
                "Your body needs you right now. Let's go.",
                "Every step you take is a step ahead.",
                "The rings are patient. Are you?",
                "Get up. Move. You'll be glad you did.",
            ]

        // MARK: Afternoon · Medium
        case (.afternoon, .medium):
            return [
                "Good progress — finish the afternoon strong.",
                "You're in the zone. Keep that energy.",
                "Halfway through and looking solid.",
                "Nice work. The finish line is in sight.",
                "Afternoon grind in full effect. Don't stop.",
                "Solid effort today. Push just a little further.",
                "You've put in the work — see it through.",
                "The best part of today is still ahead.",
                "Don't leave points on the table.",
                "Momentum is your friend right now. Ride it.",
            ]

        // MARK: Afternoon · High
        case (.afternoon, .high):
            return [
                "You're absolutely crushing today.",
                "The afternoon warrior strikes again.",
                "On fire — the rings can barely keep up.",
                "Elite performance and the day isn't even over.",
                "On track for a perfect day. Incredible.",
                "Everyone else is taking a break. Not you.",
                "The competition should be worried.",
                "Honestly? Unstoppable.",
                "Afternoon MVP. No contest.",
                "You set the bar today. Proud of you.",
            ]

        // MARK: Evening · Low
        case (.evening, .low):
            return [
                "Evening calls — there's still time.",
                "Sunset workout? Best kind of workout.",
                "Don't let the day slip away. Move now.",
                "A little evening effort goes a long way.",
                "Last chance to make today count.",
                "The rings are still open. Close them.",
                "An evening push can turn the whole day around.",
                "Night is coming. Give it one good push.",
                "You've got time. Don't talk yourself out of it.",
                "Even a short burst is better than nothing.",
            ]

        // MARK: Evening · Medium
        case (.evening, .medium):
            return [
                "Evening grind paying off. Keep going.",
                "Almost there — finish the day strong.",
                "Good hustle today. Push to the finish.",
                "So close. Don't leave it here.",
                "Evening warrior mode activated.",
                "You've built a good day. Make it a great one.",
                "The finish line is right there.",
                "This close, you'd regret stopping now.",
                "Strong evening energy — use it.",
                "Just a little more. You've earned the close.",
            ]

        // MARK: Evening · High
        case (.evening, .high):
            return [
                "What a day. You've absolutely earned this.",
                "Evening excellence — this is your day.",
                "You left it all out there. Respect.",
                "Today's MVP? That's you.",
                "Closing out the day like a champion.",
                "The competition is watching. And impressed.",
                "Phenomenal effort today, top to bottom.",
                "From sunrise to sunset. You showed up.",
                "This is what a great day looks like.",
                "If today is any measure, tomorrow will be even better.",
            ]

        // MARK: Night · Low
        case (.night, .low):
            return [
                "Night owl energy — still time to move.",
                "Even a short walk counts. Go for it.",
                "Late night movement is better than none.",
                "Tomorrow starts with what you do tonight.",
                "Night shift athletes, this one's for you.",
                "A little late, but never too late.",
                "Night mode on. Still time to make a dent.",
                "The quiet hours are good for movement.",
                "Not the ideal hour, but the perfect decision.",
                "Late movers still move. Go.",
            ]

        // MARK: Night · Medium
        case (.night, .medium):
            return [
                "Night owl with a solid day. Respect.",
                "Late but putting in real work. That counts.",
                "Good effort today. Sleep will lock it in.",
                "Night mode and still going strong.",
                "Solid day's work. Rest up for tomorrow.",
                "Under the stars and still moving.",
                "Good night, great effort.",
                "You made today mean something. Sleep well.",
                "The stars are your audience. They're impressed.",
                "Quiet hours, strong numbers. Well done.",
            ]

        // MARK: Night · High
        case (.night, .high):
            return [
                "What a day. Time to recover like a champion.",
                "Late night, elite score. You're built different.",
                "Absolutely dominated today. Rest well.",
                "The stars are out and so was your best self.",
                "Day complete. Every ring closed.",
                "Champion performance, start to finish.",
                "Unreal effort today. Sleep and repeat.",
                "You earned every point. Every single one.",
                "The day is done and you won it.",
                "Lights out, winner.",
            ]
        }
    }
}
