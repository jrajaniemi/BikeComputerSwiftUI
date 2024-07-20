//
//  ContentView.swift
//  BikeComputer
//
//  Created by Jussi Rajaniemi on 19.7.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Spacer()
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Text("A")
                    .font(.custom("CustomFontName", size: 24))
                    .frame(width: geometry.size.width, height: geometry.size.height * 6 / 12)
                    .background(Color.red)
                    .foregroundColor(.white)
                
                HStack(spacing: 0) {
                    Text("B")
                        .font(.custom("CustomFontName", size: 24))
                        .frame(width: geometry.size.width / 2, height: geometry.size.height * 3 / 12)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                    Text("C")
                        .font(.custom("CustomFontName", size: 24))
                        .frame(width: geometry.size.width / 2, height: geometry.size.height * 3 / 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                }
                
                Text("D")
                    .font(.custom("CustomFontName", size: 24))
                    .frame(width: geometry.size.width, height: geometry.size.height * 3 / 12)
                    .background(Color.black)
                    .foregroundColor(.white)
            }
            .edgesIgnoringSafeArea(.all)
        }

    }
}

#Preview {
    ContentView()
}
