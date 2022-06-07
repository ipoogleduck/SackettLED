//
//  Gameboard.swift
//  SacketLED
//
//  Created by Oliver Elliott on 4/23/22.
//

import Foundation
import AVFoundation

enum Level: Int, CaseIterable {
    case zero = 0
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case eleven = 11
    case twelve = 12
    case thirteen = 13
    case fourteen = 14
    case fifteen = 15
    case sixteen = 16
    case seventeen = 17
    case eighteen = 18
    case nineteen = 19
    
    func framesPerCell() -> Int {
        switch self {
        case .zero:
            return 48
        case .one:
            return 43
        case .two:
            return 38
        case .three:
            return 33
        case .four:
            return 28
        case .five:
            return 23
        case .six:
            return 18
        case .seven:
            return 13
        case .eight:
            return 8
        case .nine:
            return 6
        case .ten:
            return 5
        case .eleven:
            return 5
        case .twelve:
            return 5
        case .thirteen:
            return 4
        case .fourteen:
            return 4
        case .fifteen:
            return 4
        case .sixteen:
            return 3
        case .seventeen:
            return 3
        case .eighteen:
            return 3
        case .nineteen:
            return 2
        }
    }
    
    func blockDropRate() -> Double {
        return Double(framesPerCell())/50
    }
    
    func blockSoftDropRate() -> Double {
        return 0.06 //0.13 //0.05 //blockDropRate()/2
    }
    
    func string() -> String {
        return String(self.rawValue)
    }
    
    func scoreIncrease(with clearAmount: Int) -> Int {
        let multiplier = self.rawValue + 1
        if clearAmount == 1 {
            return 40*multiplier
        } else if clearAmount == 2 {
            return 100*multiplier
        } else if clearAmount == 3 {
            return 300*multiplier
        } else {
            return 1200*multiplier
        }
    }
    
    func clearsBeforeNextLevel() -> Int {
        return (self.rawValue+1)*5
    }
    
    mutating func next() {
        if self != Level.allCases.last {
            self = Level(rawValue: self.rawValue + 1)!
        }
    }
    
}

struct Pixel {
    var position: Point
    var color: BlockColor?
}

class Gameboard {
    
    private(set) var solidBoard: [[BlockColor?]] = []
    private var currentShape: Shape?
    private var nextShape: Shape?
    private var clears = 0
    private var level = Level.zero
    private var score = 0
    private(set) var isRunning = false //True if game is running
    private var gameMusic: Sound!
    private var isPlayingFastMusic = false

    private var musicPlayer: AVAudioPlayer?
    
    private var blockTimer: Timer?
    private weak var downPressTimer: Timer?
    private weak var movePressTimer: Timer?
    private var currentMovePress = 0 //For left right motion
    
    var delegate: GameDelegate?
    
    //MARK: Public Functions
    
    ///Initializes game with a starting level
    init(level: Level) {
        clearBoard()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback) //Sets playback to play regardless of mute switch
        } catch(let error) {
            print(error.localizedDescription)
        }
        self.level = level
    }
    
    ///Starts/restarts game, including music.
    ///Note that stopGame() should be called before restarting the game
    func startGame() {
        isRunning = true
        delegate?.displayRefresh(solidBoard)
        gameMusic = Sound.randomSong()
        playMusic(gameMusic, fast: false)
        addNextShapeToGameboard()
        startBlockTimer()
    }
    
    ///Stops game and music, calls delegate method gameEnd with ending info.
    ///fullGame should be true if game was played to the end, otherwise if it ends early (ie user quits) it should be false
    func stopGame(fullGame: Bool = false) {
        isRunning = false
        delegate?.gameEnd(score: score, scoreString: scoreString(), level: level, clears: clears, fullGame: fullGame)
        stopTimer()
        musicPlayer?.stop()
    }
    
    ///Starts soft drop of shape, where shape moves down fast.
    ///This method should be called from a Long Press Gesture Recognizer in UIKit.
    ///Note that you must call endShapeSoftDrop() when user lifts finger from button
    func startShapeSoftDrop() {
        downPressTimer?.invalidate()
        blockTimer?.invalidate()
        if isRunning {
            moveShapeDown()
        }
        var downCount = 0
        downPressTimer = Timer.scheduledTimer(withTimeInterval: level.blockSoftDropRate(), repeats: true) { [weak self] timer in
            guard let self = self else {
                self?.downPressTimer?.invalidate()
                return
            }
            if self.isRunning {
                self.moveShapeDown(with: downCount)
                downCount += 1
            }
        }
    }
    
    ///Stops shape soft drop, should be called after startShapeSoftDrop()
    ///Will be called automatically when shape reaches it's lowest point in the gameboard
    func endShapeSoftDrop() {
        if isRunning {
            startBlockTimer()
        }
        downPressTimer?.invalidate()
    }
    
    ///Starts movement of block left or right.
    ///There is an initial delay after the first movement, and then block is moved fast sideways if endMoveTimer() hasn't been called.
    ///This method should be called from a Long Press Gesture Recognizer in UIKit.
    ///You must call endMoveTimer() to stop movement, should be called when user lifts finger from the Long Press Gesture Recognizer
    func startMoveTimer(for leftButton: Bool) {
        movePressTimer?.invalidate()
        currentMovePress += 1
        let press = currentMovePress
        leftButton ? moveShapeLeft() : moveShapeRight()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if press == self.currentMovePress {
                self.movePressTimer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] timer in //0.05
                    guard let self = self else {
                        self?.movePressTimer?.invalidate()
                        return
                    }
                    if self.isRunning {
                        leftButton ? self.moveShapeLeft() : self.moveShapeRight()
                    }
                }
            }
        }
    }
    
    ///Stops shape side to side movement, should be called after startMoveTimer()
    func endMoveTimer() {
        currentMovePress += 1
        movePressTimer?.invalidate()
    }
    
