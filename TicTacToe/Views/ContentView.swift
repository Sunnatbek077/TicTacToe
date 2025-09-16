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


struct ContentView: View {
    @State private var selectedPlayer: String = "X"
    @State private var selectedDifficulty: String = "Easy"
    @State private var selectedGameMode: String = "AI"
    @State private var showGame: Bool = false

    // Keep these as StateObjects so they persist while ContentView is alive
    @StateObject private var viewModel = ViewModel()
    @StateObject private var ticTacToeModel: TicTacToeModel

    init() {
        let vm = ViewModel()
        _viewModel = StateObject(wrappedValue: vm)
        _ticTacToeModel = StateObject(wrappedValue: TicTacToeModel(viewModel: vm))
    }
    
    var body: some View {
        if showGame {
            GameBoardView(onExit: { showGame = false }, viewModel: viewModel, ticTacToe: ticTacToeModel)
        } else {
            NavigationStack {
                List {
                    Section(header: Text("Select Player").font(.headline)) {
                        Picker("Player", selection: $selectedPlayer) {
                            ForEach(["X", "O"], id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section(header: Text("Game Mode").font(.headline)) {
                        Picker("Mode", selection: $selectedGameMode) {
                            ForEach(["AI", "P v P"], id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section(header: Text("Bot Difficulty").font(.headline)) {
                        Picker("Difficulty", selection: $selectedDifficulty) {
                            ForEach(["Easy", "Medium", "Hard"], id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                        .disabled(selectedGameMode == "P v P")
                        .opacity(selectedGameMode == "P v P" ? 0.5 : 1.0)
                    }

                    Section {
                        Button{
                            showGame = true 
                        } label: {
                            Text("Start Game")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
                .navigationTitle("Tic Tac Toe")
                .listStyle(.insetGrouped)
            }
        }
    }
}

#Preview {
    ContentView()
}
