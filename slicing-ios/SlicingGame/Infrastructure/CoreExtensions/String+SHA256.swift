//
//  String+SHA256.swift
//  Core extension: extends string to calculate an SHA256 hash
//

extension String {
    
    func sha256() -> String {
        if let messageData = self.data(using: .utf8) {
            return messageData.sha256()
        }
        return "unavailable"
    }
    
}
