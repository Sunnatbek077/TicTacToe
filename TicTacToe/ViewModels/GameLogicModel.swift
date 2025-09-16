//
//  GameLogicModel.swift
//  TicTacToe
//
//  Created by Sunnatbek on 06/09/25.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Skeleton map of the Board
/// Represents the TicTacToe board and contains the main game logic
struct Board {
    /// Current state of each square on the board
    let pos: [SquareStatus]
    /// Current player's turn
    let turn: SquareStatus
    /// Last move made on the board
    let lastMove: Int
    /// Opponent of the current turn
    let opposite: SquareStatus
    
    // MARK: - Initializer
    /// Initializes a new board with default or provided values
    init(
        position: [SquareStatus] = Array(repeating: .empty, count: 9),
        turn: SquareStatus = .x,
        lastMove: Int = -1
    ) {
        self.pos = position
        self.turn = turn
        self.lastMove = lastMove
        self.opposite = turn == .x ? .o : .x
    }
    
    // MARK: - Make a move
    /// Returns a new board after making a move at the specified location
    func move(_ location: Int) -> Board {
        var tempPosition = pos
        tempPosition[location] = turn
        return Board(position: tempPosition, turn: opposite, lastMove: location)
    }
    
    // MARK: - Legal Moves
    /// Returns all indexes that are still empty and valid to play
    var legalMoves: [Int] {
        return pos.indices.filter { pos[$0] == .empty }
    }
    
    // MARK: - Winning Combinations
    /// Returns all possible winning combinations (rows, columns, diagonals)
    private var winningCombos: [[Int]] {
        [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
            [0, 4, 8], [2, 4, 6]             // diagonals
        ]
    }
    
    /// Checks if the current board state is a win
    var isWin: Bool {
        for combo in winningCombos {
            let a = combo[0], b = combo[1], c = combo[2]
            if pos[a] == pos[b], pos[b] == pos[c], pos[a] != .empty {
                return true
            }
        }
        return false
    }
    
    /// Checks if the game is a draw (no empty squares and no winner)
    var isDraw: Bool {
        return !isWin && legalMoves.isEmpty
    }
    
    // MARK: - Minimax Algorithm
    /// Recursive minimax algorithm to evaluate board positions
    func minimax(_ board: Board, depth: Int, alpha: inout Int, beta: inout Int, maximizing: Bool, originalPlayer: SquareStatus) -> Int {
        if board.isWin && originalPlayer == board.opposite { return 10 - depth }
        else if board.isWin && originalPlayer != board.opposite { return depth - 10 }
        else if board.isDraw { return 0 }
        
        if maximizing {
            var maxEval = Int.min
            for move in board.legalMoves {
                var a = alpha, b = beta
                let eval = minimax(board.move(move), depth: depth + 1, alpha: &a, beta: &b, maximizing: false, originalPlayer: originalPlayer)
                maxEval = max(maxEval, eval)
                alpha = max(alpha, eval)
                if beta <= alpha { break }
            }
            return maxEval
        } else {
            var minEval = Int.max
            for move in board.legalMoves {
                var a = alpha, b = beta
                let eval = minimax(board.move(move), depth: depth + 1, alpha: &a, beta: &b, maximizing: true, originalPlayer: originalPlayer)
                minEval = min(minEval, eval)
                beta = min(beta, eval)
                if beta <= alpha { break }
            }
            return minEval
        }
    }
    
    // Optional: convenience wrapper to start minimax with defaults
    private func evaluateMove(_ board: Board, maximizing: Bool, originalPlayer: SquareStatus) -> Int {
        var alpha = Int.min
        var beta = Int.max
        return minimax(board, depth: 0, alpha: &alpha, beta: &beta, maximizing: maximizing, originalPlayer: originalPlayer)
    }
    
    // MARK: - Find the Best Move for AI (Hard)
    func findBestMove(_ board: Board) -> Int? {
        var bestEval = Int.min
        var bestMove = -1
        for move in board.legalMoves {
            let childBoard = board.move(move)
            let result = evaluateMove(childBoard, maximizing: false, originalPlayer: board.turn)
            if result > bestEval {
                bestEval = result
                bestMove = move
            }
        }
        return bestMove >= 0 ? bestMove : nil
    }
}

// MARK: - TicTacToeModel Class
/// Observable object that manages the game state for the UI
class TicTacToeModel: ObservableObject {
    @Published var squares = [Square]()
    @Published var playerToMove: Bool = false
    @ObservedObject var viewModel: ViewModel
    
