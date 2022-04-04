//
//  StickiesView.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 19.03.2022.
//

import UIKit
import SwiftUI
import CoreData

struct StickiesView: View {
    
    // MARK: - Model and Environment
    @Environment(\.colorScheme) var colorScheme //dark/light mode
    @Environment(\.presentationMode) var presentation //use it to dismiss
    
    // MARK: -
    @ObservedObject var viewModel:ViewModel
    private var stickyText:String
    var dismiss:(()->())? //dismiss VC when user choses a note or touches [+]
    
    init(viewModel:ViewModel, stickyText:String, closure: (()->())?) {
        self.viewModel = viewModel
        self.dismiss = closure
        self.stickyText = stickyText
        self.userInput = userInput
    }
    
    // MARK: -
    @State var userInput:String = ""
    @FocusState var isFocused:Bool
    
    private var isDark:Bool { colorScheme == .dark }
    private let maxUserInputLength = 12
    private let rowHeight = CGFloat(9)
    
    // MARK: - Methods and Properties
    ///displayed results keep updating as userInput changes
    private func filtered() -> [Sticky] {
        return userInput.isEmpty ?
        viewModel.stickies :
        viewModel.stickies.filter { filterPredicate($0.content, userInput) }
    }
    
    private func filterPredicate(_ stickyContent:String?, _ userInput:String) -> Bool {
        guard let content = stickyContent else { fatalError() }
        
        let sticky = content.lowercased().folding(options: .diacriticInsensitive, locale: nil)
        let userText = userInput.lowercased().folding(options: .diacriticInsensitive, locale: nil)
        
        return sticky.contains(userText)
    }
    
    private var isIdenticalSticky:Bool { viewModel.stickyContents.contains(userInput.capitalized) }
    
    private var isOverMaxCount:Bool { userInput.count > maxUserInputLength }
    
    private var isButtonDisabled:Bool { isIdenticalSticky || isOverMaxCount }
}

// MARK: - Views
extension StickiesView {
    var body: some View {
        ZStack {
            VStack {
                Spacer().frame(height: 70)
                if !viewModel.stickies.isEmpty { list }
                else { emptyListPlaceholder }
            }
            .background(isDark ? Color.gray : .white)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: isDark ? .clear : .shadowGray, radius: 10)
            .onTapGesture { isFocused = !isFocused } //toggle text field keyboard
            
            VStack {
                Spacer().frame(height: 20)
                HStack {
                    field
                    if userInput.count > 9 { Spacer(minLength: 35) }
                }
                Spacer()
            }
            
            if !userInput.isEmpty {
                let disabled = isButtonDisabled
                VStack {
                    Spacer().frame(height: 4)
                    HStack {
                        Spacer()
                        button
                            .disabled(disabled ? true : false)
                            .foregroundColor(buttonColor)
                    }
                    Spacer()
                }
            }
        }
    }
    
    // MARK: -
    var list:some View {
        List {
            let filteredStickies = filtered()
            
            ForEach(filteredStickies) {sticky in
                Text(sticky.content ?? "")
                //font size and color
                    .font(.title3)
                    .foregroundColor(.white)
                //make editing sticky visible to the user with a black background
                    .background((stickyText == sticky.content) ? Color.black : .clear )
                //user taps a sticky and sets the new note
                    .onTapGesture {
                        viewModel.userTapsStickyInTheList(with: sticky.content ?? "")
                        UserFeedback.triggerSingleHaptic(.light)
                        dismiss?()
                    }
            }
            .onDelete { viewModel.userDeletesSticky(at:$0) }
            .listRowBackground(Color.darkGray)
            
            //prevent app crash when user wants to drag-and-drop text in the textfield
            if filteredStickies.isEmpty {
                noMatchFoundAlert.listRowBackground(Color.darkGray).padding(-10)
            }
        }
        .padding()
        .listStyle(.plain)
        .background(Color.darkGray)
        .onAppear(perform: {
            UITableView.appearance().showsVerticalScrollIndicator = false
        })
        .environment(\.defaultMinListRowHeight, rowHeight)
        .listRowSeparator(.hidden)
    }
    
    // MARK: - fieldbutton legos
    var field:some View {
        TextField("Search / Add Note", text: $userInput)
            .font(.system(size: 30, weight: .regular))
            .minimumScaleFactor(0.5)
            .padding([.trailing, .leading])
            .focused($isFocused, equals: true) //isFocused changes and must watch for true
            .autocapitalization(.words)
            .onChange(of: userInput) {//user types characters
                if $0.count > maxUserInputLength { userInput.removeLast() }
            }
    }
    
    var characterCounter:some View {
        Text("\(maxUserInputLength - userInput.count)")
            .fontWeight(.bold)
            .font(.caption)
            .foregroundColor(isDark ? .mediumGray : .white)
            .padding([.top, .trailing], 30)
    }
    
    var button:some View {
        Button {//actions
            viewModel.userTapsCreateNewStickyButton(userInput)//1
            dismiss?()//2
        } label: {
            ZStack {
                Image(systemName: "plus.square.fill")
                    .font(.system(size: 60, weight: .light))
                if maxUserInputLength - userInput.count >= 0 { characterCounter }
            }
        }
    }
    
    //list lego
    var emptyListPlaceholder:some View {
        VStack (alignment:.leading, spacing: 10) {
            Text("Empty Notes List")
                .font(.title2)
                .fontWeight(.medium)
            VStack (alignment:.leading, spacing: 6) {
                VStack (alignment:.leading, spacing: 0) {
                    Text("1. Add Note")
                    Text("up to \(maxUserInputLength) characters long")
                        .font(.caption2)
                        .padding([.leading])
                }
                Text("2. Tap [+] Button")
            }
            .foregroundColor(.mediumGray)
            Spacer()
        }
        .padding()
    }
    
    var noMatchFoundAlert:some View {
        VStack(alignment:.center, spacing: 4) {
            Spacer(minLength: 30)
            Text("No Match Found")
                .foregroundColor(.white)
                .font(.title3)
                .background(Color.red)
            Text("Tap [+] to Add Note")
                .font(.title3)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Methods or properties
    //button color depends on 1.dark light mode & 2.userInput length
    private var buttonColor:Color {
        let condition = isButtonDisabled
        switch colorScheme {
            case .light: return condition ? .lightGray : .blue
            case .dark: return condition ? .lightGray : .white
            @unknown default: return Color.red
        }
    }
}
