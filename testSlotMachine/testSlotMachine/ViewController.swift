//
//  ViewController.swift
//  testSlotMachine
//
//  Created by emil kurbanov on 10.04.2022.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var buttonState: UIButton!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    
    let array = ["😇", "🤬", "🥶", "🧐"]
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    typealias completionBlock = () -> Void

    @IBAction func startGames(_ sender: Any) {
        
        label1.text = array.randomElement()
        label2.text = array.randomElement()
        if label1.text == label2.text {
            let alertController = UIAlertController(title: "ПОБЕДА!!!🥳", message: "Вы выиграли", preferredStyle: .alert)
            let action = UIAlertAction(title: "Начать заново?", style: .cancel)
            self.present(alertController, animated: true)
            alertController.addAction(action)
            print("Вы выиграли")
        } else {
            print("Вы прогиграли!")
        }
    }
}
