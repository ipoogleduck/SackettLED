//
//  TetrisSampleVC.swift
//  SacketLED
//
//  Created by Oliver Elliott on 4/24/22.
//

import UIKit

class TetrisSampleVC: UIViewController, GameDelegate {
    
    @IBOutlet weak var tetrisImage: UIImageView!
    @IBOutlet weak var upNextImage: UIImageView!
    @IBOutlet weak var gameOverView: UIView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    
    var game: Gameboard!
    var matrix: [[BlockColor?]] = []
    var lastClearableSection: [Pixel] = []
    
    var staringLevel: Level!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLevel(with: staringLevel)
        game = Gameboard(level: staringLevel)
        game.delegate = self
        startGame()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        game.stopGame()
        game.delegate = nil
    }
    
    func startGame() {
        gameOverView.isHidden = true
        scoreLabel.text = "0"
        game.startGame()
        gameBoardToImage()
    }
    
    func gameBoardToImage() {
        let image = UIImage(cgImage: makeImageFromMatrixColors(matrix))
        tetrisImage.image = image
    }
    
    //Make CGImage from the matrix colors inputted
    func makeImageFromMatrixColors(_ matrix: [[BlockColor?]]) -> CGImage {
        
        let width = matrix.count
        let height = matrix[0].count
        
        var srgbArray: [UInt32] = []

        for i in 0 ..< height {
            for j in 0 ..< width {
                let rawColor = matrix[j][i]?.rawValue ?? 11
                srgbArray.append(UIColor(named: "bc\(rawColor)")!.hexa)
            }
        }
        
        let multiplier = 30
        
        srgbArray = increaseResolution(of: srgbArray, by: multiplier, width: width, height: height)
        
        let newWidth = width*multiplier
        let newHeight = height*multiplier
        
        let cgImg = srgbArray.withUnsafeMutableBytes { (ptr) -> CGImage in
            let ctx = CGContext(
                data: ptr.baseAddress,
                width: newWidth,
                height: newHeight,
                bitsPerComponent: 8,
                bytesPerRow: 4*newWidth,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue +
                    CGImageAlphaInfo.premultipliedFirst.rawValue
            )!
            return ctx.makeImage()!
        }
        
        return cgImg
    }
    
    //Increase reolution of 2D array
    func increaseResolution(of array: [UInt32], by multiplier: Int, width: Int, height: Int) -> [UInt32] {
        var newArray: [UInt32] = []
        for i in 0 ..< height {
            var xArray: [UInt32] = []
            for j in 0 ..< width {
                for _ in 0 ..< multiplier {
                    xArray.append(array[(i*width)+j])
                    //print((i*j)+j)
                }
            }
            for _ in 0 ..< multiplier {
                newArray.append(contentsOf: xArray)
            }
        }
        return newArray
    }
    
    func updatePixels(with pixels: [Pixel], clearable: Bool) {
        for pixel in lastClearableSection {
            matrix[pixel.position.x][pixel.position.y] = nil
        }
        if clearable {
            lastClearableSection = pixels
        } else {
            lastClearableSection = []
        }
        
        for pixel in pixels {
            matrix[pixel.position.x][pixel.position.y] = pixel.color
        }
        gameBoardToImage()
    }
    
    func displayRefresh(_ dislay: [[BlockColor?]]) {
        matrix = dislay
        gameBoardToImage()
    }
    
    func updateNextShape(with shape: Shape) {
        let matrix = shape.type.twoByFour()
        let image = UIImage(cgImage: self.makeImageFromMatrixColors(matrix))
        upNextImage.image = image
    }
    
    func updateLevel(with newLevel: Level) {
        levelLabel.text = "Level \(newLevel.string())"
    }
    
    func updateScore(with score: String) {
        scoreLabel.text = score
    }
    
    func gameEnd(score: Int, scoreString: String, level: Level, clears: Int, fullGame: Bool) {
        gameOverView.isHidden = false
        let topScore = UserDefaults.getString(key: .topPracticeScore)
        if let topScore = topScore, let topScoreInt = Int(topScore), topScoreInt > score {
            //Display old best score
        } else {
            UserDefaults.save(scoreString, key: .topPracticeScore)
            //Display new best score
        }
    }
    
    @IBAction func leftLongPress(_ gesture: UILongPressGestureRecognizer) {
        handleTimerFor(leftButton: true, gesture: gesture)
    }
    
    @IBAction func rightLongPress(_ gesture: UILongPressGestureRecognizer) {
        handleTimerFor(leftButton: false, gesture: gesture)
    }
    
    func handleTimerFor(leftButton: Bool, gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            game.startMoveTimer(for: leftButton)
        } else if gesture.state == .ended || gesture.state == .cancelled {
            game.endMoveTimer()
        }
    }
    
    @IBAction func downLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            game.startShapeSoftDrop()
        } else if gesture.state == .ended || gesture.state == .cancelled {
            game.endShapeSoftDrop()
        }
    }
    
    @IBAction func rotateButton(_ sender: Any) {
        game.rotateShapeRight()
    }
    
    @IBAction func reset(_ sender: Any) {
        if !game.isRunning {
            game.delegate = nil
            game = Gameboard(level: staringLevel)
            game.delegate = self
            startGame()
        }
    }
    
    @IBAction func doneButton(_ sender: Any) {
        dismiss(animated: true)
    }
    
    deinit {
        print("Deinit TetrisSampleVC")
    }
    
    
}

extension UIColor {
    var hexa: UInt32 {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        var value: UInt32 = 0
        value += UInt32(alpha * 255) << 24
        value += UInt32(abs(red)   * 255) << 16
        value += UInt32(abs(green) * 255) << 8
        value += UInt32(abs(blue)  * 255)
        return value
    }
    convenience init(hexa: UInt32) {
        self.init(red  : CGFloat((hexa & 0xFF0000)   >> 16) / 255,
                  green: CGFloat((hexa & 0xFF00)     >> 8)  / 255,
                  blue : CGFloat( hexa & 0xFF)              / 255,
                  alpha: CGFloat((hexa & 0xFF000000) >> 24) / 255)
    }
}
