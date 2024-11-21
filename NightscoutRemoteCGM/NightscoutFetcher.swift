//
//  NightscoutFetcher.swift
//  NightscoutRemoteCGM
//
//  Created by Ivan Valkou on 10.10.2019.
//  Copyright © 2019 Ivan Valkou. All rights reserved.
//

import Foundation
import NightscoutKit
import LoopKit
import HealthKit
import LoopAlgorithm

final class NightscoutFetcher {
    let url: URL
    let apiSecret: String

    init(url: URL, apiSecret: String) {
        self.url = url
        self.apiSecret = apiSecret
    }
    
    public func fetchRecent(minutes: Int = 60, completion: @escaping (Result<[GlucoseEntry], Swift.Error>) -> Void) {
        
        let client = NightscoutClient(siteURL: url, apiSecret: apiSecret)
        
        let intervalLength: TimeInterval = TimeInterval(60 * minutes)
        let maxCount = (minutes / 5) * 2 // Assume 1 entry delivered every 5 minutes. Include multiplier in case multiple glucose sources.
        let interval = DateInterval(start: Date().addingTimeInterval(-intervalLength), duration: intervalLength)
        client.fetchGlucose(dateInterval: interval, maxCount: maxCount) { result in
            switch result {
            case .success(let entries):
                completion(.success(entries))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

extension GlucoseEntry: GlucoseValue {
    public var startDate: Date { date }
    public var quantity: LoopQuantity { .init(unit: .milligramsPerDeciliter, doubleValue: glucose) }
}

extension GlucoseEntry: GlucoseDisplayable {

    public var isStateValid: Bool {
        glucoseType == .meter || glucose >= 39
    }
    public var trendType: LoopKit.GlucoseTrend? {
        if let trend = trend {
            return LoopKit.GlucoseTrend(rawValue: trend.rawValue)
        } else {
            return nil
        }
    }

    public var isLocal: Bool { false }
    
    // TODO Placeholder. This functionality will come with LOOP-1311
    public var glucoseRangeCategory: GlucoseRangeCategory? {
        return nil
    }
    
    public var trendRate: LoopQuantity? {
        if let changeRate = changeRate {
            return LoopQuantity(unit: .milligramsPerDeciliterPerMinute, doubleValue: changeRate)
        } else {
            return nil
        }
    }
}
