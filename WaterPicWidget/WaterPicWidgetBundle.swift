//
//  WaterPicWidgetBundle.swift
//  WaterPicWidget
//
//  Created by Marius Bringsvor Rusten on 23/02/2025.
//

import WidgetKit
import SwiftUI

@main
struct WaterPicWidgetBundle: WidgetBundle {
    var body: some Widget {
        WaterPicWidget()
        WaterPicWidgetControl()
        WaterPicWidgetLiveActivity()
    }
}
