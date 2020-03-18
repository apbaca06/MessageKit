//
//  ExtraActionViewController.swift
//  ChatExample
//
//  Created by justin on 2020/03/17.
//  Copyright © 2020 MessageKit. All rights reserved.
//

import UIKit

protocol ExtraActionViewControllerDelegate: class {
    func tapLeft()
    func tapCenter()
    func tapRight()
}

class ExtraActionViewController: UIViewController {
    weak var delegate: ExtraActionViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func tapLeftButton(_ sender: Any) {
        self.delegate?.tapLeft()
    }

    @IBAction func tapCenterButton(_ sender: Any) {
        self.delegate?.tapCenter()
    }

    @IBAction func tapRightButton(_ sender: Any) {
        self.delegate?.tapRight()
    }
}
