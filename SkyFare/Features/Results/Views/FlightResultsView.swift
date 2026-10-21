//
//  FlightResultsView.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import SwiftUI

struct FlightResultsView: View {
    @StateObject private var viewModel: FlightResultsViewModel
    @State private var isShowingFilters = false

    init(query: FlightSearchQuery, offers: [FlightOffer]) {
        _viewModel = StateObject(
            wrappedValue: FlightResultsViewModel(query: query, offers: offers)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            controls

            if viewModel.hasNoOffers {
                emptyState(
                    title: "No flights found",
                    message: "Try different dates or a nearby airport."
                )
            } else if viewModel.isEmptyAfterFiltering {
                emptyState(
                    title: "No flights match your filters",
                    message: "Loosen a filter to see more results."
                )
            } else {
                offerList
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.query.routeSummary)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingFilters) {
            FlightFilterSheet(viewModel: viewModel)
                .presentationDetents([.large])
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack {
                Text(viewModel.resultCountSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("results.count")

                Spacer()

                Button {
                    isShowingFilters = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(viewModel.filter.isActive ? "Filters (\(viewModel.filter.activeCount))" : "Filters")
                    }
                    .font(.footnote.weight(.semibold))
                }
                .accessibilityIdentifier("results.filters")
            }

            Picker("Sort", selection: $viewModel.sortOption) {
                ForEach(FlightSortOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("results.sort")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }

    private var offerList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.visibleOffers) { offer in
                    FlightOfferCard(offer: offer)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func emptyState(title: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "airplane.circle")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("results.emptyState")
    }
}

#Preview {
    NavigationStack {
        FlightResultsView(query: SampleData.query, offers: SampleData.offers)
    }
}
