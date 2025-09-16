//
//  GameBoardView.swift
//  TicTacToe
//
//  Created by Sunnatbek on 05/09/25.
//

import SwiftUI
import UIKit
import Combine
import Foundation

class ViewModel: ObservableObject {
    @Published var gameOver: Bool = false
    @Published var winner: SquareStatus = .empty
}

struct GameBoardView: View {
    var onExit: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: ViewModel
    @ObservedObject var ticTacToe: TicTacToeModel
    
    // Configuration coming from ContentView
    let gameTypeIsPVP: Bool        // false = AI mode, true = PvP
    let difficulty: AIDifficulty
    let startingPlayerIsO: Bool    // false = X starts, true = O starts
    
    @State private var vibro: Bool = false
    
    static func setVibro(mode: Bool) {
        UserDefaults.standard.set(mode, forKey: "vibro")
    }
    
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
    
    func buttonAction(_ index : Int) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            _ = self.ticTacToe.makeMove(index: index, gameType: gameTypeIsPVP, difficulty: difficulty)
        }
        GameBoardView.triggerHapticFeedback(type: 2)
    }
    
    var currentPlayer: String {
        self.ticTacToe.playerToMove == false ? "X" : "O"
    }
    
    var headerTitle: String { "Tic Tac Toe" }
    
    var headerSubtitle: String {
        if gameTypeIsPVP {
            return "\(currentPlayer)’s move"
        } else {
            let aiMark = ticTacToe.aiPlays == .x ? "X" : "O"
            if (ticTacToe.playerToMove == false && aiMark == "X") || (ticTacToe.playerToMove == true && aiMark == "O") {
                return "AI is thinking…"
            } else {
                return "Your move"
            }
        }
    }
    
    var modeBadgeText: String {
        if gameTypeIsPVP {
            return "PvP"
        } else {
            let aiSide = ticTacToe.aiPlays == .x ? "X" : "O"
            let diff: String = {
                switch difficulty {
                case .easy: return "Easy"
                case .medium: return "Medium"
                case .hard: return "Hard"
                }
            }()
            return "AI: \(aiSide) • \(diff)"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            header
            board
                .padding(.horizontal)
            footer
        }
        .padding(.top, 12)
        .background(background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(role: .cancel) {
                    exitToMenu()
                } label: {
                    Label("Exit", systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .imageScale(.large)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Exit to menu")
                }
            }
        }
        .onAppear {
            // Ensure starting player is applied when entering the board
            if ticTacToe.squares.allSatisfy({ $0.squareStatus == .empty }) {
                ticTacToe.playerToMove = startingPlayerIsO
            }
            // If AI mode and AI plays X and board is empty, let AI start immediately
            if gameTypeIsPVP == false,
               ticTacToe.aiPlays == .x,
               ticTacToe.squares.allSatisfy({ $0.squareStatus == .empty }) {
                // Make sure it's AI's turn (X)
                ticTacToe.playerToMove = false // false means X to move
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    let boardMoves = ticTacToe.getBoard
                    let testBoard = Board(position: boardMoves, turn: .x, lastMove: -1)
                    let answer = testBoard.bestMove(difficulty: difficulty)
                    if answer >= 0 {
                        _ = ticTacToe.makeMove(index: answer, gameType: false, difficulty: difficulty)
                    }
                }
            }
        }
        .alert(isPresented: $viewModel.gameOver, content: {
            var title = ""
            if gameTypeIsPVP == false {
                // AI mode: map winner based on which mark AI plays
                if ticTacToe.aiPlays == .x {
                    if viewModel.winner == .x { title = "AI won!" }
                    else if viewModel.winner == .o { title = "You won!" }
                    else { title = "Draw" }
                } else {
                    if viewModel.winner == .x { title = "You won!" }
                    else if viewModel.winner == .o { title = "AI won!" }
                    else { title = "Draw" }
                }
            } else {
                // PvP: neutral
                if viewModel.winner == .x { title = "X won!" }
                else if viewModel.winner == .o { title = "O won!" }
                else { title = "Draw" }
            }
            return Alert(
                title: Text(title),
                dismissButton: .default(Text("Play Again")) {
                    resetForNextRound()
                }
            )
        })
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Text(headerTitle)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
            
            Text(headerSubtitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityLabel(headerSubtitle)
            
            Text(modeBadgeText)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
                .foregroundStyle(.primary)
                .accessibilityHidden(false)
        }
        .padding(.horizontal)
    }
    
    private var board: some View {
        GeometryReader { proxy in
            // Make the board square and centered
            let side = min(proxy.size.width, proxy.size.height)
            let spacing: CGFloat = 10
            let cellSize = (side - spacing * 2) / 3
            
            VStack(spacing: spacing) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<3, id: \.self) { column in
                            let index = row * 3 + column
                            if ticTacToe.squares.indices.contains(index) {
                                SquareButtonView(
                                    dataSource: ticTacToe.squares[index],
                                    size: cellSize,
                                    action: { self.buttonAction(index) }
                                )
                            } else {
                                Color.clear.frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
            .frame(width: side, height: side, alignment: .center)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(minHeight: 360)
        .accessibilityElement(children: .contain)
    }
    
    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                resetForNextRound()
            } label: {
                Label("Restart", systemImage: "arrow.counterclockwise.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .accessibilityLabel("Restart game")
            
            Spacer(minLength: 12)
            
            Button(role: .destructive) {
                exitToMenu()
            } label: {
                Label("Exit", systemImage: "xmark.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Exit to menu")
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }
    
    private var background: some View {
        Group {
            if colorScheme == .dark {
                Color.black.opacity(0.95)
            } else {
                Color(UIColor.systemGroupedBackground)
            }
        }
        .ignoresSafeArea()
    }
    
    private func resetForNextRound() {
        self.ticTacToe.resetGame()
        // Preserve initial settings
        self.ticTacToe.playerToMove = startingPlayerIsO
        viewModel.gameOver = false
        viewModel.winner = .empty
        
        // If AI is X, let it start again
        if gameTypeIsPVP == false,
           ticTacToe.aiPlays == .x,
           ticTacToe.squares.allSatisfy({ $0.squareStatus == .empty }) {
            ticTacToe.playerToMove = false // X
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                let boardMoves = ticTacToe.getBoard
                let testBoard = Board(position: boardMoves, turn: .x, lastMove: -1)
                let answer = testBoard.bestMove(difficulty: difficulty)
                if answer >= 0 {
                    _ = ticTacToe.makeMove(index: answer, gameType: false, difficulty: difficulty)
                }
            }
        }
    }
    
    private func exitToMenu() {
        self.ticTacToe.resetGame()
        self.ticTacToe.playerToMove = startingPlayerIsO
        viewModel.gameOver = false
        viewModel.winner = .empty
        onExit()
    }
}

private struct SquareButtonView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var dataSource: Square
    let size: CGFloat
    var action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button {
            if dataSource.squareStatus == .empty {
                action()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(backgroundFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )
                    .shadow(color: shadowColor.opacity(0.12), radius: 6, x: 0, y: 3)
                    .scaleEffect(isPressed ? 0.97 : 1.0)
                    .animation(.easeOut(duration: 0.12), value: isPressed)
                
                Text(symbol)
                    .font(.system(size: size * 0.52, weight: .heavy, design: .rounded))
                    .foregroundStyle(symbolColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contentTransition(.symbolEffect(.replace))
                    .animation(.spring(response: 0.25, dampingFraction: 0.85), value: dataSource.squareStatus)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in
            withAnimation(.easeOut(duration: 0.08)) { isPressed = true }
        }.onEnded { _ in
            withAnimation(.easeOut(duration: 0.08)) { isPressed = false }
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("Double-tap to place your mark")
    }
    
    private var symbol: String {
        switch dataSource.squareStatus {
        case .x, .xw: return "X"
        case .o, .ow: return "O"
        case .empty: return ""
        }
    }
    
    private var symbolColor: Color {
        switch dataSource.squareStatus {
        case .xw, .ow:
            return .green
        default:
            return .primary
        }
    }
    
    private var backgroundFill: some ShapeStyle {
        if case .empty = dataSource.squareStatus {
            return AnyShapeStyle(.thinMaterial)
        } else {
            return AnyShapeStyle(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color(UIColor.systemBackground))
        }
    }
    
    private var borderColor: Color {
        switch dataSource.squareStatus {
        case .xw, .ow:
            return .green.opacity(0.9)
        default:
            return Color.secondary.opacity(0.25)
        }
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .black : .gray
    }
    
    private var accessibilityLabel: String {
        "Board square"
    }
    
    private var accessibilityValue: String {
        switch dataSource.squareStatus {
        case .x, .xw: return "X"
        case .o, .ow: return "O"
        case .empty: return "Empty"
        }
    }
}

#Preview {
    // Provide required observed objects for preview
    let viewModel = ViewModel()
    let model = TicTacToeModel(viewModel: viewModel)
    return NavigationStack {
        GameBoardView(
            onExit: {},
            viewModel: viewModel,
            ticTacToe: model,
            gameTypeIsPVP: false,
            difficulty: .hard,
            startingPlayerIsO: false
        )
    }
}
