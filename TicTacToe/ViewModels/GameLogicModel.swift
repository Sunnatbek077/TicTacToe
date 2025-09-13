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
        position: [SquareStatus] = [.empty, .empty, .empty, .empty, .empty, .empty, .empty, .empty, .empty],
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
    func minimax(_ board: Board, maximizing: Bool, originalPlayer: SquareStatus) -> Int{
        // Terminal conditions
        if board.isWin && originalPlayer == board.opposite { return 1 } // Opponent wins
        else if board.isWin && originalPlayer != board.opposite { return -1 } // Current player loses
        else if board.isDraw { return 0 } // Draw
        
        if maximizing {
            var bestEval = Int.min
            for move in board.legalMoves {
                let result = minimax(board.move(move), maximizing: false, originalPlayer: originalPlayer)
                bestEval = max(result, bestEval)
            }
            return bestEval
        } else {
            var worstEval = Int.max
            for move in board.legalMoves {
                let result = minimax(board.move(move), maximizing: true, originalPlayer: originalPlayer)
                worstEval = min(result, worstEval)
            }
            return worstEval
        }
    }
    
    // MARK: - Find the Best Move for AI
    /// Returns the best move for AI using minimax
    func findBestMove(_ board: Board) -> Int? {
        var bestEval = Int.min
        var bestMove = -1
        for move in board.legalMoves {
            let result = minimax(board.move(move), maximizing: false, originalPlayer: board.turn)
            if result > bestEval {
                bestEval = result
                bestMove = move
            }
        }
        return bestMove
    }
}

// MARK: - TicTacToeModel Class
/// Observable object that manages the game state for the UI
class TicTacToeModel: ObservableObject {
    @Published var squares = [Square]()           // Array representing the board squares
    @Published var playerToMove: Bool = false    // Tracks which player's turn
    @ObservedObject var viewModel: ViewModel     // External view model reference
    
    // MARK: - Initializer
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        for _ in 0...8 {
            squares.append(Square(status: .empty))
        }
    }
    
    // MARK: - Reset Game
    /// Resets all squares to empty and resets the turn
    func resetGame() -> Void {
        for i in 0...8 {
            squares[i].squareStatus = .empty
            playerToMove = false
        }
    }
    
    // MARK: - Check Game Over
    /// Returns the winner and whether the game is over
    var gameOver: (SquareStatus, Bool) {
        get {
            if viewModel.gameOver == false {
                if winner.0 != .empty {
                    colorize(check: winner.0, row: winner.1)
                    viewModel.winner = winner.0
                    return (winner.0, true)
                } else {
                    for i in 0...8 {
                        if squares[i].squareStatus == .empty {
                            return (.empty, false)
                        }
                        viewModel.gameOver = true
                        return (.empty, true)
                    }
                }
            }
            return (.empty, false)
        }
    }
    
    // MARK: - Colorize Winning Combination
    /// Updates the UI to show winning combination in green
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
    
    // MARK: - Make a Move
    /// Handles a move by the player and triggers AI if needed
    func makeMove(index: Int, gameType: Bool) -> Bool {
        var player: SquareStatus
        if playerToMove == false {
            player = .x
        } else {
            player = .o
        }
        if squares[index].squareStatus == .empty {
            squares[index].squareStatus = player
            if playerToMove == false && gameType == false && gameOver.1 == false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.moveAI()
                    GameBoardView.triggerHapticFeedback(type: 2)
                    _ = self.gameOver
                }
            }
            playerToMove.toggle()
            _ = self.gameOver
            return true
        }
        return false
    }
    
    // MARK: - Current Board State
    var getBoard: [SquareStatus] {
        var moves: Array = [SquareStatus]()
        for i in 0...8 {
            moves.append(squares[i].squareStatus)
        }
        return moves
    }
    
    // MARK: - AI Move
    private func moveAI() {
        let boardMoves: [SquareStatus] = getBoard
        let testBoard: Board = Board(position: boardMoves, turn: .o, lastMove: -1)
        guard let answer = testBoard.findBestMove(testBoard) else { return }
        playerToMove = true
        _ = makeMove(index: answer, gameType: true)
    }
    
    // MARK: - Determine Winner
    private var winner: (SquareStatus, [Int]) {
        get {
            let allCombos = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]
            for combo in allCombos {
                if let check = self.checkIndexes(combo) {
                    return (check, combo)
                }
            }
            return (.empty, [])
        }
    }
    
    // Checks if a specific set of indexes has a winner
    private func checkIndexes(_ indexes : [Int]) -> SquareStatus? {
        var xCount: Int = 0
        var oCount: Int = 0
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

// MARK: - Main Logic moves (Simpler Observable Object)
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
            return findBestMove(self) ?? easyMove() // fallback to random if minimax fails
        }
    }
    
    /// Easy difficulty: random move
    private func easyMove() -> Int {
        legalMoves.randomElement() ?? -1
    }
    
    /// Medium difficulty: try to win or block opponent, else random
    private func mediumMove() -> Int {
        // 1️⃣ Check if AI can win
        for candidate in legalMoves {
            let newBoard = self.move(candidate)
            if newBoard.isWin { return candidate }
        }
        // 2️⃣ Check if opponent can win and block
        for candidate in legalMoves {
            let newBoard = self.move(candidate)
            let opponentBoard = Board(position: newBoard.pos, turn: self.opposite)
            if opponentBoard.isWin { return candidate }
        }
        // 3️⃣ Otherwise random move
        return easyMove()
    }
}
