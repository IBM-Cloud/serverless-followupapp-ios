import Foundation

internal class RefreshTokenImpl: RefreshToken {
    private var rawData = ""

    var raw: String? {
        return rawData
    }

    internal init? (with raw: String) {
        self.rawData = raw
    }

}
