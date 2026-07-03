//
//  ContentView.swift
//  Vitesse watch Watch App
//
//  Created by Jérôme Kasparian on 23/06/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(edges: .all)
            Text("00")
                .padding(1)
                .font(Font.monospacedDigit(Font.system(size: 1000))())
                .minimumScaleFactor(0.01)
                .foregroundColor(Color(UIColor.lightGray))
                .background(Color.black)
                . multilineTextAlignment(.center)
            //                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)            //        VStack {
            //            Image(systemName: "globe")
            //                .imageScale(.large)
            //                .foregroundStyle(.tint)
            //            Text("Hello, world!")
            //        }
            //        .padding()
        }
    }
}

#Preview {
    ContentView()
}
