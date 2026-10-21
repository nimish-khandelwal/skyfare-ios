//
//  FlightOfferCard.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import SwiftUI

struct FlightOfferCard: View {
    let offer: FlightOffer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let outbound = offer.outbound {
                itineraryRow(outbound)
            }

            if let inbound = offer.inbound {
                Divider()
                itineraryRow(inbound)
            }

            footer
        }
        .cardBackground()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("results.offer.\(offer.id)")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(offer.validatingCarrier.displayName)
                    .font(.subheadline.weight(.semibold))
                if let designator = offer.outbound?.segments.first?.flightDesignator {
                    Text(designator)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(DisplayFormatting.price(offer.totalPrice, currencyCode: offer.currencyCode))
                    .font(.title3.weight(.bold))
                if offer.travellerCount > 1 {
                    Text("total for \(offer.travellerCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func itineraryRow(_ itinerary: Itinerary) -> some View {
        HStack(alignment: .center, spacing: 12) {
            timeColumn(itinerary.departure, alignment: .leading)

            VStack(spacing: 4) {
                Text(DisplayFormatting.duration(itinerary.duration))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ZStack {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 2)
                    Image(systemName: "airplane")
                        .font(.caption2)
                        .foregroundStyle(.tint)
                        .background(Color(.secondarySystemGroupedBackground))
                }

                Text(stopsLabel(for: itinerary))
                    .font(.caption2)
                    .foregroundStyle(itinerary.stopCount == 0 ? Color.green : Color.secondary)
            }
            .frame(maxWidth: .infinity)

            timeColumn(itinerary.arrival, alignment: .trailing, showsNextDay: itinerary.crossesMidnight)
        }
    }

    private func timeColumn(
        _ point: SegmentPoint?,
        alignment: HorizontalAlignment,
        showsNextDay: Bool = false
    ) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            HStack(spacing: 2) {
                Text(point.map { DisplayFormatting.time($0.date) } ?? "--:--")
                    .font(.title3.weight(.semibold).monospacedDigit())
                if showsNextDay {
                    Text("+1")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.orange)
                }
            }
            Text(point?.iataCode ?? "---")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            tag(
                offer.includesCheckedBag ? "Bag included" : "Cabin bag only",
                systemImage: offer.includesCheckedBag ? "suitcase.rolling.fill" : "handbag"
            )

            if let cabin = offer.cabin {
                tag(cabin.title, systemImage: "chair")
            }

            Spacer(minLength: 0)

            if let seats = offer.seatsRemaining, seats <= 4 {
                Text("\(seats) seats left")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
    }

    private func tag(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private func stopsLabel(for itinerary: Itinerary) -> String {
        let stops = DisplayFormatting.stops(itinerary.stopCount)
        let layovers = itinerary.layoverAirports

        guard !layovers.isEmpty else { return stops }
        return "\(stops) · \(layovers.joined(separator: ", "))"
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(SampleData.offers) { offer in
                FlightOfferCard(offer: offer)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
