//
//  CustomChatViewController.swift
//  ChatExample
//
//  Created by justin on 2020/03/09.
//  Copyright © 2020 MessageKit. All rights reserved.
//

import UIKit
import MapKit
import MessageKit
import InputBarAccessoryView

/// A base class for the example controllers
class CustomChatViewController: MessagesViewController {

    enum PopViewType {
        case text
        case add
        case sticker
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    /// The `BasicAudioController` controller the AVAudioPlayer state (play, pause, stop) and update audio cell UI accordingly.
    open lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)

    var messageList: [MockMessage] = []
    var popViewType: PopViewType = .text

    var extraActionVC: ExtraActionViewController?
    var stickerVC: StickerViewController?

    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private var keyboardManager: KeyboardManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMessageCollectionView()
        configureMessageInputBar()
        loadFirstMessages()
        title = "MessageKit"

        // refer: https://stackoverflow.com/questions/28858908/add-uitapgesturerecognizer-to-uitextview-without-blocking-textview-touches
        let tapTextViewGesture = UITapGestureRecognizer.init(target: self, action: #selector(textViewTapped))
        tapTextViewGesture.delegate = self
        tapTextViewGesture.numberOfTouchesRequired = 1
        messageInputBar.inputTextView.addGestureRecognizer(tapTextViewGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeKeyboardHeight()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeAllPopView()
        keyboardManager = nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        MockSocket.shared.disconnect()
        audioController.stopAnyOngoingPlaying()
    }

    func loadFirstMessages() {
        DispatchQueue.global(qos: .userInitiated).async {
            let count = UserDefaults.standard.mockMessagesCount()
            SampleData.shared.getMessages(count: count) { messages in
                DispatchQueue.main.async {
                    self.messageList = messages
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToBottom()
                }
            }
        }
    }

    func configureMessageCollectionView() {
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.setMessageIncomingAvatarSize(CGSize(width: 30, height: 30))
        layout?.setMessageIncomingAvatarPosition(.init(vertical: .messageLabelTop))
        layout?.setMessageOutgoingAvatarSize(.zero) // hidden self's avatar

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
    }

    func configureMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.isTranslucent = true
        messageInputBar.inputTextView.tintColor = .primaryColor
        messageInputBar.inputTextView.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        messageInputBar.inputTextView.placeholder = "New message"
        messageInputBar.inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        messageInputBar.middleContentViewPadding = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 5, left: 12, bottom: 0, right: 12)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 5, left: 16, bottom: 0, right: 16)
        messageInputBar.inputTextView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1).cgColor
        messageInputBar.inputTextView.layer.borderWidth = 1.0
        messageInputBar.inputTextView.layer.cornerRadius = 16.0
        messageInputBar.inputTextView.layer.masksToBounds = true
        configureInputBarItems()
    }

    private func configureInputBarItems() {
        messageInputBar.setRightStackViewWidthConstant(to: 0, animated: false)
        messageInputBar.setLeftStackViewWidthConstant(to: 74, animated: false)
        let addButton = InputBarButtonItem()
        .configure {
            $0.setImage(UIImage(named: "add"), for: .normal)
            $0.setImage(UIImage(named: "add_feedback"), for: .highlighted)
            $0.imageView?.contentMode = .scaleAspectFit
            $0.setSize(CGSize(width: 32, height: 32), animated: false)
            $0.addTarget(self, action: #selector(tapAdd), for: .touchUpInside)
        }
        let stickerButton = InputBarButtonItem()
        .configure {
            $0.setImage(UIImage(named: "stickers"), for: .normal)
            $0.setImage(UIImage(named: "stickers_feedback"), for: .highlighted)
            $0.imageView?.contentMode = .scaleAspectFit
            $0.setSize(CGSize(width: 32, height: 32), animated: false)
            $0.addTarget(self, action: #selector(tapSticker), for: .touchUpInside)
        }
        let leftItems = [stickerButton, addButton, .flexibleSpace]
        messageInputBar.setStackViewItems(leftItems, forStack: .left, animated: false)
    }

    // MARK: - IBAction

    @IBAction func tapAdd() {
        popViewType = .add

        inputTextViewBecomeFirstResponse()
        processPopView()
    }

    @IBAction func tapSticker() {
        popViewType = .sticker

        inputTextViewBecomeFirstResponse()
        processPopView()
    }

    // MARK: - Helpers

    func insertMessage(_ message: MockMessage) {
        messageList.append(message)
        // Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([messageList.count - 1])
            if messageList.count >= 2 {
                messagesCollectionView.reloadSections([messageList.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        })
    }

    func isLastSectionVisible() -> Bool {

        guard !messageList.isEmpty else { return false }

        let lastIndexPath = IndexPath(item: 0, section: messageList.count - 1)

        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }

    func observeKeyboardHeight() {
        keyboardManager = KeyboardManager()
        // Add some extra handling to manage content inset
        keyboardManager?.on(event: .didChangeFrame) { (notification) in
            let notificationEndFrame = notification.endFrame
            let messageInputBarHeight = self.messageInputBar.bounds.size.height

            if notificationEndFrame.size.height > messageInputBarHeight { // keyboard did show
                self.messageInputBar.setRightStackViewWidthConstant(to: 50, animated: true)
                self.processPopView()
            } else { // keyboard did hide
                self.messageInputBar.setRightStackViewWidthConstant(to: 0, animated: true)
            }
        }
    }

    private func removeStickerVCFromSuperView(superView: UIView) {
        for view in superView.subviews where view == stickerVC?.view {
            view.removeFromSuperview()
            stickerVC = nil
        }
    }

    private func removeExtractionVCFromSuperView(superView: UIView) {
        for view in superView.subviews where view == extraActionVC?.view {
            view.removeFromSuperview()
            extraActionVC = nil
        }
    }

    func removeAllPopView() {
        guard let lastWindow = UIApplication.shared.windows.last, let inputContainerView = lastWindow.subviews.first else {
            return
        }

        removeStickerVCFromSuperView(superView: inputContainerView)
        removeExtractionVCFromSuperView(superView: inputContainerView)
    }

    private func inputTextViewBecomeFirstResponse() {
        if messageInputBar.inputTextView.isFirstResponder == false {
            messageInputBar.inputTextView.becomeFirstResponder()
        }
    }

    private func processPopView() {

        guard let lastWindow = UIApplication.shared.windows.last, let inputContainerView = lastWindow.subviews.first, let inputHostView = inputContainerView.subviews.first else {
                    return
                }

        switch popViewType {
        case .text:
            removeAllPopView()
        case .add:
            removeStickerVCFromSuperView(superView: inputContainerView)

            if extraActionVC == nil {
                extraActionVC = ExtraActionViewController()
                extraActionVC?.delegate = self
            }

            guard let extraActionView = extraActionVC?.view, inputContainerView.contains(extraActionView) == false, let inputBarView = inputHostView.subviews.last else {
                return
            }

            inputContainerView.addSubview(extraActionView)
            extraActionView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                extraActionView.topAnchor.constraint(equalTo: inputBarView.bottomAnchor, constant: 0),
                extraActionView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 0),
                extraActionView.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: 0),
                extraActionView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: 0)
            ])
        case .sticker:
            removeExtractionVCFromSuperView(superView: inputContainerView)

            if self.stickerVC == nil {
                self.stickerVC = StickerViewController()
                self.stickerVC?.delegate = self
            }

            guard let stickerView = stickerVC?.view, inputContainerView.contains(stickerView) == false, let inputBarView = inputHostView.subviews.last else {
                return
            }

            inputContainerView.addSubview(stickerView)
            stickerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stickerView.topAnchor.constraint(equalTo: inputBarView.bottomAnchor, constant: 0),
                stickerView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 0),
                stickerView.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: 0),
                stickerView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: 0)
            ])
        }
    }

    @objc private func textViewTapped() {
        popViewType = .text
        processPopView()
    }

}

