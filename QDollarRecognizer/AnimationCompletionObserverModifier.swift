//
//  AnimationCompletionObserverModifier.swift
//  QDollarRecognizer
//
//  Created by Oleksandr Fedko on 13.04.2023.
//

import SwiftUI

struct AnimationCompletionObserverModifier<T>: AnimatableModifier where T: VectorArithmetic {
    var animatableData: T {
        didSet { notifyCompletionFinished() }
    }
    
    private var targetValue: T
    private var completion: () -> Void
    
    init(observedValue: T, completion: @escaping () -> Void) {
        self.completion = completion
        self.animatableData = observedValue
        self.targetValue = observedValue
    }
    
    func body(content: Content) -> some View {
        return content
    }
    
    private func notifyCompletionFinished() {
        if animatableData == targetValue {
            DispatchQueue.main.async {
                self.completion()
            }
        }
    }
}
