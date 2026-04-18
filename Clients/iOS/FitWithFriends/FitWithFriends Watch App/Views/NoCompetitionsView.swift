//
//  NoCompetitionsView.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 4/14/26.
//

import SwiftUI

struct NoCompetitionsView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy")
                .font(.system(size: 28))
                .foregroundStyle(Color("FwFBrandingColor"))
            Text("No competitions")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Join or create a competition on your iPhone to see your standings here.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("noCompetitionsView")
    }
}
