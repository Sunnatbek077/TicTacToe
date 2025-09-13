//
//  ContentView.swift
//  TicTacToe
//
//  Created by Sunnatbek on 31/08/25.
//

import SwiftUI
import Combine
import UIKit
import Foundation

class ViewModel: ObservableObject {
    @Published var gameOver: Bool = false
    @Published var winner: SquareStatus = .empty
}

struct ContentView: View {
    // Make Trigger feedback with Taptic engine
    static func triggerHapticFeedback(type: Int, override: Bool = false) {
        let vibration = Foundation.UserDefaults.standard.value(forKey: "vibration") as? Bool
        if vibration == true || override == true {
            if type == 1 {
                let generator = UIImpactFeedbackGenerator(style: .soft)
                generator.impactOccurred()
            } else if type == 2 {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } else if type == 3 {
                let generator = UIImpactFeedbackGenerator(style: .rigid)
                generator.impactOccurred()
            } else if type == 4 {
                let generator = UIImpactFeedbackGenerator(style: .rigid)
                generator.impactOccurred()
            }
        }
    }
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            GameBoardView()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
