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
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass
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
        #if os(iOS) || os(tvOS) || os(visionOS)
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
        #else
        // macOS: no haptics by default
        #endif
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
        content
            .background(background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
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
            // Keyboard/game controller shortcuts
            .onAppear {
                // nothing required here; commands are declared at the Scene level if needed
            }
    }
    
    // MARK: - Adaptive Content Layout
    @ViewBuilder
    private var content: some View {
        // Use a two-column layout on large/wide screens (iPad landscape, macOS, visionOS),
        // otherwise stack vertically (phones or compact).
        if isWide {
            HStack(spacing: 24) {
                leftPanel
                    .frame(minWidth: 260, maxWidth: 360)
                board
                rightPanel
                    .frame(minWidth: 220, maxWidth: 320)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        } else {
            VStack(spacing: 16) {
                header
                board
                    .padding(.horizontal)
                footer
            }
            .padding(.top, 12)
        }
    }
    
    private var isWide: Bool {
        #if os(macOS) || os(visionOS)
        return true
        #else
        // iPad landscape or any regular width is treated as wide
        return hSizeClass == .regular
        #endif
    }
    
    // MARK: - Panels for wide layouts
    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusCard
            footerButtonsOnly
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)
            Text(headerSubtitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Divider()
            
            Text("Mode")
                .font(.headline)
            Text(modeBadgeText)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
                .foregroundStyle(.primary)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Header
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
    
    // MARK: - Board
    private var board: some View {
        GeometryReader { proxy in
            // Choose a comfortable side length: square, up to a max, with generous margins on big screens
            let maxSide = min(proxy.size.width, proxy.size.height)
            // Cap size so on macOS/visionOS the board doesn't grow excessively wide
            let side = min(maxSide, preferredBoardSide(for: proxy.size))
            let spacing: CGFloat = max(8, side * 0.02)
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
                                .accessibilityHint("Double-tap to place your mark")
                                #if os(macOS)
                                .onHover { hovering in
                                    // simple hover effect via scale handled inside SquareButtonView
                                }
                                #endif
                                #if os(iOS) || os(visionOS)
                                .hoverEffect(.lift)
                                #endif
                            } else {
                                Color.clear.frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
            .frame(width: side, height: side, alignment: .center)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isWide ? .center : .top)
            .padding(isWide ? 12 : 0)
        }
        .frame(minHeight: 420)
        .accessibilityElement(children: .contain)
    }
    
    // Calculate a pleasant maximum board side depending on platform and size
    private func preferredBoardSide(for size: CGSize) -> CGFloat {
        #if os(macOS)
        // Leave space for side panels; keep board around 520–640 points typically
        return min(640, max(420, min(size.width, size.height) * 0.8))
        #elseif os(visionOS)
        // Slightly larger for comfortable reach in space
        return min(720, max(480, min(size.width, size.height) * 0.85))
        #else
        // iPad/iPhone
        if hSizeClass == .regular {
            return min(600, max(420, min(size.width, size.height) * 0.9))
        } else {
            return min(420, max(360, min(size.width, size.height) * 0.95))
        }
        #endif
    }
    
    // MARK: - Footer
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
    
    // Buttons only for the right panel in wide layouts
    private var footerButtonsOnly: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                resetForNextRound()
            } label: {
                Label("Restart", systemImage: "arrow.counterclockwise.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            
            Button(role: .destructive) {
                exitToMenu()
            } label: {
                Label("Exit", systemImage: "xmark.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Background
    private var background: some View {
        Group {
            #if os(visionOS)
            // Transparent background works well with ornaments/spatial contexts
            Color.clear
            #else
            if colorScheme == .dark {
                Color.black.opacity(0.95)
            } else {
                Color(UIColor.systemGroupedBackground)
            }
            #endif
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(macOS)
        ToolbarItem(placement: .primaryAction) {
            Button {
                resetForNextRound()
            } label: {
                Label("Restart", systemImage: "arrow.counterclockwise.circle")
            }
            .help("Restart game")
            .keyboardShortcut("r", modifiers: [.command]) // keep keyboard shortcut here
        }
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .cancel) {
                exitToMenu()
            } label: {
                Label("Exit", systemImage: "xmark.circle")
            }
            .help("Exit to menu")
            .keyboardShortcut(.escape, modifiers: []) // keep keyboard shortcut here
        }
        #else
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
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                resetForNextRound()
            } label: {
                Label("Restart", systemImage: "arrow.counterclockwise.circle")
            }
            .accessibilityLabel("Restart game")
        }
        #endif
    }
    
    // MARK: - Actions
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
    #if os(macOS)
    @State private var isHovering: Bool = false
    #endif
    
    var body: some View {
        Button {
            if dataSource.squareStatus == .empty {
                action()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )
                    .shadow(color: shadowColor.opacity(0.12), radius: 6, x: 0, y: 3)
                    .scaleEffect(scaleEffectValue)
                    .animation(.easeOut(duration: 0.12), value: isPressed)
                    #if os(macOS)
                    .animation(.easeOut(duration: 0.12), value: isHovering)
                    #endif
                
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
        #if os(macOS)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.08)) { isHovering = hovering }
        }
        #endif
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
    
    private var cornerRadius: CGFloat {
        max(12, size * 0.08)
    }
    
    private var scaleEffectValue: CGFloat {
        #if os(macOS)
        return isPressed ? 0.97 : (isHovering ? 1.02 : 1.0)
        #else
        return isPressed ? 0.97 : 1.0
        #endif
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
