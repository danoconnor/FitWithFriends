//
//  ActivityValueView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import SwiftUI

struct ActivityValueView: View {
    let name: String
    let unit: String
    let color: Color
    let currentValue: UInt
    let goal: UInt

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(currentValue) / Double(goal))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("\(currentValue)/\(goal)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.2))

                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)

            Text(unit.uppercased())
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ActivityValueView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 16) {
            ActivityValueView(name: "Move", unit: "Cal", color: Color.red, currentValue: 430, goal: 700)
            ActivityValueView(name: "Exercise", unit: "Min", color: Color.green, currentValue: 25, goal: 30)
            ActivityValueView(name: "Stand", unit: "h", color: Color.cyan, currentValue: 8, goal: 12)
        }
        .padding()
    }
}
