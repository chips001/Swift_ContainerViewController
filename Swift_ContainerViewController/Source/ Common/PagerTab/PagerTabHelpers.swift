//
//  PagerTabHelpers.swift
//  Swift_ContainerViewController
//
//  Created by 一木 英希 on 2019/03/22.
//  Copyright © 2019 一木 英希. All rights reserved.
//

import Foundation

enum SwipeDirection {
    case left
    case right
    case none
}

enum PagerTabBehaviour {
    case common
    case progressive(elasticIndicatorLimit: Bool)
    
    var isProgressiveIndicator: Bool {
        switch self {
        case .common:
            return false
        case .progressive:
            return true
        }
    }
    
    var isElasticIndicatorLimit: Bool {
        switch self {
        case .common:
            return false
        case .progressive(let elasticIndicatorLimit):
            return elasticIndicatorLimit
        }
    }
}
