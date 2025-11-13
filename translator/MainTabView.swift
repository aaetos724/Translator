//
//  MainTabView.swift
//  translator
//
//  Created by Elisa Guadalupe Alejos Torres on 10/11/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TextToSignView()
                .tabItem {
                    Label("Text", systemImage: "text.bubble")
                }
            
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}

