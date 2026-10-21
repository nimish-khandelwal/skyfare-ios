//
//  CardStyle.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import SwiftUI

private struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

extension View {
    func cardBackground() -> some View {
        modifier(CardBackground())
    }
}
