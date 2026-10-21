//
//  FlightSearchViewModel.swift
//  SkyFare
//
//  Created by Nimish Khandelwal.
//

import Combine
import Foundation

@MainActor
final class FlightSearchViewModel: ObservableObject {
    enum SearchState: Equatable {
        case idle
        case searching
        case loaded(query: FlightSearchQuery, offers: [FlightOffer])
        case failed(String)

        var isSearching: Bool {
            self == .searching
        }
    }

    @Published var form: FlightSearchForm
    @Published var activeField: AirportField?

    @Published private(set) var originSuggestions: [Airport] = []
    @Published private(set) var destinationSuggestions: [Airport] = []
    @Published private(set) var loadingFields: Set<AirportField> = []
    @Published private(set) var suggestionError: String?
    @Published private(set) var state: SearchState = .idle
    @Published private(set) var validationMessage: String?
    @Published private(set) var canSearch = false

    private let airportRepository: AirportRepository
    private let offerRepository: FlightOfferRepository
    private let debounceInterval: DispatchQueue.SchedulerTimeType.Stride
    private let scheduler: DispatchQueue

    private var cancellables: Set<AnyCancellable> = []
    private var suggestionTasks: [AirportField: Task<Void, Never>] = [:]
    private var searchTask: Task<Void, Never>?

    init(
        airportRepository: AirportRepository,
        offerRepository: FlightOfferRepository,
        form: FlightSearchForm = FlightSearchForm(),
        debounceInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(350),
        scheduler: DispatchQueue = .main
    ) {
        self.airportRepository = airportRepository
        self.offerRepository = offerRepository
        self.form = form
        self.debounceInterval = debounceInterval
        self.scheduler = scheduler

        bindValidation()
        bindAirportSuggestions()
    }

    deinit {
        suggestionTasks.values.forEach { $0.cancel() }
        searchTask?.cancel()
    }

    func suggestions(for field: AirportField) -> [Airport] {
        switch field {
        case .origin: return originSuggestions
        case .destination: return destinationSuggestions
        }
    }

    func isLoadingSuggestions(for field: AirportField) -> Bool {
        loadingFields.contains(field)
    }

    func select(_ airport: Airport, for field: AirportField) {
        form.select(airport, for: field)
        setSuggestions([], for: field)
        activeField = nil
    }

    func swapEndpoints() {
        form.swapEndpoints()
        originSuggestions = []
        destinationSuggestions = []
    }

    func search() {
        guard let query = form.makeQuery() else {
            state = .failed(form.validationMessage ?? "This search is not complete yet.")
            return
        }

        searchTask?.cancel()
        state = .searching

        searchTask = Task { [weak self, offerRepository] in
            do {
                let offers = try await offerRepository.offers(for: query)
                guard !Task.isCancelled else { return }
                self?.state = .loaded(query: query, offers: offers)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self?.state = .failed(Self.message(for: error))
            }
        }
    }

    func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
        state = .idle
    }

    private func bindValidation() {
        $form
            .map(\.validationMessage)
            .removeDuplicates()
            .assign(to: &$validationMessage)

        $form
            .map(\.canSearch)
            .removeDuplicates()
            .assign(to: &$canSearch)
    }

    private func bindAirportSuggestions() {
        for field in AirportField.allCases {
            $form
                .map { $0.query(for: field) }
                .removeDuplicates()
                .debounce(for: debounceInterval, scheduler: scheduler)
                .sink { [weak self] keyword in
                    self?.loadSuggestions(keyword, for: field)
                }
                .store(in: &cancellables)
        }
    }

    private func loadSuggestions(_ keyword: String, for field: AirportField) {
        suggestionTasks[field]?.cancel()

        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed == form.selection(for: field)?.displayTitle {
            setSuggestions([], for: field)
            return
        }

        form.clearSelection(for: field)

        guard trimmed.count >= DuffelAirportRepository.minimumKeywordLength else {
            setSuggestions([], for: field)
            loadingFields.remove(field)
            return
        }

        loadingFields.insert(field)
        suggestionError = nil

        suggestionTasks[field] = Task { [weak self, airportRepository] in
            do {
                let airports = try await airportRepository.airports(matching: trimmed)
                guard !Task.isCancelled else { return }
                self?.setSuggestions(airports, for: field)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self?.setSuggestions([], for: field)
                self?.suggestionError = Self.message(for: error)
            }
            self?.loadingFields.remove(field)
        }
    }

    private func setSuggestions(_ airports: [Airport], for field: AirportField) {
        switch field {
        case .origin: originSuggestions = airports
        case .destination: destinationSuggestions = airports
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
