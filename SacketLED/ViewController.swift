//
//  ViewController.swift
//  SacketLED
//
//  Created by Oliver Elliott on 10/19/21.
//

import UIKit
import CoreBluetooth
import PhotosUI
import MobileCoreServices
import AVKit
import ALRT

let maxCharSend = 18 //Max char values that can send in 1 message

//Enum name ConnectionStatus with the following cases: displayConnected, bluetoothActive, bluetoothConnected, bluetoothDisconnected each with the name as a raw value
enum ConnectionStatus: String {
    case displayConnected = "displayConnected"
    case bluetoothActive = "bluetoothActive"
    case bluetoothConnected = "bluetoothConnected"
    case bluetoothDisconnected = "bluetoothDisconnected"
}

enum MatrixColor: String, CaseIterable, Codable {
    case black = "000000"
    case white = "151515"
    case gray = "050505"
    case lowWhite = "010101"
    case red = "150000"
    case lowRed = "010000"
    case mintGreen = "051500"
    case green = "001500"
    case lowGreen = "000100"
    case blue = "000015"
    case lowBlue = "000001"
    case lightBlue = "001515"
    case lowLightBlue = "000101"
    case yellow = "150700"
    case lowYellow = "030100"
    case orange = "150200"
    case lowOrange = "150100"
    case pink = "150006"
    case lowPink = "040001"
    case darkPink = "150002"
    case purple = "080015"
    case lowPurple = "010001"
}

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var mainTF: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var displayImage: UIImageView!
    
    @IBOutlet weak var colorsCollectionView: UICollectionView!
    
    var centralManager: CBCentralManager!
    var NanoPeripheral: CBPeripheral!
    var FFE1Characteristic: CBCharacteristic!
    var selectedTextColor = MatrixColor.white
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        sendButton.isEnabled = false
        mainTF.delegate = self
        
        colorsCollectionView.delegate = self
        colorsCollectionView.dataSource = self
    }
    
    @IBAction func mainTF(_ sender: Any) {
    }
    
    func sendText(_ text: String) {
        let value: [UInt8] = Array(text.utf8)
        let data = Data(value)
        NanoPeripheral.writeValue(data, for: FFE1Characteristic, type: .withResponse)
    }
    
    @IBAction func sendTextButton(_ sender: Any) { //f000000t4c0001x150200Hello this is a loop|s
        let text = "f000000t4c0001x\(selectedTextColor.rawValue)\(mainTF.text ?? " ")|sr"
        sendDataToDisplay(text)
    }
    
    @IBAction func sendButton(_ sender: Any) { //f000000t4c0001x150000Hello|s
        let rawText = mainTF.text ?? " "
        sendDataToDisplay(rawText)
    }
    
    func sendDataToDisplay(_ text: String) {
        var rawText = text
        if rawText == "" {
            rawText = " "
        }
        //let text = "*\(rawText)|"
        let text = "$\(rawText)^"
        let totalSends = Int((Double(text.count)/Double(maxCharSend)).rounded(.up))
        for i in 0 ..< totalSends {
            let startIndex = text.index(text.startIndex, offsetBy: (i*maxCharSend))
            var endOffset = maxCharSend-1
            if i == totalSends-1 {
                endOffset = (text.count % maxCharSend)-1
            }
            if endOffset == -1 {
                endOffset = maxCharSend-1
            }
            let endIndex = text.index(startIndex, offsetBy: endOffset)
            let stringToSend = String(text[startIndex ... endIndex])
            print("String to send: \(stringToSend)")
            sendText(stringToSend)
        }
        print("Sent \"\(text)\" to LED display")
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    @IBAction func uploadImageButton(_ sender: Any) {
        if #available(iOS 14, *) {
            var configuration = PHPickerConfiguration()
            configuration.filter = .images
            configuration.selectionLimit = 1
            // Create instance of PHPickerViewController
            let picker = PHPickerViewController(configuration: configuration)
            // Set the delegate
            picker.delegate = self
            // Present the picker
            present(picker, animated: true)
        }
    }
    
    func sendImageToDisplay(_ image: UIImage) {
        //displayImage.image = image
        let newSize = CGSize(width: 32, height: 64)
        let scaledImage = image.scalePreservingAspectRatio(targetSize: newSize)
        displayImage.image = scaledImage
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        MatrixColor.allCases.count-1 //Exclude black
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorSelectionCell", for: indexPath) as! ColorSelectionCell
        cell.outerColor.layer.cornerRadius = cell.outerColor.bounds.width/2
        cell.separation.layer.cornerRadius = cell.separation.bounds.width/2
        cell.innerColor.layer.cornerRadius = cell.innerColor.bounds.width/2
        let color = MatrixColor.allCases[indexPath.item+1].rawValue //Exclude black
        cell.outerColor.backgroundColor = UIColor(named: color)
        cell.innerColor.backgroundColor = UIColor(named: color)
        if selectedTextColor.rawValue == color {
            cell.separation.alpha = 1
        } else {
            cell.separation.alpha = 0
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 30, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let spacing: CGFloat = CGFloat(9*collectionView.numberOfItems(inSection: 0))
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedTextColor = MatrixColor.allCases[indexPath.row+1] //Exclude black
        colorsCollectionView.reloadData()
    }
}

extension ViewController: PHPickerViewControllerDelegate {

    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // Always dismiss the picker first
        dismiss(animated: true)
        if let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self)
            { [weak self]  image, error in
                DispatchQueue.main.async {
                  guard let self = self else { return }
                  if let image = image as? UIImage {
                      self.sendImageToDisplay(image)
                    } else {
                        ALRT.create(.alert, title: "Error", message: "Unable to get image").addOK().show()
                    }
                }
            }
        }
    }

}

class ColorSelectionCell: UICollectionViewCell {
    
    @IBOutlet var outerColor: UIView!
    @IBOutlet var separation: UIView!
    @IBOutlet var innerColor: UIView!
    
}
