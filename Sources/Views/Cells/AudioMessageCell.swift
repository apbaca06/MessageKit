/*
 MIT License

 Copyright (c) 2017-2019 MessageKit

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit
import AVFoundation

/// A subclass of `MessageContentCell` used to display video and audio messages.
open class AudioMessageCell: MessageContentCell {
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
    
    open var audioView: UIView = {
        let audioView = UIView()
        audioView.backgroundColor = .clear
        return audioView
    }()

    /// The play button view to display on audio messages.
    public lazy var playButton: UIButton = {
        let playButton = UIButton(type: .custom)
        let playImage = UIImage.messageKitImageWith(type: .play)
        let pauseImage = UIImage.messageKitImageWith(type: .pause)
        playButton.setImage(playImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        playButton.setImage(pauseImage?.withRenderingMode(.alwaysTemplate), for: .selected)
        return playButton
    }()

    /// The time duration label to display on audio messages.
    public lazy var durationLabel: UILabel = {
        let durationLabel = UILabel(frame: CGRect.zero)
        durationLabel.textAlignment = .right
        durationLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        durationLabel.text = "0:00"
        return durationLabel
    }()

    public lazy var activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .gray)
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.isHidden = true
        return activityIndicatorView
    }()

    public lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = 0.0
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        return progressView
    }()
    
    // MARK: - Methods
    
    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        playButton.constraint(equalTo: CGSize(width: 24, height: 24))
        playButton.addConstraints(left: audioView.leftAnchor, centerY: audioView.centerYAnchor, leftConstant: 12)
        activityIndicatorView.addConstraints(centerY: playButton.centerYAnchor, centerX: playButton.centerXAnchor)
        durationLabel.addConstraints(right: audioView.rightAnchor, centerY: audioView.centerYAnchor, rightConstant: 15)
        progressView.addConstraints(left: playButton.rightAnchor, right: durationLabel.leftAnchor, centerY: audioView.centerYAnchor, leftConstant: 6, rightConstant: 8)
        let heightConstraint = progressView.heightAnchor.constraint(equalToConstant: 6)
        progressView.addConstraint(heightConstraint)
    }

    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(imageView)
        messageContainerView.addSubview(messageLabel)
        messageContainerView.addSubview(lineView)
        messageContainerView.addSubview(audioView)
        audioView.addSubview(playButton)
        audioView.addSubview(activityIndicatorView)
        audioView.addSubview(durationLabel)
        audioView.addSubview(progressView)
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.attributedText = nil
        imageView.image = nil
        progressView.progress = 0
        playButton.isSelected = false
        activityIndicatorView.stopAnimating()
        playButton.isHidden = false
        durationLabel.text = "0:00"
    }

    /// Handle tap gesture on contentView and its subviews.
    open override func handleTapGesture(_ gesture: UIGestureRecognizer) {
        let touchLocation = gesture.location(in: self)
        // compute action label touch area, currently action label which is hardly touchable
        let audioViewTouchArea = CGRect(audioView.frame.origin.x, audioView.frame.origin.y, audioView.frame.size.width, audioView.frame.size.height)
        let imageViewTouchArea = CGRect(imageView.frame.origin.x, imageView.frame.origin.y, imageView.frame.size.width, imageView.frame.size.height)
        let translateTouchLocation = convert(touchLocation, to: messageContainerView)
        if audioViewTouchArea.contains(translateTouchLocation) || imageViewTouchArea.contains(translateTouchLocation) {
            delegate?.didTapPlayButton(in: self)
        } else {
            super.handleTapGesture(gesture)
        }
    }

    // MARK: - Configure Cell

    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)

        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError(MessageKitError.nilMessagesDisplayDelegate)
        }

        let progressTintColor = displayDelegate.audioProgressTintColor(for: message, at: indexPath, in: messagesCollectionView)
        let trackTintColor = displayDelegate.audioTrackTintColor(for: message, at: indexPath, in: messagesCollectionView)
        playButton.imageView?.tintColor = progressTintColor
        durationLabel.textColor = progressTintColor
        progressView.tintColor = progressTintColor
        progressView.trackTintColor = trackTintColor

        displayDelegate.configureAudioCell(self, message: message)
        
        if case let .audio(audioItem) = message.kind {
            let bubbleWidth = messageContainerView.frame.size.width
            imageView.image = audioItem.image ?? audioItem.placeholderImage
            imageView.frame = CGRect(x: 0, y: 0, width: bubbleWidth, height: audioItem.imageHeight)
            messageLabel.frame = CGRect(x: 0, y: audioItem.imageHeight, width: bubbleWidth, height: audioItem.textViewHeight)
            messageLabel.attributedText = audioItem.text
            messageLabel.textInsets = audioItem.textViewContentInset
            let lineViewHeight: CGFloat = (audioItem.imageHeight + audioItem.textViewHeight == 0) ? 0 : 0.5
            lineView.frame = CGRect(x: 0, y: audioItem.imageHeight + audioItem.textViewHeight, width: bubbleWidth, height: lineViewHeight)
            lineView.backgroundColor = audioItem.lineColor
            audioView.frame = CGRect(x: 0, y: audioItem.imageHeight + audioItem.textViewHeight + lineViewHeight, width: audioItem.audioSize.width, height: audioItem.audioSize.height)
            durationLabel.text = displayDelegate.durationProgressTextFormat(audioItem.audioDuration, for: self, in: messagesCollectionView)
            setupConstraints()
        }
        
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
