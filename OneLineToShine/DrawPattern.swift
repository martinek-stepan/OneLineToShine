//
//  DrawPattern.swift
//  OneLineToShine
//
//  Created by Stepan Martinek on 22/11/2017.
//  Copyright © 2017 Štěpán Martinek. All rights reserved.
//

import Foundation


class DrawPattern
{
    var points: [NeibPoint]
    var name: String
    
    init(_ patternName: String, _ arr:[NeibPoint])
    {
        name = patternName
        points = arr;
    }
}
