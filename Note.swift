//
//  Note.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 08.04.2022.
//

import SwiftUI

struct Note: View {
    let content:String
    let lineWidth:CGFloat
    let cornerRadius:CGFloat
    
    let aspectRatio:CGFloat = 2.134
    
    init(content:String = "", lineWidth:CGFloat = 6, radius:CGFloat = 10) {
        self.content = content
        self.lineWidth = lineWidth
        self.cornerRadius = radius
    }
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                Label { Text("Note") } icon: { }
                Spacer()
            }
            .background(border)
            .background(background)
        }
        .padding()
        .font(.largeTitle)
        .foregroundColor(.black)
    }
    
    var background: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .foregroundColor(.red)
            .aspectRatio(aspectRatio, contentMode: .fill)
            .shadow(radius: 2)
    }
    
    var border: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(lineWidth: lineWidth, antialiased: true)
            .aspectRatio(aspectRatio, contentMode: .fill)
            .foregroundColor(.white)
    }
}

struct Note_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Note()
            Note()
                .preferredColorScheme(.dark)
        }
    }
}
