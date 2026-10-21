//
//  FlightSearchView.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import SwiftUI

struct FlightSearchView: View {
    @ObservedObject var viewModel: FlightSearchViewModel
    @EnvironmentObject private var coordinator: AppCoordinator

    let isUsingSampleData: Bool

    @FocusState private var focusedField: AirportField?
    @State private var isShowingPassengers = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isUsingSampleData {
                    sampleDataBanner
                }

                tripTypePicker
                routeCard
                datesCard
                travellersCard

                if let message = viewModel.suggestionError {
                    inlineMessage(message, isError: true)
                }

                if case let .failed(message) = viewModel.state {
                    inlineMessage(message, isError: true)
                }

                searchButton
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("SkyFare")
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $isShowingPassengers) {
            PassengerSelectionSheet(
                passengers: $viewModel.form.passengers,
                cabin: $viewModel.form.cabin
            )
            .presentationDetents([.medium, .large])
        }
        .onChange(of: focusedField) { _, newValue in
            viewModel.activeField = newValue
        }
        .onChange(of: viewModel.activeField) { _, newValue in
            if newValue == nil, focusedField != nil {
                focusedField = nil
            }
        }
        .onChange(of: viewModel.state) { _, newValue in
            if case let .loaded(query, offers) = newValue {
                coordinator.showResults(query: query, offers: offers)
            }
        }
    }

    private var sampleDataBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "wifi.slash")
            VStack(alignment: .leading, spacing: 2) {
                Text("Demo data")
                    .font(.subheadline.weight(.semibold))
                Text("Add Amadeus credentials to Config/Secrets.xcconfig for live flights.")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("search.sampleDataBanner")
    }

    private var tripTypePicker: some View {
        Picker("Trip type", selection: $viewModel.form.tripType) {
            ForEach(TripType.allCases) { option in
                Text(option.title).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("search.tripType")
    }

    private var routeCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                AirportSearchField(
                    field: .origin,
                    text: $viewModel.form.originQuery,
                    selection: viewModel.form.origin,
                    suggestions: viewModel.originSuggestions,
                    isLoading: viewModel.isLoadingSuggestions(for: .origin),
                    isActive: viewModel.activeField == .origin,
                    onSelect: { viewModel.select($0, for: .origin) }
                )
                .focused($focusedField, equals: .origin)

                Button {
                    focusedField = nil
                    viewModel.swapEndpoints()
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.footnote.weight(.bold))
                        .padding(8)
                        .background(Circle().fill(Color(.tertiarySystemFill)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Swap origin and destination")
                .accessibilityIdentifier("search.swap")
            }

            Divider()

            AirportSearchField(
                field: .destination,
                text: $viewModel.form.destinationQuery,
                selection: viewModel.form.destination,
                suggestions: viewModel.destinationSuggestions,
                isLoading: viewModel.isLoadingSuggestions(for: .destination),
                isActive: viewModel.activeField == .destination,
                onSelect: { viewModel.select($0, for: .destination) }
            )
            .focused($focusedField, equals: .destination)
        }
        .cardBackground()
    }

    private var datesCard: some View {
        VStack(spacing: 12) {
            DatePicker(
                "Departure",
                selection: $viewModel.form.departureDate,
                in: viewModel.form.earliestDepartureDate...,
                displayedComponents: .date
            )
            .accessibilityIdentifier("search.departureDate")

            if viewModel.form.tripType == .roundTrip {
                Divider()
                DatePicker(
                    "Return",
                    selection: $viewModel.form.returnDate,
                    in: viewModel.form.earliestReturnDate...,
                    displayedComponents: .date
                )
                .accessibilityIdentifier("search.returnDate")
            }
        }
        .cardBackground()
    }

    private var travellersCard: some View {
        Button {
            focusedField = nil
            isShowingPassengers = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Travellers and cabin")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text("\(viewModel.form.passengers.summary) · \(viewModel.form.cabin.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .cardBackground()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("search.travellers")
    }

    private func inlineMessage(_ text: String, isError: Bool) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(isError ? Color.red : Color.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchButton: some View {
        VStack(spacing: 8) {
            Button {
                focusedField = nil
                viewModel.search()
            } label: {
                HStack(spacing: 8) {
                    if viewModel.state.isSearching {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    Text(viewModel.state.isSearching ? "Searching" : "Search flights")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSearch || viewModel.state.isSearching)
            .accessibilityIdentifier("search.submit")

            if let message = viewModel.validationMessage {
                inlineMessage(message, isError: false)
                    .accessibilityIdentifier("search.validationMessage")
            }
        }
    }
}

#Preview {
    NavigationStack {
        FlightSearchView(
            viewModel: FlightSearchViewModel(
                airportRepository: SampleAirportRepository(),
                offerRepository: SampleFlightOfferRepository()
            ),
            isUsingSampleData: true
        )
        .environmentObject(AppCoordinator())
    }
}
