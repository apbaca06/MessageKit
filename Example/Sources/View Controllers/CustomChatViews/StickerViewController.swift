//
//  StickerViewController.swift
//  ChatExample
//
//  Created by justin on 2020/03/17.
//  Copyright © 2020 MessageKit. All rights reserved.
//

import UIKit

protocol StickerViewControllerDelegate: class {
    func didSelectStickerWithName(_ stickerNam: String)
}

class StickerViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!

    weak var delegate: StickerViewControllerDelegate?
    private let stickerWidth: CGFloat = 97
    private let stickerHeight: CGFloat = 97
    private var stickersArray: [String] = []
    private let pageOfNumber = 6

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(UINib.init(nibName: "StickerCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "StickerCollectionViewCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.currentPageIndicatorTintColor = .green

        let numbers = Array(1...9)
        numbers.forEach { number in
            let stickerName = "sticker_\(number)"
            stickersArray.append(stickerName)
        }
    }

}

extension StickerViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentIndex: Int = Int(scrollView.contentOffset.x / scrollView.frame.width)
        pageControl.currentPage = currentIndex
    }
}

extension StickerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        var sections: Int = stickersArray.count / pageOfNumber

        if stickersArray.count % 6 > 0 {
            sections += 1
        }
        pageControl.numberOfPages = sections

        return sections
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageOfNumber
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let collectionViewCell: StickerCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCollectionViewCell", for: indexPath) as? StickerCollectionViewCell else {
            fatalError()
        }

        let stickerIndex = indexPath.section * pageOfNumber + indexPath.row

        if stickersArray.indices.contains(stickerIndex) {
            collectionViewCell.imageView.image = UIImage(named: stickersArray[stickerIndex])
            collectionViewCell.isUserInteractionEnabled = true
        } else {
            collectionViewCell.imageView.image = nil
            collectionViewCell.isUserInteractionEnabled = false
        }

        return collectionViewCell
    }

}

extension StickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let stickerIndex = indexPath.section * 6 + indexPath.row + 1
        delegate?.didSelectStickerWithName("sticker_\(stickerIndex)")
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = .lightGray

        return true
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = .clear
    }
}

extension StickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: stickerWidth, height: stickerHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let verticalPadding = (collectionView.bounds.size.height - stickerHeight * 2) / 3
        let horizontalPadding = (collectionView.bounds.size.width - stickerWidth * 3) / 4

        return UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return (collectionView.bounds.size.width - stickerWidth * 3) / 4
    }
}
