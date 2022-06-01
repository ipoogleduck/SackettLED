//
//  Shape.swift
//  SacketLED
//
//  Created by Oliver Elliott on 4/23/22.
//

import Foundation

enum Orientation {
    
    case Zero
    case Ninety
    case OneEighty
    case TwoSeventy
    
}

enum BlockColor: Int, CaseIterable {
    case turquoise = 0
    case blue = 1
    case orange = 2
    case yellow = 3
    case green = 4
    case purple = 5
    case red = 6
}

enum ShapeType: String, CaseIterable {
    
    case I = "I", J = "J", L = "L", O = "O", S = "S", T = "T", Z = "Z"
    
    func color() -> BlockColor {
        switch self {
        case .I:
            return .turquoise
        case .J:
            return .blue
        case .L:
            return .orange
        case .O:
            return .yellow
        case .S:
            return .green
        case .T:
            return .purple
        case .Z:
            return .red
        }
    }
    
    func startOrientation() -> Int {
        switch self {
        case .I:
            return 0
        case .J:
            return 2
        case .L:
            return 2
        case .O:
            return 0
        case .S:
            return 0
        case .T:
            return 2
        case .Z:
            return 0
        }
    }
    
    func layout() -> [[[BlockColor?]]] {
        let col = self.color()
        let nilLayout: [[BlockColor?]] = [
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil]
        ]
        var layout: [[[BlockColor?]]] = []
        switch self {
        case .I:
            layout = [nilLayout, nilLayout]
            
            layout[0][0][2] = col
            layout[0][1][2] = col
            layout[0][2][2] = col
            layout[0][3][2] = col
            
            layout[1][2][0] = col
            layout[1][2][1] = col
            layout[1][2][2] = col
            layout[1][2][3] = col
        case .J:
            layout = [nilLayout, nilLayout, nilLayout, nilLayout]
            
            layout[0][0][0] = col
            layout[0][0][1] = col
            layout[0][1][1] = col
            layout[0][2][1] = col
            
            layout[1][1][0] = col
            layout[1][2][0] = col
            layout[1][1][1] = col
            layout[1][1][2] = col
            
            layout[2][0][1] = col
            layout[2][1][1] = col
            layout[2][2][1] = col
            layout[2][2][2] = col
            
            layout[3][1][0] = col
            layout[3][1][1] = col
            layout[3][1][2] = col
            layout[3][0][2] = col
            
        case .L:
            layout = [nilLayout, nilLayout, nilLayout, nilLayout]
            
            layout[0][0][1] = col
            layout[0][1][1] = col
            layout[0][2][1] = col
            layout[0][2][0] = col
            
            layout[1][1][0] = col
            layout[1][1][1] = col
            layout[1][1][2] = col
            layout[1][2][2] = col
            
            layout[2][0][1] = col
            layout[2][0][2] = col
            layout[2][1][1] = col
            layout[2][2][1] = col
            
            layout[3][0][0] = col
            layout[3][1][0] = col
            layout[3][1][1] = col
            layout[3][1][2] = col
        case .O:
            layout = [nilLayout]
            
            layout[0][1][0] = col
            layout[0][2][0] = col
            layout[0][1][1] = col
            layout[0][2][1] = col
        case .S:
            layout = [nilLayout, nilLayout]
            
            layout[0][0][1] = col
            layout[0][1][0] = col
            layout[0][1][1] = col
            layout[0][2][0] = col
            
            layout[1][1][0] = col
            layout[1][1][1] = col
            layout[1][2][1] = col
            layout[1][2][2] = col
        case .T:
            layout = [nilLayout, nilLayout, nilLayout, nilLayout]
            
            layout[0][1][0] = col
            layout[0][0][1] = col
            layout[0][1][1] = col
            layout[0][2][1] = col
            
            layout[1][1][0] = col
            layout[1][1][1] = col
            layout[1][1][2] = col
            layout[1][2][1] = col
            
            layout[2][1][2] = col
            layout[2][0][1] = col
            layout[2][1][1] = col
            layout[2][2][1] = col
            
            layout[3][0][1] = col
            layout[3][1][0] = col
            layout[3][1][1] = col
            layout[3][1][2] = col
        case .Z:
            layout = [nilLayout, nilLayout]
            
            layout[0][0][1] = col
            layout[0][1][1] = col
            layout[0][1][2] = col
            layout[0][2][2] = col
            
            layout[1][1][1] = col
            layout[1][2][0] = col
            layout[1][2][1] = col
            layout[1][1][2] = col
        }
        return layout
    }
    
    func twoByFour() -> [[BlockColor?]] {
        var matrix = layout()[startOrientation()]
        
        var count = 0
        for i in 0 ..< 4 {
            if matrix.allSatisfy({ $0[3-i] == nil }) && count < 2 {
                for j in 0 ..< 4 { //Remove last row
                    matrix[j].remove(at: 3-i)
                }
                count += 1
            }
        }
        
        return matrix
    }
    
}

