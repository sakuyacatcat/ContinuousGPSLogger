//
//  ActionButtonView.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import SwiftUI

struct ActionButtonView: View {
    let title: String
    let style: ButtonStyle
    let isDisabled: Bool
    let action: () -> Void
    
    enum ButtonStyle {
        case prominent
        case bordered
        case caption
    }
    
    init(
        title: String,
        style: ButtonStyle = .bordered,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        switch style {
        case .prominent:
            Button(title, action: action)
                .buttonStyle(.borderedProminent)
                .disabled(isDisabled)
        case .bordered:
            Button(title, action: action)
                .buttonStyle(.bordered)
                .disabled(isDisabled)
        case .caption:
            Button(title, action: action)
                .buttonStyle(.bordered)
                .font(.caption)
                .disabled(isDisabled)
        }
    }
}

#Preview {
    Form {
        Section("Button Examples") {
            VStack(alignment: .leading, spacing: 12) {
                ActionButtonView(
                    title: "Always 権限をリクエスト",
                    style: .prominent
                ) {
                    print("Request permission")
                }
                
                ActionButtonView(
                    title: "設定を開く",
                    style: .bordered
                ) {
                    print("Open settings")
                }
                
                HStack {
                    ActionButtonView(
                        title: "統計リセット",
                        style: .caption
                    ) {
                        print("Reset statistics")
                    }
                    Spacer()
                }
                
                ActionButtonView(
                    title: "無効なボタン",
                    style: .bordered,
                    isDisabled: true
                ) {
                    print("This won't be called")
                }
            }
        }
    }
}