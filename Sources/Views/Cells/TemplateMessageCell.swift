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
    /// The `MessageCellDelegate` for the cell.
    open override weak var delegate: MessageCellDelegate? {
        didSet {
            messageLabel.delegate = delegate
        }
    }
    
    open var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    open var messageLabel = MessageLabel()

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

    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(imageView)
        messageContainerView.addSubview(messageLabel)
        actionLabel.addSubview(lineView)
        messageContainerView.addSubview(actionLabel)
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
        let actionView = actionLabel.frame.size.height > 0 ? actionLabel : messageLabel
        let actionViewTouchArea = CGRect(actionView.frame.origin.x, actionView.frame.origin.y, actionView.frame.size.width, actionView.frame.size.height)
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
            let bubbleWidth = messageContainerView.frame.size.width
            imageView.image = template.image ?? template.placeholderImage
            imageView.frame = CGRect(x: 0, y: 0, width: bubbleWidth, height: template.imageHeight)
            messageLabel.frame = CGRect(x: 0, y: template.imageHeight, width: bubbleWidth, height: template.textViewHeight)
            lineView.frame = CGRect(x: 0, y: 0, width: bubbleWidth, height: 0.5)
            actionLabel.frame = CGRect(x: 0, y: template.imageHeight + template.textViewHeight, width: bubbleWidth, height: template.bottomTextViewHeight)
            messageLabel.attributedText = template.text
            messageLabel.textInsets = template.textViewContentInset
            actionLabel.attributedText = template.actionString
            actionLabel.textContainerInset = template.bottomTextViewContentInset
            actionLabel.textAlignment = .center
            lineView.backgroundColor = template.lineColor
        default:
            break
        }

        displayDelegate.configureMediaMessageImageView(imageView, for: message, at: indexPath, in: messagesCollectionView)
        
        let enabledDetectors = displayDelegate.enabledDetectors(for: message, at: indexPath, in: messagesCollectionView)

        messageLabel.configure {
            messageLabel.enabledDetectors = enabledDetectors
            for detector in enabledDetectors {
                let attributes = displayDelegate.detectorAttributes(for: detector, and: message, at: indexPath)
                messageLabel.setAttributes(attributes, detector: detector)
            }
        }
    }
    
    /// Used to handle the cell's contentView's tap gesture.
    /// Return false when the contentView does not need to handle the gesture.
    open override func cellContentView(canHandle touchPoint: CGPoint) -> Bool {
        return messageLabel.handleGesture(touchPoint)
    }
}
