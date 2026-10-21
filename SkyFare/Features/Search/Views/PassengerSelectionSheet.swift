//
//  PassengerSelectionSheet.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import SwiftUI

struct PassengerSelectionSheet: View {
    @Binding var passengers: PassengerSelection
    @Binding var cabin: CabinClass
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Travellers") {
                    ForEach(PassengerSelection.Kind.allCases) { kind in
                        stepperRow(for: kind)
                    }
                }

                Section("Cabin") {
                    Picker("Cabin", selection: $cabin) {
                        ForEach(CabinClass.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                if let message = passengers.validationMessage {
                    Section {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Who is flying?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("passengers.done")
                }
            }
        }
    }

    private func stepperRow(for kind: PassengerSelection.Kind) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(kind.title)
                Text(kind.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    passengers.decrement(kind)
                } label: {
                    Image(systemName: "minus.circle")
                }
                .accessibilityIdentifier("passengers.\(kind.rawValue).decrement")

                Text("\(count(for: kind))")
                    .font(.body.monospacedDigit())
                    .frame(minWidth: 20)

                Button {
                    passengers.increment(kind)
                } label: {
                    Image(systemName: "plus.circle")
                }
                .accessibilityIdentifier("passengers.\(kind.rawValue).increment")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
        }
    }

    private func count(for kind: PassengerSelection.Kind) -> Int {
        switch kind {
        case .adults: return passengers.adults
        case .children: return passengers.children
        case .infants: return passengers.infants
        }
    }
}

#Preview {
    PassengerSelectionSheet(
        passengers: .constant(PassengerSelection()),
        cabin: .constant(.economy)
    )
}
