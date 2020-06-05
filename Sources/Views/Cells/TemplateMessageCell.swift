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
    open var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    open var messageLabel: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.contentInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        if #available(iOS 11.0, *) {
            textView.adjustsFontForContentSizeCategory = true
        }

        return textView
    }()

    open var lineView: UIView = {
        let lineView = UIView()
        return lineView
    }()

    open var actionLabel: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.contentInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        if #available(iOS 11.0, *) {
            textView.adjustsFontForContentSizeCategory = true
        }

        return textView
    }()

    // MARK: - Methods

    open func setupConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        lineView.translatesAutoresizingMaskIntoConstraints = false
        actionLabel.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 11.0, *) {
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            messageLabel.setContentHuggingPriority(.required, for: .vertical)
            actionLabel.setContentHuggingPriority(.required, for: .vertical)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: messageContainerView.topAnchor, constant: 0),
                imageView.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: 0),
                imageView.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: 0),
                imageView.bottomAnchor.constraint(equalTo: messageLabel.topAnchor, constant: 0),
                messageLabel.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: 0),
                messageLabel.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: 0),
                lineView.topAnchor.constraint(equalTo: actionLabel.topAnchor, constant: 0),
                lineView.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: 0),
                lineView.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: 0),
                lineView.heightAnchor.constraint(equalToConstant: 0.5),
                actionLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 0),
                actionLabel.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: 0),
                actionLabel.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: 0),
                actionLabel.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: 0)
            ])
        }
    }

    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(imageView)
        messageContainerView.addSubview(messageLabel)
        actionLabel.addSubview(lineView)
        messageContainerView.addSubview(actionLabel)
        setupConstraints()
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.attributedText = nil
        imageView.image = nil
        actionLabel.attributedText = nil
    }

    /// Handle tap gesture on contentView and its subviews.
    open override func handleTapGesture(_ gesture: UIGestureRecognizer) {
        let touchLocation = gesture.location(in: self)
        // compute action label touch area, currently action label which is hardly touchable
        let actionViewTouchArea = CGRect(actionLabel.frame.origin.x, actionLabel.frame.origin.y, actionLabel.frame.size.width, actionLabel.frame.size.height)
        let translateTouchLocation = convert(touchLocation, to: messageContainerView)
        if actionViewTouchArea.contains(translateTouchLocation) {
            delegate?.didTapActionView(in: self)
        } else {
            super.handleTapGesture(gesture)
        }
    }

    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)

        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError(MessageKitError.nilMessagesDisplayDelegate)
        }

        switch message.kind {
        case .template(let template):
            imageView.image = template.image ?? template.placeholderImage
            messageLabel.attributedText = template.text
            messageLabel.textContainerInset = template.textViewContentInset
            actionLabel.attributedText = template.actionString
            actionLabel.textContainerInset = template.bottomTextViewContentInset
            actionLabel.textAlignment = .center
            lineView.backgroundColor = template.lineColor
        default:
            break
        }

        displayDelegate.configureMediaMessageImageView(imageView, for: message, at: indexPath, in: messagesCollectionView)
    }
}