    // New: which mark the AI plays (relevant only when playing vs AI)
    // .x means AI plays X, .o means AI plays O
    var aiPlays: SquareStatus = .o
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        for _ in 0..<9 {
            squares.append(Square(status: .empty))
        }
    }
    
    // Reset Game
    func resetGame() {
        for i in 0..<9 {
            squares[i].squareStatus = .empty
            playerToMove = false
        }
    }
    
    // Game Over Check
    var gameOver: (SquareStatus, Bool) {
        get {
            if viewModel.gameOver == false {
                if winner.0 != .empty {
                    colorize(check: winner.0, row: winner.1)
                    viewModel.winner = winner.0
                    return (winner.0, true)
                }
                if squares.allSatisfy({ $0.squareStatus != .empty }) {
                    viewModel.gameOver = true
                    return (.empty, true) // draw
                }
            }
            return (.empty, false)
        }
    }
    
    // Highlight Winner
    func colorize(check: SquareStatus, row: [Int]) {
        withAnimation {
            if check == .x {
                squares[row[0]].squareStatus = .xw
                squares[row[1]].squareStatus = .xw
                squares[row[2]].squareStatus = .xw
            } else {
                squares[row[0]].squareStatus = .ow
                squares[row[1]].squareStatus = .ow
                squares[row[2]].squareStatus = .ow
            }
        }
        viewModel.gameOver = true
    }
    
    // Make Move
    // gameType: false = AI mode, true = PvP
    func makeMove(index: Int, gameType: Bool, difficulty: AIDifficulty = .hard) -> Bool {
        guard index >= 0 && index < squares.count else { return false }
        guard squares[index].squareStatus == .empty else { return false }
        
        let player: SquareStatus = playerToMove ? .o : .x
        squares[index].squareStatus = player
        
        playerToMove.toggle()
        _ = self.gameOver
        
        // If AI mode and it's now AI's turn, trigger AI
        if gameType == false && gameOver.1 == false {
            let currentTurn: SquareStatus = playerToMove ? .o : .x
            if currentTurn == aiPlays {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.moveAI(difficulty: difficulty)
                    GameBoardView.triggerHapticFeedback(type: 2)
                    _ = self.gameOver
                }
            }
        }
        
        return true
    }
    
    // Board state
    var getBoard: [SquareStatus] {
        squares.map { $0.squareStatus }
    }
    
    // AI Move
    private func moveAI(difficulty: AIDifficulty) {
        let boardMoves = getBoard
        // Build board with the AI's mark to move
        let aiTurn: SquareStatus = aiPlays
        let testBoard = Board(position: boardMoves, turn: aiTurn, lastMove: -1)
        let answer = testBoard.bestMove(difficulty: difficulty)
        guard answer >= 0 else { return }
        _ = makeMove(index: answer, gameType: false, difficulty: difficulty)
    }
    
    // Winner Check
    private var winner: (SquareStatus, [Int]) {
        let allCombos = [[0,1,2],[3,4,5],[6,7,8],
                         [0,3,6],[1,4,7],[2,5,8],
                         [0,4,8],[2,4,6]]
        for combo in allCombos {
            if let check = self.checkIndexes(combo) {
                return (check, combo)
            }
        }
        return (.empty, [])
    }
    
    private func checkIndexes(_ indexes : [Int]) -> SquareStatus? {
        var xCount = 0, oCount = 0
        for index in indexes {
            let square = squares[index]
            if square.squareStatus == .x || square.squareStatus == .xw { xCount += 1 }
            else if square.squareStatus == .o || square.squareStatus == .ow { oCount += 1 }
        }
        if xCount == 3 { return .x }
        else if oCount == 3 { return .o }
        return nil
    }
}

// MARK: - Simple TicTacToe State
class TicTacToe: ObservableObject {
    @Published var squares = [Square]()
    @Published var playerToMove: Bool = false
    init() {}
}

// MARK: - AI Difficulty Enum
enum AIDifficulty {
    case easy
    case medium
    case hard
}

extension Board {
    /// Returns the best move for the AI depending on the difficulty
    func bestMove(difficulty: AIDifficulty) -> Int {
        switch difficulty {
        case .easy:
            return easyMove()
        case .medium:
            return mediumMove()
        case .hard:
            return findBestMove(self) ?? easyMove()
        }
    }
    
    private func easyMove() -> Int {
        legalMoves.randomElement() ?? -1
    }
    
    private func mediumMove() -> Int {
        // 1️⃣ Try to win
        for candidate in legalMoves {
            let newBoard = self.move(candidate)
            if newBoard.isWin { return candidate }
        }
        // 2️⃣ Block opponent
        for candidate in legalMoves {
            let newBoard = self.move(candidate)
            let opponentBoard = Board(position: newBoard.pos, turn: self.opposite)
            if opponentBoard.isWin { return candidate }
        }
        // 3️⃣ Otherwise random
        return easyMove()
    }
}

