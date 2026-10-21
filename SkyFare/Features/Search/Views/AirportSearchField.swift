//
//  AirportSearchField.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import SwiftUI

struct AirportSearchField: View {
    let field: AirportField
    @Binding var text: String
    let selection: Airport?
    let suggestions: [Airport]
    let isLoading: Bool
    let isActive: Bool
    let onSelect: (Airport) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(field.title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Image(systemName: field == .origin ? "airplane.departure" : "airplane.arrival")
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                TextField(field.placeholder, text: $text)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("search.\(field.rawValue).field")

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear \(field.title)")
                }
            }

            if let selection {
                Text(selection.countryName.isEmpty ? selection.displaySubtitle : "\(selection.displaySubtitle) · \(selection.countryName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if isActive, !suggestions.isEmpty {
                suggestionList
            }
        }
    }

    private var suggestionList: some View {
        VStack(spacing: 0) {
            ForEach(suggestions) { airport in
                Button {
                    onSelect(airport)
                } label: {
                    HStack(spacing: 12) {
                        Text(airport.iataCode)
                            .font(.footnote.weight(.bold).monospaced())
                            .frame(width: 44, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(airport.cityName)
                                .font(.subheadline)
                            Text(airport.displaySubtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("search.\(field.rawValue).suggestion.\(airport.iataCode)")

                if airport != suggestions.last {
                    Divider()
                }
            }
        }
        .padding(.top, 4)
    }
}

#Preview {
    AirportSearchField(
        field: .origin,
        text: .constant("Dub"),
        selection: SampleData.dubai,
        suggestions: SampleData.airports,
        isLoading: false,
        isActive: true,
        onSelect: { _ in }
    )
    .padding()
}
