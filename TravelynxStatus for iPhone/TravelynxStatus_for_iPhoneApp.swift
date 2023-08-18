//
//  TravelynxStatus_for_iPhoneApp.swift
//  TravelynxStatus for iPhone
//
//  Created by Lola Schwan on 16.08.23.
//

import SwiftUI

@main
struct TravelynxStatus_for_iPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            
            TabView {
                StatusView()
                    .tabItem {
                        Image(systemName: "tram.fill")
                        Text("Status")
                    }
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
            }
        }
    }
}
