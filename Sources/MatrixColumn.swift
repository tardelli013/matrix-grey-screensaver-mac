import Foundation
import CoreGraphics

final class MatrixColumn {
    struct Cell {
        let row: Int
        var glyph: String
    }

    let x: CGFloat
    let rowCount: Int

    var row: Int
    var stepDelay: Int
    var stepCounter: Int
    var trailLength: Int
    private(set) var cells: [Cell] = []

    init(x: CGFloat, rowCount: Int) {
        self.x = x
        self.rowCount = max(rowCount, 1)
        self.row = -Int.random(in: 0...max(rowCount, 1))
        self.stepDelay = Int.random(in: 1...3)
        self.stepCounter = 0
        self.trailLength = Int.random(in: 8...22)
    }

    /// Returns true on frames where the head advanced one row.
    func tick() -> Bool {
        // Cheap glyph twinkle: rarely, mutate one of the existing trail glyphs.
        if !cells.isEmpty, Int.random(in: 0..<8) == 0 {
            let idx = Int.random(in: 0..<cells.count)
            cells[idx].glyph = Glyphs.random()
        }

        stepCounter += 1
        guard stepCounter >= stepDelay else { return false }
        stepCounter = 0
        row += 1

        cells.append(Cell(row: row, glyph: Glyphs.random()))
        while let oldest = cells.first, oldest.row < row - trailLength {
            cells.removeFirst()
        }

        if row - trailLength > rowCount + 5 {
            row = -Int.random(in: 0...20)
            stepDelay = Int.random(in: 1...3)
            trailLength = Int.random(in: 8...22)
            cells.removeAll()
        }
        return true
    }
}
