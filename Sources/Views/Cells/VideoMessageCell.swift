//
//  VideoMessageCell.swift
//  MessageKit
//
//  Created by Jui hsin Chen on 2020/12/1.
//  Copyright © 2020 MessageKit. All rights reserved.
//

import Foundation

open class VideoMessageCell: TemplateMessageCell {
    
    open lazy var playButton: UIButton = {
        let assetBundle = Bundle.messageKitAssetBundle()
        guard let imagePath = assetBundle.path(forResource: "playVideo", ofType: "png", inDirectory: "Images"), let playImage = UIImage(contentsOfFile: imagePath) else { return UIButton() }
        let button = UIButton(type: .custom)
        button.setImage(playImage, for: .normal)
        return button
    }()
    
    open lazy var imageMaskView: UIView = {
       let maskView = UIView()
        maskView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        return maskView
    }()
    
    open var timeDurationButton: UIButton = {
        let timeDurationButton = UIButton()
        timeDurationButton.isUserInteractionEnabled = false
        timeDurationButton.backgroundColor = UIColor(red: 68/255, green: 68/255, blue: 68/255, alpha: 1)
        timeDurationButton.setTitleColor(.white, for: .normal)
        timeDurationButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        timeDurationButton.layer.cornerRadius = 3
        timeDurationButton.clipsToBounds = true
        timeDurationButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        return timeDurationButton
    }()
    
    // MARK: - Methods

    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(imageView)
        imageView.addSubview(timeDurationButton)
        timeDurationButton.addConstraints(bottom: imageView.bottomAnchor, right: imageView.rightAnchor, bottomConstant: 6, rightConstant: 6)
        imageView.addSubview(imageMaskView)
        imageMaskView.addSubview(playButton)
        playButton.centerInSuperview()
        playButton.addConstraints(widthConstant: 48, heightConstant: 48)
        imageMaskView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        messageContainerView.addSubview(messageLabel)
        actionLabel.addSubview(lineView)
        messageContainerView.addSubview(actionLabel)
        imageView.addSubview(timeDurationButton)
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
        let actionViewTouchArea = actionLabel.frame
        let translateTouchLocation = convert(touchLocation, to: messageContainerView)
        
        if actionViewTouchArea.contains(translateTouchLocation) || imageMaskView.frame.contains(translateTouchLocation) {
            delegate?.didTapActionView(in: self)
        }
    }
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError(MessageKitError.nilMessagesDisplayDelegate)
        }
        
        switch message.kind {
        case .media(let item):
            timeDurationButton.setTitle(displayDelegate.durationProgressTextFormat(item.timeDuration, for: self, in: messagesCollectionView), for: .normal)
        default:
            break
        }

    }
    
    /// Used to handle the cell's contentView's tap gesture.
    /// Return false when the contentView does not need to handle the gesture.
    open override func cellContentView(canHandle touchPoint: CGPoint) -> Bool {
        return messageLabel.handleGesture(touchPoint)
    }
}
