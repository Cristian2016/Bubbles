//
//  TestTimer.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 25.06.2021.
//

import SwiftUI
import WidgetKit

struct TestTimer: View {
    let date:Date
    
    var body: some View {
        Text(date, style: .timer)
    }
}

struct TestTimer_Previews: PreviewProvider {
    static var previews: some View {
        TestTimer(date: Date().addingTimeInterval(-3600))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
