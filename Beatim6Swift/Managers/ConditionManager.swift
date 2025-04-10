//
//  ConditionManager.swift
//  Beatim6Swift
//
//  Created by heilab on 2025-04-10.
//

import Foundation

enum ExperimentConditionType: String, CaseIterable, Identifiable {
    case condition1a = "1a"
    case condition1b = "1b"
    case condition2a = "2a"
    case condition2b = "2b"
    case condition2c = "2c"
    case conditionP = "practice"

    var id: String { self.rawValue }

    var description: String {
        switch self {
        case .condition1a:
            return "1a (推薦なし, ステップサウンド: None)"
        case .condition1b:
            return "1b (推薦あり, ステップサウンド: None)"
        case .condition2a:
            return "2a (推薦あり, ステップサウンド: None)"
        case .condition2b:
            return "2b (推薦あり, ステップサウンド: Beep)"
        case .condition2c:
            return "2c (推薦あり, ステップサウンド: Beep)"
        case .conditionP:
            return "practice (練習用)"
        }
    }

    var isRecommendationEnabled: Bool {
        switch self {
        case .condition1a:
            return false
        default:
            return true
        }
    }

    var stepSoundType: StepSoundType {
        switch self {
        case .condition2b, .condition2c, .conditionP:
            return .beep
        default:
            return .none
        }
    }
}

enum StepSoundType {
    case none
    case beep
}

class ConditionManager: ObservableObject {
    @Published var selectedCondition: ExperimentConditionType = .conditionP
}
