import Foundation

enum Glyphs {
    static let alphabet: [Character] = Array(
        "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜｦﾝ" +
        "0123456789" +
        "ABCDEFGHJKLMNPQRSTUVWXYZ" +
        "@#$%&*+=-/<>?:"
    )

    static func random() -> String {
        String(alphabet.randomElement()!)
    }
}
