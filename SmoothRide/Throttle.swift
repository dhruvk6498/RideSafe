//
//  Throttle.swift
//  SmoothRide
//
//  Created by Dhruv Kakran on 10/7/18.
//  Copyright © 2018 Dhruv Kakran. All rights reserved.
//

import Foundation

class Throttler {
    
    private let queue: DispatchQueue = DispatchQueue.global(qos: .background)
    
    private var job: DispatchWorkItem = DispatchWorkItem(block: {})
    private var previousRun: Date = Date.distantPast
    private var maxInterval: Int
    
    init(seconds: Int) {
        self.maxInterval = seconds
    }
    
    
    func throttle(block: @escaping () -> ()) {
        job.cancel()
        job = DispatchWorkItem(){ [weak self] in
            self?.previousRun = Date()
            block()
        }
        let delay = Date.second(from: previousRun) > maxInterval ? 0 : maxInterval
        queue.asyncAfter(deadline: .now() + Double(delay), execute: job)
    }
}

private extension Date {
    static func second(from referenceDate: Date) -> Int {
        return Int(Date().timeIntervalSince(referenceDate).rounded())
    }
}


