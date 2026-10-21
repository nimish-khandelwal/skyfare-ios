//
//  FlightFilterSheet.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import SwiftUI

struct FlightFilterSheet: View {
    @ObservedObject var viewModel: FlightResultsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Stops") {
                    Picker("Stops", selection: $viewModel.filter.maximumStops) {
                        Text("Any").tag(Int?.none)
                        Text("Direct only").tag(Int?.some(0))
                        Text("Up to 1 stop").tag(Int?.some(1))
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Departure time") {
                    ForEach(DepartureWindow.allCases) { window in
                        toggleRow(
                            title: window.title,
                            isOn: viewModel.filter.departureWindows.contains(window)
                        ) {
                            viewModel.toggleDepartureWindow(window)
                        }
                        .accessibilityIdentifier("filter.window.\(window.rawValue)")
                    }
                }

                if !viewModel.availableCarriers.isEmpty {
                    Section("Airlines") {
                        ForEach(viewModel.availableCarriers, id: \.code) { carrier in
                            toggleRow(
                                title: carrier.displayName,
                                isOn: viewModel.filter.carrierCodes.contains(carrier.code)
                            ) {
                                viewModel.toggleCarrier(carrier.code)
                            }
                            .accessibilityIdentifier("filter.carrier.\(carrier.code)")
                        }
                    }
                }

                Section("Baggage") {
                    Toggle("Checked bag included", isOn: $viewModel.filter.checkedBagIncludedOnly)
                        .accessibilityIdentifier("filter.checkedBag")
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") { viewModel.resetFilters() }
                        .disabled(!viewModel.filter.isActive)
                        .accessibilityIdentifier("filter.reset")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Show \(viewModel.visibleOffers.count)") { dismiss() }
                        .accessibilityIdentifier("filter.apply")
                }
            }
        }
    }

    private func toggleRow(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if isOn {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FlightFilterSheet(
        viewModel: FlightResultsViewModel(query: SampleData.query, offers: SampleData.offers)
    )
}
