//
//  SwiftUIView.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 01.07.2021.
//

import SwiftUI

struct SwiftUIView: View {
    var body: some View {
        
        HStack {
            ZStack {
                Text("6")
                    .fontWeight(.semibold)
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    .frame(width: 200, height: 200, alignment: .center)
                Circle()
                    .stroke(lineWidth: 6)
                    .frame(width: 100, height: 100, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            }
            Spacer()
        }
        .padding(10)
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
