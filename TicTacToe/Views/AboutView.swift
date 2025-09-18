//
//  AboutView.swift
//  TicTacToe
//
//  Created by Sunnatbek on 19/09/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "circle.grid.cross")
                            .resizable()
                            .frame(width: 56, height: 56)
                            .cornerRadius(12)
                            .padding(.trailing, 4)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("TicTacToe")
                                .font(.title2)
                                .bold()
                            Text("A modern version of the classic Tic Tac Toe")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    // Description
                    Group {
                        Text("Overview")
                            .font(.headline)
                        Text("""
TicTacToe is a modern take on the classic 3x3 game. 
It features:
- A powerful AI using the Minimax algorithm,
- Three different play modes,
- Smooth animations and clean UI,
- Open-source on GitHub (Sunnatbek077).
""")
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Features
                    Group {
                        Text("Key Features")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                Text("•").bold()
                                Text("Strong Minimax AI — optimized for perfect decision-making.")
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            HStack(alignment: .top) {
                                Text("•").bold()
                                Text("Two Modes:\n   1) Player vs Player — local two-player mode.\n   2) Player vs AI — challenge the computer.")
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            HStack(alignment: .top) {
                                Text("•").bold()
                                Text("Smooth graphics and animations for a modern feel.")
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            HStack(alignment: .top) {
                                Text("•").bold()
                                Text("User-friendly design with restart.")
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // Technical note
                    Group {
                        Text("Technical Note")
                            .font(.headline)
                        Text("The Minimax algorithm is enhanced with optimizations to prune unnecessary moves and cache evaluations, ensuring both speed and unbeatable AI performance.")
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Links
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            if let url = URL(string: "https://github.com/Sunnatbek077") {
                                openURL(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "link")
                                Text("GitHub: Sunnatbek077")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Dismiss (X) button
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                            .padding(8)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }
}

#Preview {
    AboutView()
}
