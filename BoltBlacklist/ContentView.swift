import SwiftUI
import Vision
import PhotosUI
import UIKit

struct ContentView: View {

    @State private var image: UIImage?
    @State private var showPicker = false
    @State private var ocrText = ""
    @State private var fileName =
        UserDefaults.standard.string(forKey: "file_name") ?? "ocr_results.txt"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            }

            OverlayViewRepresentable(ocrText: $ocrText)

            VStack {
                Spacer()
                HStack(spacing: 12) {

                    Button("File Name") {
                        changeFileName()
                    }

                    Button("Add Picture") {
                        showPicker = true
                    }

                    Button("Run OCR") {
                        runOCR()
                    }
                }
                .padding()
                .background(Color.black.opacity(0.6))
            }
        }
        .sheet(isPresented: $showPicker) {
            PhotoPicker(image: $image)
        }
    }

    // MARK: OCR
    func runOCR() {
        guard let img = image,
              let cg = img.cgImage else { return }

        let request = VNRecognizeTextRequest { req, _ in
            let text = (req.results as? [VNRecognizedTextObservation])?
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ") ?? ""

            DispatchQueue.main.async {
                self.ocrText = text.uppercased()
                saveKey(text)
            }
        }

        request.recognitionLevel = .accurate

        DispatchQueue.global(qos: .userInitiated).async {
            try? VNImageRequestHandler(cgImage: cg).perform([request])
        }
    }

    // MARK: File handling
    func fileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory,
                                 in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    func saveKey(_ text: String) {
        let key = text.split(separator: "-").first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() ?? ""

        guard !key.isEmpty else { return }

        let url = fileURL()
        let existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""

        if !existing.contains(key) {
            let line = key + "\n"
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(line.data(using: .utf8)!)
                handle.closeFile()
            } else {
                try? line.write(to: url,
                                atomically: true,
                                encoding: .utf8)
            }
        }
    }

    // MARK: UI helpers
    func changeFileName() {
        let alert = UIAlertController(
            title: "File name",
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { $0.text = fileName }

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            if let name = alert.textFields?.first?.text, !name.isEmpty {
                fileName = name
                UserDefaults.standard.set(name, forKey: "file_name")
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        UIApplication.shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?
            .rootViewController?
            .present(alert, animated: true)
    }
}

