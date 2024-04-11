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

    var body: some View {
        VStack {
            Text(name)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(currentValue)/\(goal) \(unit.uppercased())")
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(color)
        }
    }
}

struct ActivityValueView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityValueView(name: "Move", unit: "Cal", color: Color.red, currentValue: 430, goal: 700)
    }
}
