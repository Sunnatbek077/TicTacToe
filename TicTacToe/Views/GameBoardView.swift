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
    @State var selection: Bool = false
    @State var move: Bool = false
    @State private var vibro: Bool = false
    @State var popUp: Bool = false
    
    static func setVibro(mode: Bool) {
        UserDefaults.standard.set(mode, forKey: "vibro")
    }
    
    // Binding to control presentation from parent (ContentView)
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
        if (self.ticTacToe.playerToMove == false && selection == false) || selection == true {
            _ = self.ticTacToe.makeMove(index: index, gameType: selection)
        }
        GameBoardView.triggerHapticFeedback(type: 2)
    }
    
    var currentPlayer: String {
        return self.ticTacToe.playerToMove == false ? "X" : "O"
    }
    var AIMove: String {
        return self.ticTacToe.playerToMove == false ? "O" : "X"
    }
    
    var body: some View {
        VStack(spacing: 10) {
            VStack {
                Text("Tic Tac Toe - AI")
                    .font(.largeTitle)
                    .bold()
                Text("Your move!")
                    .bold()
                    .font(.title)
            }
            .padding()
            
            // 3x3 grid
            ForEach(0..<(ticTacToe.squares.count / 3), id: \.self) { row in
                HStack {
                    ForEach(0..<3, id: \.self) { column in
                        let index = row * 3 + column
                        if ticTacToe.squares.indices.contains(index) {
                            SquareCellView(
                                dataSource: ticTacToe.squares[index],
                                action: { self.buttonAction(index) }
                            )
                        }
                    }
                }
            }
            
            // Exit button
            Button {
                self.ticTacToe.resetGame()
                viewModel.gameOver = false
                viewModel.winner = .empty
                onExit()
            } label: {
                Text("Exit")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding()
        .alert(isPresented: $viewModel.gameOver, content: {
            var text = ""
            if self.selection == false {
                if viewModel.winner == .x { text = "You won!" }
                else if viewModel.winner == .o { text = "AI won!" }
                else { text = "Draw!" }
            } else {
                if viewModel.winner == .x { text = "X won!" }
                else if viewModel.winner == .o { text = "O won!" }
                else { text = "Draw!" }
            }
            return Alert(title: Text(text),
                         dismissButton: Alert.Button.cancel(Text("Ok"), action: {
                self.ticTacToe.resetGame()
                viewModel.gameOver = false
                viewModel.winner = .empty
            })
            )
        })
    }
}

#Preview {
    // Provide required observed objects for preview
    let viewModel = ViewModel()
    let model = TicTacToeModel(viewModel: viewModel)
    return GameBoardView(onExit: {}, viewModel: viewModel, ticTacToe: model)
}