//    func hardDropShape() {
//        guard var shape = currentShape else { return }
//        while !shapeAtLowest(shape) {
//            shape.moveDown()
//        }
//        currentShape = shape
//        if adoptShape() {
//            playSound(.fall)
//            rowElimination()
//            if let delegate = delegate {
//                addShapeToGameboard(delegate.newShapeRequest())
//            }
//        } else {
//            print("Error adopting shape")
//        }
//    }
    
    ///As an alternative to startMoveTimer(), this method can be used to move the shape once to the left, if it doesn't collide with other blocks
    func moveShapeLeft() {
        guard var shape = currentShape else { return }
        if shape.moveLeft() && !shapeColides(shape) {
            currentShape = shape
            SoundEffect.sharedInstance.playSound(.move)
            updateShape(shapeAdopted: false)
        }
    }
    
    ///As an alternative to startMoveTimer(), this method can be used to move the shape once to the right, if it doesn't collide with other blocks
    func moveShapeRight() {
        guard var shape = currentShape else { return }
        if shape.moveRight() && !shapeColides(shape) {
            currentShape = shape
            SoundEffect.sharedInstance.playSound(.move)
            updateShape(shapeAdopted: false)
        }
    }
    
    ///Rotates shape once to the right, if it doesn't collide with other blocks
    func rotateShapeRight() {
        guard var shape = currentShape else { return }
        if shape.rotateRight() && !shapeColides(shape) {
            currentShape = shape
            SoundEffect.sharedInstance.playSound(.rotate)
            updateShape(shapeAdopted: false)
        }
    }
    
    ///Rotates shape once to the left, if it doesn't collide with other blocks
    func rotateShapeLeft() {
        guard var shape = currentShape else { return }
        if shape.rotateLeft() && !shapeColides(shape) {
            currentShape = shape
            SoundEffect.sharedInstance.playSound(.rotate)
            updateShape(shapeAdopted: false)
        }
    }
    
    ///Will trigger all delagate methods that provide game info.
    ///Usefull for when display may be out of date if user moves out of connection range for a while
    func requestFullDisplayRefresh() {
        refreshDisplay()
        delegate?.updateScore(with: scoreString())
        delegate?.updateLevel(with: level)
        if let nextShape = nextShape {
            delegate?.updateNextShape(with: nextShape)
        }
    }
    
    
    //MARK: PRIVATE FUNCTIONS
    
    private func clearBoard() {
        solidBoard = []
        for _ in 0 ..< 10 {
            var column: [BlockColor?] = []
            for _ in 0 ..< 20 {
                column.append(nil)
            }
            solidBoard.append(column)
        }
    }
    
    
    private func startBlockTimer() {
        stopTimer()
        blockTimer = Timer.scheduledTimer(withTimeInterval: level.blockDropRate(), repeats: true, block: { _ in
            self.moveShapeDown()
        })
    }
    
    private func stopTimer() {
        blockTimer?.invalidate()
    }
    
    private func gameOver() {
        stopGame(fullGame: true)
        SoundEffect.sharedInstance.playSound(.gameOver)
    }
    
    private func updateShape(shapeAdopted: Bool) {
        if let shape = currentShape {
            delegate?.updatePixels(with: mapShapeToPixelsInGameboard(shape: shape), clearable: !shapeAdopted)
        }
    }
    
    private func scoreString() -> String {
        return String(score)
//        var string = ""
//        for _ in 0 ..< 6-String(score).count {
//            string += "0"
//        }
//        string += String(score)
//        return string
    }
    
    private func spawnNewShape() -> Shape {
        let shapeType = ShapeType.allCases.filter( { $0 != currentShape?.type }).randomElement()! //Chooses random element that isn't current element
        return Shape(type: shapeType)
    }
    
    private func addNextShapeToGameboard() {
        if let nextShape = nextShape {
            currentShape = nextShape
        } else {
            currentShape = spawnNewShape()
        }
        nextShape = spawnNewShape()
        delegate?.updateNextShape(with: nextShape!)
        updateShape(shapeAdopted: false)
        handleMusic()
        if shapeColides(currentShape!) {
            gameOver()
        }
    }
    
    private func refreshDisplay() {
        delegate?.displayRefresh(solidBoard)
    }
    
    private func moveShapeDown(with dropCount: Int? = nil) {
        guard var shape = currentShape else { return }
        if !shapeAtLowest(shape) && shape.moveDown() { //Check if shape has reached bottom
            currentShape = shape
            updateShape(shapeAdopted: false)
        } else {
            if adoptShape() {
                if let dropCount = dropCount {
                    score += dropCount
                    delegate?.updateScore(with: scoreString())
                }
                SoundEffect.sharedInstance.playSound(.fall)
                rowElimination() //I can probably add something here to send all this data at once: score, up next block, and level
                addNextShapeToGameboard()
            } else {
                print("Error adopting shape")
            }
        }
    }
    
    private func playMusic(_ sound: Sound, fast: Bool) {
        let soundString = fast ? sound.fastSoundtrack() : sound.rawValue
        guard let path = Bundle.main.path(forResource: soundString, ofType: "mp3") else {
            return }
        let url = URL(fileURLWithPath: path)
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.volume = 0.2
            musicPlayer?.play()
            
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    private func shapeColides(_ shape: Shape) -> Bool {
        guard let position = shape.position else { return false }
        
        for i in 0 ..< 4 where position.x+i >= 0 && position.x <= 10 {
            for j in 0 ..< 4 where position.y+j >= 0 && position.y <= 20 {
                if shape.matrix()[i][j] != nil && solidBoard[position.x+i][position.y+j] != nil {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func shapeAtLowest(_ shape: Shape) -> Bool {
        var nextShape = shape
        
        if nextShape.moveDown() {
            return shapeColides(nextShape)// || shapeColides(shape)
        } else {
            return true
        }
    }
    
    private func mapShapeToPixelsInGameboard(shape: Shape) -> [Pixel] {
        var pixels: [Pixel] = []
        let position = shape.position!
        for i in 0 ..< 4 {
            for j in 0 ..< 4 where position.y+j >= 0 {
                if let color = shape.matrix()[i][j] {
                    pixels.append(Pixel(position: Point(x: position.x+i, y: position.y+j), color: color))
                }
            }
        }
        return pixels
    }
    
    private func adoptShape() -> Bool {
        guard let shape = currentShape else { return false }
        
        for pixel in mapShapeToPixelsInGameboard(shape: shape) {
            solidBoard[pixel.position.x][pixel.position.y] = pixel.color
        }
        
        updateShape(shapeAdopted: true)
        endShapeSoftDrop()
        
        return true
    }
    
    private func rowElimination() -> Bool {
        var eliminationRows: [Int] = []
        for i in 0 ..< 20 {
            if solidBoard.allSatisfy({ $0[19 - i] != nil }) { //This row is empty
                eliminationRows.append(19-i)
            }
        }
        if !eliminationRows.isEmpty {
            addScoreForClearedLines(amount: eliminationRows.count)
            clears += eliminationRows.count
            SoundEffect.sharedInstance.playSound(eliminationRows.count < 4 ? .clear : .tetris)
            eliminateRows(eliminationRows.reversed()) //Reverse so that elimination starts at top, avoiding any problems
            levelUpdate()
            refreshDisplay()
            return true
        }
        return false
    }
    
    private func levelUpdate() {
        if clears >= level.clearsBeforeNextLevel() {
            level.next()
            delegate?.updateLevel(with: level)
            SoundEffect.sharedInstance.playSound(.levelUp)
        }
    }
    
    private func addScoreForClearedLines(amount: Int) {
        score += level.scoreIncrease(with: amount)
        delegate?.updateScore(with: scoreString())
    }
    
    private func handleMusic() {
        let isValidFast = !solidBoard.allSatisfy({ $0[6] == nil })
        if isValidFast != isPlayingFastMusic {
            playMusic(gameMusic, fast: isValidFast)
            isPlayingFastMusic = isValidFast
        }
    }
    
    private func eliminateRows(_ rows: [Int]) {
        for row in rows {
            for i in 0 ..< 10 {
                solidBoard[i].remove(at: row)
                solidBoard[i].insert(nil, at: 0)
            }
        }
    }
    
    deinit {
        print("Deinit gameboard")
    }
    
}

protocol GameDelegate {
    func updatePixels(with pixels: [Pixel], clearable: Bool)
    func displayRefresh(_ dislay: [[BlockColor?]])
    func updateScore(with score: String)
    func updateNextShape(with shape: Shape)
    func updateLevel(with newLevel: Level)
    func gameEnd(score: Int, scoreString: String, level: Level, clears: Int, fullGame: Bool)
}
