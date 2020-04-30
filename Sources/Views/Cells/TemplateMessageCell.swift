//
//  TemplateMessageCell.swift
//  MessageKit
//
//  Created by justin on 2020/04/22.
//  Copyright © 2020 MessageKit. All rights reserved.
//
// Note: iOS version need more than iOS 11

import UIKit

open class TemplateMessageCell: MessageContentCell {
    open var messageLabel: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.contentInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        if #available(iOS 11.0, *) {
            textView.adjustsFontForContentSizeCategory = true
        }

        return textView
    }()

    open var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    // MARK: - Methods

    open func setupConstraints() {
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 11.0, *) {
            messageLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .vertical)
            NSLayoutConstraint.activate([
                messageLabel.topAnchor.constraint(equalToSystemSpacingBelow: messageContainerView.topAnchor, multiplier: 0),
                messageLabel.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: 15),
                messageLabel.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -5),
                imageView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 0),
                imageView.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: 0),
                imageView.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: 0),
                imageView.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: 0),
            ])
        }
    }

    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(messageLabel)
        messageContainerView.addSubview(imageView)
        setupConstraints()
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.attributedText = nil
        imageView.image = nil
    }

    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)

        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError(MessageKitError.nilMessagesDisplayDelegate)
        }

        switch message.kind {
        case .template(let template):
            messageLabel.attributedText = template.text
            imageView.image = template.image ?? template.placeholderImage
        default:
            break
        }

        displayDelegate.configureMediaMessageImageView(imageView, for: message, at: indexPath, in: messagesCollectionView)
    }
}
