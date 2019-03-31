//
//  PagerTabKind.swift
//  Swift_ContainerViewController
//
//  Created by 一木 英希 on 2019/03/21.
//  Copyright © 2019 一木 英希. All rights reserved.
//

import Foundation

enum PagerTabKind: CustomStringConvertible {
    case red
    case blue
    case yellow
    
    var description: String {
        switch self {
        case .red: return "Red"
        case .blue: return "Blue"
        case .yellow: return "Yellow"
        }
    }
}
