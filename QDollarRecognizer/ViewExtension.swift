//
//  ViewExtension.swift
//  QDollarRecognizer
//
//  Created by Oleksandr Fedko on 13.04.2023.
//

import SwiftUI

extension View {
    func onAnimationCompleted<T: VectorArithmetic>(for value: T, completion: @escaping () -> Void) -> ModifiedContent<Self, AnimationCompletionObserverModifier<T>> {
            return modifier(AnimationCompletionObserverModifier(observedValue: value, completion: completion))
        }
}
