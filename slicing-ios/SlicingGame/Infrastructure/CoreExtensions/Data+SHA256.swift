//
//  Data+SHA256.swift
//  Core extension: extends data to calculate an SHA256 hash
//

import Foundation
import CommonCrypto

extension Data {
    
    func sha256() -> String {
        // Generate hash
        let hash = self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.baseAddress, CC_LONG(self.count), &hash)
            return hash
        }

        // Return SHA256 hash string formatted as hexadecimal
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }
    
}
