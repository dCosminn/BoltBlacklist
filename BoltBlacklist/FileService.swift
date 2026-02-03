import Foundation

class FileService {
    static let shared = FileService()
    
    private var fileName: String {
        UserDefaults.standard.string(forKey: "ocr_file_name") ?? "ocr_results.txt"
    }
    
    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(fileName)
    }
    
    func setFileName(_ name: String) {
        UserDefaults.standard.set(name, forKey: "ocr_file_name")
    }
    
    func getFileName() -> String {
        fileName
    }
    
    func appendLine(_ line: String) {
        let content = "\(line)\n"
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                handle.seekToEndOfFile()
                if let data = content.data(using: .utf8) {
                    handle.write(data)
                }
                handle.closeFile()
            }
        } else {
            try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
    
    func getAllLines() -> [String] {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return []
        }
        return content.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
    
    func findDuplicate(for key: String) -> String? {
        getAllLines().first { line in
            line.components(separatedBy: "-").first?.trimmingCharacters(in: .whitespaces).uppercased() == key
        }
    }
}
