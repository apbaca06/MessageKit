//
//  TemplateItem.swift
//  MessageKit
//
//  Created by justin on 2020/04/22.
//  Copyright © 2020 MessageKit. All rights reserved.
//

import Foundation

/// A protocol used to represent the data for a media message.
public protocol MessageItem {
    /// The text.
    var text: NSAttributedString { get }
    /// The text view's content inset
    var textViewContentInset: UIEdgeInsets { get }
    /// The text view's height
    var textViewHeight: CGFloat { get }
}

/// A protocol used to represent the data for a media message.
public protocol ActionItem {
    /// The action text
    var actionString: NSAttributedString? { get }
    /// The line's color
    var lineColor: UIColor { get }
    /// The bottom text view's height
    var bottomTextViewHeight: CGFloat { get }
    /// The bottom text view's content inset
    var bottomTextViewContentInset: UIEdgeInsets { get }
}

public protocol TemplateItem: MediaItem, MessageItem, ActionItem {
    /// The image's height
    var imageHeight: CGFloat { get }
}
