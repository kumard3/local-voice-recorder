//
//  NetworkMonitor.swift
//  local-voice-recorder-watch Watch App
//
//  Monitors network connectivity and WiFi availability
//

import Foundation
import Network
import Combine

@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = false
    @Published var isWiFi = false
    @Published var connectionType: NWInterface.InterfaceType?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasConnected = self?.isConnected ?? false
                let wasWiFi = self?.isWiFi ?? false

                self?.isConnected = path.status == .satisfied

                // Check if connected via WiFi
                self?.isWiFi = path.usesInterfaceType(.wifi)

                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else {
                    self?.connectionType = nil
                }

                // Log network status changes
                if wasConnected != self?.isConnected || wasWiFi != self?.isWiFi {
                    print("━━━ NETWORK: Status changed - Connected: \(self?.isConnected ?? false), WiFi: \(self?.isWiFi ?? false), Type: \(String(describing: self?.connectionType))")
                }
            }
        }

        monitor.start(queue: queue)
        print("━━━ NETWORK: Monitoring started")
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    nonisolated deinit {
        monitor.cancel()
    }
}