// MARK: - MessagesDataSource

extension CustomChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return SampleData.shared.currentSender
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }

    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {

        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)])
    }
}

// MARK: - MessageCellDelegate

extension CustomChatViewController: MessageCellDelegate {

    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
    }

    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
    }

    func didTapImage(in cell: MessageCollectionViewCell) {
        print("Image tapped")
    }

    func didTapCellTopLabel(in cell: MessageCollectionViewCell) {
        print("Top cell label tapped")
    }

    func didTapCellBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom cell label tapped")
    }

    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        print("Top message label tapped")
    }

    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom label tapped")
    }

    func didTapPlayButton(in cell: AudioMessageCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                print("Failed to identify message when audio cell receive tap gesture")
                return
        }
        guard audioController.state != .stopped else {
            // There is no audio sound playing - prepare to start playing for given audio message
            audioController.playSound(for: message, in: cell)
            return
        }
        if audioController.playingMessage?.messageId == message.messageId {
            // tap occur in the current cell that is playing audio sound
            if audioController.state == .playing {
                audioController.pauseSound(for: message, in: cell)
            } else {
                audioController.resumeSound()
            }
        } else {
            // tap occur in a difference cell that the one is currently playing sound. First stop currently playing and start the sound for given message
            audioController.stopAnyOngoingPlaying()
            audioController.playSound(for: message, in: cell)
        }
    }

    func didStartAudio(in cell: AudioMessageCell) {
        print("Did start playing audio sound")
    }

    func didPauseAudio(in cell: AudioMessageCell) {
        print("Did pause audio sound")
    }

    func didStopAudio(in cell: AudioMessageCell) {
        print("Did stop audio sound")
    }

    func didTapAccessoryView(in cell: MessageCollectionViewCell) {
        print("Accessory view tapped")
    }

}

// MARK: - MessageLabelDelegate

extension CustomChatViewController: MessageLabelDelegate {

