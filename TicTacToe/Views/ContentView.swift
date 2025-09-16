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
    
    private var mappedDifficulty: AIDifficulty {
        switch selectedDifficulty.lowercased() {
        case "easy": return .easy
        case "medium": return .medium
        default: return .hard
        }
    }
    
    // false = AI mode, true = PvP (to match GameLogicModel.makeMove's gameType)
    private var mappedGameTypeIsPVP: Bool {
        selectedGameMode == "P v P"
    }
    
    private var startingPlayerIsO: Bool {
        selectedPlayer == "O"
    }
    
    private var configurationSummary: String {
        if mappedGameTypeIsPVP {
            return "PvP • \(selectedPlayer) starts"
        } else {
            let aiSide = startingPlayerIsO ? "X" : "O"
            return "AI: \(aiSide) • \(selectedDifficulty)"
        }
    }
    
    private var startButtonDisabled: Bool {
        false
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                background
                ScrollView {
                    VStack(spacing: 24) {
                        heroHeader
                        configurationCard
                        startButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 600)
                    .navigationDestination(isPresented: $showGame) {
                        GameBoardView(
                            onExit: { showGame = false },
                            viewModel: viewModel,
                            ticTacToe: ticTacToeModel,
                            gameTypeIsPVP: mappedGameTypeIsPVP,
                            difficulty: mappedDifficulty,
                            startingPlayerIsO: startingPlayerIsO
                        )
                    }
                }
            }
            .navigationTitle("Tic Tac Toe")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Header
    private var heroHeader: some View {
        VStack(spacing: 12) {
            // App “mark” — replace with your app icon if desired
            Text("⭕️❌")
                .font(.system(size: 56))
                .accessibilityHidden(true)
            
            Text("Ready to play?")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
            
            Text("Choose your setup and start a game.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // Dynamic summary chip
            Text(configurationSummary)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
                .overlay(
                    Capsule().strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                )
                .accessibilityLabel("Current configuration: \(configurationSummary)")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Configuration
    private var configurationCard: some View {
        VStack(spacing: 20) {
            // Player
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Player")
                        .font(.headline)
                    Spacer()
                    Text(selectedPlayer)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                
                Picker("Player", selection: $selectedPlayer) {
                    ForEach(["X", "O"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Select your mark")
                .onChange(of: selectedPlayer) { _, _ in
                    // No-op: keep explicit in case you want to auto-adjust difficulty or hints later
                }
                
                Text("Choose whether you play as X or O. X moves first.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            // Game Mode
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Game Mode")
                        .font(.headline)
                    Spacer()
                    Text(selectedGameMode)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                
                Picker("Mode", selection: $selectedGameMode) {
                    ForEach(["AI", "P v P"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Select game mode")
                .onChange(of: selectedGameMode) { _, newValue in
                    // Gentle defaults:
                    // If switching to PvP, default to X (conventional start), but respect user choice if they change it back.
                    if newValue == "P v P" {
                        if selectedPlayer != "X" {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedPlayer = "X"
                            }
                        }
                    }
                }
                
                Text("Play against AI or with a friend on the same device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            // Difficulty
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("AI Difficulty")
                        .font(.headline)
                    Spacer()
                    Text(selectedDifficulty)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .opacity(mappedGameTypeIsPVP ? 0.5 : 1.0)
                        .accessibilityHidden(true)
                }
                
                Picker("Difficulty", selection: $selectedDifficulty) {
                    ForEach(["Easy", "Medium", "Hard"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                .disabled(mappedGameTypeIsPVP)
                .opacity(mappedGameTypeIsPVP ? 0.5 : 1.0)
                .accessibilityLabel("Select AI difficulty")
                
                Text("Hard plays optimally using minimax.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .opacity(mappedGameTypeIsPVP ? 0.5 : 1.0)
            }
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
        .animation(.easeInOut(duration: 0.2), value: selectedGameMode)
        .animation(.easeInOut(duration: 0.2), value: selectedDifficulty)
        .animation(.easeInOut(duration: 0.2), value: selectedPlayer)
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                startGame()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill")
                    .imageScale(.large)
                Text("Start Game")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.accentColor.opacity(0.35), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(startButtonDisabled)
        .opacity(startButtonDisabled ? 0.6 : 1.0)
        .padding(.top, 4)
        .accessibilityLabel("Start game")
        .accessibilityHint("Starts a new game with the selected configuration")
    }
    
    // MARK: - Background
    private var background: some View {
        Group {
            Color(UIColor.systemGroupedBackground)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Start
    private func startGame() {
        // Reset and configure model before starting
        ticTacToeModel.resetGame()
        
        // Configure who the AI is if playing vs AI
        if mappedGameTypeIsPVP == false {
            // If user selected O, AI is X; else AI is O
            ticTacToeModel.aiPlays = startingPlayerIsO ? .x : .o
        }
        
        // playerToMove: false means X to move, true means O to move
        ticTacToeModel.playerToMove = startingPlayerIsO
        
        // Navigate to game
        showGame = true
    }
}

#Preview {
    ContentView()
}
