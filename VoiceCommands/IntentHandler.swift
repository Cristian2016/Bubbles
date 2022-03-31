//
//  IntentHandler.swift
//  VoiceCommands
//
//  Created by Cristian Lapusan on 09.01.2022.
//

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        switch intent {
        case is StartIntent:
            print("is StartIntent")
            return StartHandler()
        default:
            break
        }
        
        return self
    }
    
}

class StartHandler: NSObject, StartIntentHandling {
    func handle(intent: StartIntent, completion: @escaping (StartIntentResponse) -> Void) {
        
    }
}