    func didSelectAddress(_ addressComponents: [String: String]) {
        print("Address Selected: \(addressComponents)")
    }

    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }

    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }

    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }

    func didSelectTransitInformation(_ transitInformation: [String: String]) {
        print("TransitInformation Selected: \(transitInformation)")
    }

    func didSelectHashtag(_ hashtag: String) {
        print("Hashtag selected: \(hashtag)")
    }

    func didSelectMention(_ mention: String) {
        print("Mention selected: \(mention)")
    }

    func didSelectCustom(_ pattern: String, match: String?) {
        print("Custom data detector patter selected: \(pattern)")
    }

}

// MARK: - MessageInputBarDelegate

extension CustomChatViewController: InputBarAccessoryViewDelegate {

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {

        // Here we can parse for which substrings were autocompleted
        let attributedText = messageInputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in

            let substring = attributedText.attributedSubstring(from: range)
            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
            print("Autocompleted: `", substring, "` with context: ", context ?? [])
        }

        let components = inputBar.inputTextView.components
        messageInputBar.inputTextView.text = String()
        messageInputBar.invalidatePlugins()

        // Send button activity animation
        messageInputBar.sendButton.startAnimating()
        messageInputBar.inputTextView.placeholder = "Sending..."
        DispatchQueue.global(qos: .default).async {
            // fake send request task
            sleep(1)
            DispatchQueue.main.async { [weak self] in
                self?.messageInputBar.sendButton.stopAnimating()
                self?.messageInputBar.inputTextView.placeholder = "New Message"
                self?.insertMessages(components)
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }

    private func insertMessages(_ data: [Any]) {
        for component in data {
            let user = SampleData.shared.currentSender
            if let str = component as? String {
                let message = MockMessage(text: str, user: user, messageId: UUID().uuidString, date: Date())
                insertMessage(message)
            } else if let image = component as? UIImage {
                let message = MockMessage(image: image, user: user, messageId: UUID().uuidString, date: Date())
                insertMessage(message)
            }
        }
    }
}

// MARK: - MessagesDisplayDelegate

extension CustomChatViewController: MessagesDisplayDelegate {

    // MARK: - Text Messages

    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }

    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        switch detector {
        case .hashtag, .mention: return [.foregroundColor: UIColor.blue]
        default: return MessageLabel.defaultAttributes
        }
    }

    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date, .transitInformation, .mention, .hashtag]
    }

    // MARK: - All Messages

    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .primaryColor : UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {

        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .topRight : .topLeft
        return .bubbleTail(tail, .curved)
    }

    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if isFromCurrentSender(message: message) == false {
            let avatar = SampleData.shared.getAvatarFor(sender: message.sender)
            avatarView.set(avatar: avatar)
        }
    }

    // MARK: - Location Messages

    func annotationViewForLocation(message: MessageType, at indexPath: IndexPath, in messageCollectionView: MessagesCollectionView) -> MKAnnotationView? {
        let annotationView = MKAnnotationView(annotation: nil, reuseIdentifier: nil)
        let pinImage = #imageLiteral(resourceName: "ic_map_marker")
        annotationView.image = pinImage
        annotationView.centerOffset = CGPoint(x: 0, y: -pinImage.size.height / 2)
        return annotationView
    }

    func animationBlockForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> ((UIImageView) -> Void)? {
        return { view in
            view.layer.transform = CATransform3DMakeScale(2, 2, 2)
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [], animations: {
                view.layer.transform = CATransform3DIdentity
            }, completion: nil)
        }
    }

    func snapshotOptionsForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LocationMessageSnapshotOptions {

        return LocationMessageSnapshotOptions(showsBuildings: true, showsPointsOfInterest: true, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
    }

    // MARK: - Audio Messages

    func audioTintColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : UIColor(red: 15/255, green: 135/255, blue: 255/255, alpha: 1.0)
    }

    func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {
        audioController.configureAudioCell(cell, message: message) // this is needed especily when the cell is reconfigure while is playing sound
    }

}

// MARK: - MessagesLayoutDelegate

extension CustomChatViewController: MessagesLayoutDelegate {

    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return indexPath.section % 3 == 0 ? 50 : 0
    }

    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }

}

extension CustomChatViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let textView = otherGestureRecognizer.view, textView is InputTextView {
            return true
        }
        return false
    }
}

extension CustomChatViewController: ExtraActionViewControllerDelegate {
    func tapLeft() {
        print("delegate for tap left")
    }

    func tapCenter() {
        print("delegate for tap center")
    }

    func tapRight() {
        print("delegate for tap right")
    }
}

extension CustomChatViewController: StickerViewControllerDelegate {
    func didSelectStickerWithName(_ stickerNam: String) {
        let user = SampleData.shared.currentSender
        if let image = UIImage(named: stickerNam) {
           let message = MockMessage(image: image, user: user, messageId: UUID().uuidString, date: Date())
            insertMessage(message)
        }
    }
}
