//
//  ContentView.swift
//  TourmalineServiceExample
//
//  Created by Brian Dennis Vega Hidalgo on 25-10-19.
//  Copyright © 2019 Brian Dennis Vega Hidalgo. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: startService) {
                        Text("Start Service")
                    }
                }
            }
            .navigationBarTitle(Text("Tourmaline Service Example"))
        }
    }
}

func startService() {
    let user: String = "User"
    let service: TLBridge = TLBridge()
    service.startTLKit(user)
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