struct Point {
    var x: Int
    var y: Int
}

struct Shape {
    
    //Required init
    var type: ShapeType
    
    //Internal
    private var orientation = 0
    private(set) var position: Point?
    
    init(type: ShapeType) {
        self.type = type
        orientation = type.startOrientation()
        position = Point(x: 3, y: -topRowOfShape())
    }
    
    ///Gets block matrix for current orientation
    func matrix() -> [[BlockColor?]] {
        type.layout()[orientation]
    }
    
    ///Gets top row of shape in it's current orienation
    func topRowOfShape() -> Int {
        for i in 0 ..< 4 {
            if !matrix().allSatisfy({$0[i] == nil}) {
                return i
            }
        }
        return 0
    }
    
    ///Gets bottom row of shape in it's current orienation
    func bottomRowOfShape() -> Int {
        for i in 0 ..< 4 {
            if !matrix().allSatisfy({$0[3-i] == nil}) {
                return 3-i
            }
        }
        return 0
    }
    
    ///Gets left column of shape in it's current orienation
    func leftColumnOfShape() -> Int {
        for i in 0 ..< 4 {
            if !matrix()[i].allSatisfy({$0 == nil}) {
                return i
            }
        }
        return 0
    }
    
    ///Gets left column of shape in it's current orienation
    func rightColumnOfShape() -> Int {
        for i in 0 ..< 4 {
            if !matrix()[3-i].allSatisfy({$0 == nil}) {
                return 3-i
            }
        }
        return 0
    }
    
    ///Moves position one block down and makes sure it doesn't go below the bottom
    mutating func moveDown() -> Bool {
        if position != nil && position!.y + bottomRowOfShape() + 1 < 20 {
            position!.y += 1
            return true
        }
        return false
    }
    
    ///Moves position one block left and makes sure it doesn't go too far left
    mutating func moveLeft() -> Bool {
        if position != nil && position!.x + leftColumnOfShape() > 0 {
            position!.x -= 1
            return true
        }
        return false
    }
    
    ///Moves position one block right and makes sure it doesn't go too far left
    mutating func moveRight() -> Bool {
        if position != nil && position!.x + rightColumnOfShape() + 1 < 10 {
            position!.x += 1
            return true
        }
        return false
    }
    
    func validRotate() -> Bool {
        position!.y + bottomRowOfShape() + 1 <= 20 && position!.x + leftColumnOfShape() >= 0 && position!.x + rightColumnOfShape() + 1 <= 10
    }
    
    ///Rotates block to the right
    mutating func rotateRight() -> Bool {
        orientation += 1
        if orientation >= type.layout().count {
            orientation = 0
        }
        
        if validRotate() {
            return true
        }
        
        return false
    }
    
    ///Rotates block to the right
    mutating func rotateLeft() -> Bool {
        orientation -= 1
        if orientation < 0 {
            orientation = type.layout().count-1
        }
        
        if validRotate() {
            return true
        }
        
        return false
    }
    
    
}
