//
//  Issue.swift
//  SmoothRide
//
//  Created by Dhruv Kakran on 10/7/18.
//  Copyright © 2018 Dhruv Kakran. All rights reserved.
//

import Foundation
import MapKit
import CoreBluetooth

class Issue{
    
    let type : Int
    let location : CLLocation
    
    public init(issueType : Int, location : CLLocation){
        
        self.type = issueType
        self.location = location
        
    }
    
    public func getLocation() -> CLLocation{
        return self.location
    }
    
    
    public func getType() -> Int{
        return self.type
    }
    
}
