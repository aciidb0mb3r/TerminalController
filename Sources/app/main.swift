import Foundation

#if os(OSX)
import Darwin.ncurses
#else
import CNCurses
#endif

private func _tigetnum(_ str: String) -> Int? {
    return str.withCString { ptr in
        let ptr = UnsafeMutablePointer<Int8>(ptr)
        let value = Int(tigetnum(ptr))
        if value == -2 { return nil }
        return value
    }
}

private func _tigetflag(_ str: String) -> Bool {
    return str.withCString { ptr in
        let ptr = UnsafeMutablePointer<Int8>(ptr)
        return tigetflag(ptr) != -1 // tigetflag returns -1 if not a capability.
    }
}

private func _tigetstr(_ str: String) -> String {
    return str.withCString { ptr in
        let ptr = UnsafeMutablePointer<Int8>(ptr)
        guard let result = tigetstr(ptr) else { return "" }
        return String(cString: result)
    }
}

//private func _tparm(_ str: String, idx: Int) -> String {
//    return str.withCString { ptr in
//        let ptr = UnsafeMutablePointer<Int8>(ptr)
//        guard let result = tparm(ptr, idx) else { return "" }
//        return String(cString: result)
//    }
//}


final class TerminalController {

    /// Width of the terminal.
    let width: Int?

    /// Height of the terminal.
    let height: Int?

    // Newline ignored after 80 cols.
    let xn: Bool

    /// Screen pointer.
    private let screen: OpaquePointer

    // MARK:- Cursor movements:

    /// Move cursor to beginning of the line.
    let bol: String

    /// Move cursor up one line.
    let up: String

    /// Move cursor down one line.
    let down: String

    /// Move cursor left one line.
    let left: String

    /// Move cursor right one line.
    let right: String

    // MARK:- Deletion:

    /// Clear the screen and move to home position.
    let clearScreen: String

    /// Clear to the end of the line.
    let clearEol: String

    /// Clear to the beginning of the line.
    let clearBol: String

    /// Clear to the end of the screen.
    let clearEos: String

    let bold: String

    let normal: String

    let green: String

    init() {
        // Setup curses
        guard let screen = newterm(nil, stdin, stdout) else {
            fatalError("Throw instead")
        }
        self.screen = screen
        // Get width and height.
        width = _tigetnum("cols")
        height = _tigetnum("lines")
        xn = _tigetflag("xenl")

        // Movements.
        bol = _tigetstr("cr")
        up = _tigetstr("cuu1")
        down = _tigetstr("cud1")
        left = _tigetstr("cub1")
        right = _tigetstr("cuf1")
        // Deletion.
        clearScreen = _tigetstr("clear")
        clearEol = _tigetstr("el")
        clearBol = _tigetstr("el1")
        clearEos = _tigetstr("ed")

        bold = _tigetstr("bold")
        normal = _tigetstr("sgr0")

        let ESC = "\u{001B}"
        let CSI = "\(ESC)["
        green = "\(CSI)34m"
    }

    deinit {
        delscreen(screen)
        endwin()
    }
}

final class ProgressBar {

    let header: String
    let width: Int
    let term: TerminalController

    let xnl: String
    let bol: String

    var isClear: Bool // true if haven't drawn anything yet.

    init(term: TerminalController = TerminalController(), header: String) {
        if term.clearEol.isEmpty && term.up.isEmpty && term.bol.isEmpty {
            fatalError("Throw instead, incapable terminal")
        }
        self.term = term
        self.header = header

        var bol = self.term.bol
        var xnl = "\n"
        if let width = self.term.width {
            self.width = width
            if !self.term.xn {
                bol = self.term.up + self.term.bol
                xnl = ""
            }
        } else {
            self.width = 75
        }

        self.bol = bol
        self.xnl = xnl

        self.isClear = true
        self.update(percent: 0, text: "")
    }

    func update(percent: Int, text: String) {
        if isClear {
            print(header)
            print()
            isClear = false
        }

        let prefix = String(percent) + "% " + term.green + "[" + term.bold
        let suffix = term.normal + term.green + "]" + term.normal

        let barWidth = self.width - prefix.characters.count - suffix.characters.count - 6

        let n = Int(Double(barWidth) * Double(percent)/100.0)

        let textToWrite = self.bol + self.term.up + self.term.clearEol +
                        prefix + "=".repeating(n: n) + "-".repeating(n: barWidth - n) + suffix +
                        self.xnl + self.bol +
                        self.term.clearEol +
                        text
        print(textToWrite, terminator: "")

        if !self.term.xn {
            fflush(stdout)
        }
    }
}

extension String {
    func repeating(n: Int) -> String {
        var str = ""
        for _ in 0..<n {
            str = str + self
        }
        return str
    }
}

let progressBar = ProgressBar(header: "Tests")
for i in 0...100 {
    progressBar.update(percent: i, text: "\(i) Testing")
    Thread.sleep(forTimeInterval: 0.5)
}
