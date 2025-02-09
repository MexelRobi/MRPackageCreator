import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State var packageName: String = ""
    @State private var installLocation: String = "/Applications"
    @State private var licensePath: String = ""
    @State private var appPath: String = ""
    @State private var outputPath: String = ""
    @State private var selectedCertificate: String = ""
    @State private var availableCertificates: [String] = []
    @State private var licenseFileName: String = ""
    @State private var showFilePicker = false
    @State private var showLicensePicker = false
    @State private var showAppPicker = false
    @State private var showOutputPicker = false
    
    var body: some View {
        VStack {
            Text("MRPackageCreator")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.accentColor)
                .padding(.bottom, 20)
            
            TextField("Package Name", text: $packageName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .background(Color(NSColor.secondarySystemFill))
                .cornerRadius(8)
                .padding(.horizontal)
            
            fileSelectionView(title: "App to Package", path: $appPath, showPicker: $showAppPicker)
                
            fileSelectionView(title: "License File", path: $licensePath, showPicker: $showLicensePicker)
                
            fileSelectionView(title: "Output Path", path: $outputPath, showPicker: $showOutputPicker)
                
            
            Picker("Select Signing Certificate", selection: $selectedCertificate) {
                ForEach(availableCertificates, id: \.self) { certificate in
                    Text(certificate)
                }
            }
            .padding(.all, 8)
            .background(Color(NSColor.secondarySystemFill))
            .cornerRadius(8)
            .padding(.horizontal)
            .onAppear(perform: fetchAvailableCertificates)
            
            Spacer()
            
            Button("Create .pkg", action: checkAndInstallCommandLineTools)
                .frame(maxWidth: .infinity, minHeight: 50) // Macht ihn breit und hoch genug
                .padding(.horizontal) // Fügt einen Rand hinzu
                .disabled(packageName.isEmpty || outputPath.isEmpty || appPath.isEmpty || selectedCertificate.isEmpty)
                .buttonStyle(.borderedProminent) // macOS-Stil mit 3D-Effekt
                .controlSize(.extraLarge)
        }
        .padding()
        .fileImporter(isPresented: $showLicensePicker, allowedContentTypes: [UTType.text, UTType.pdf, UTType.rtf]) { handleFileSelection($0, for: &licensePath) }
        VStack {}
        .fileImporter(isPresented: $showAppPicker, allowedContentTypes: [UTType.application]) { handleFileSelection($0, for: &appPath) }
        VStack {}
        .fileImporter(isPresented: $showOutputPicker, allowedContentTypes: [.folder]) { handleFileSelection($0, for: &outputPath) }
    }
    
    private func fileSelectionView(title: String, path: Binding<String>, showPicker: Binding<Bool>) -> some View {
        HStack {
            Text("\(title):")
                .font(.body)
            Spacer()
            Text(path.wrappedValue.isEmpty ? "None selected" : path.wrappedValue)
                .foregroundColor(path.wrappedValue.isEmpty ? .gray : .primary)
                .font(.body)
                .lineLimit(1)
            Button("Choose") { showPicker.wrappedValue = true }
                .font(.body)
                .foregroundColor(.blue)
                .padding()
                Button(action: {
                path.wrappedValue = ""
            }) {
                Image(systemName: "xmark.circle.fill")
            }
            .padding()
            .buttonBorderShape(.circle)
            .buttonStyle(.borderedProminent)
        }
        .padding(.all, 8)
        .background(Color(NSColor.secondarySystemFill))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func handleFileSelection(_ result: Result<URL, Error>, for path: inout String) {
        switch result {
        case .success(let url):
            path = url.path
            if url.lastPathComponent.hasSuffix(".txt") || url.lastPathComponent.hasSuffix(".pdf") || url.lastPathComponent.hasSuffix(".rtf") {
                licenseFileName = url.lastPathComponent
            }
        case .failure(let error):
            print("Error selecting file: \(error.localizedDescription)")
        }
    }
    
    private func fetchAvailableCertificates() {
        let command = "security find-identity -v -p basic"
        let output = runShellCommand(command)
        availableCertificates = output.split(separator: "\n").compactMap { let components = $0.split(separator: "\"")
            return components.count > 1 && components[1].contains("Developer ID Installer") ? String(components[1]) : nil
        }
    }
    
    private func checkAndInstallCommandLineTools() {
        let output = runShellCommand("xcode-select -p")
        if output.contains("error") || output.isEmpty {
            DispatchQueue.global(qos: .background).async {
                runShellCommand("xcode-select --install")
            }
        } else {
            createPackage()
        }
    }
    
    private func createPackage() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(packageName)
        let pkgPath = "\(outputPath)/\(packageName).pkg"
        let finalPkgPath = "\(outputPath)/\(packageName).pkg"
        let distributionPath = "\(outputPath)/Distribution.xml"
        let appName = URL(fileURLWithPath: appPath).lastPathComponent
        print("Package Name: \(packageName)")
            print("App Path: \(appPath)")
            print("License Path: \(licensePath)")
            print("Output Path: \(outputPath)")
           print("Selected Certificate: \(selectedCertificate)")
        print("Distribution XML Path: \(distributionPath)")
        
        do {
            
            
            let distributionXML = createDistributionXML(packageName: packageName, licenseFileName: licenseFileName, pkgPath: pkgPath)
            try distributionXML.write(toFile: distributionPath, atomically: true, encoding: .utf8)
            var signCommand = ""
                        if !selectedCertificate.isEmpty {
                            signCommand = "--sign \"\(selectedCertificate)\""
                        }
            
            if FileManager.default.fileExists(atPath: licensePath) {
                let finalCommand = """
mkdir -p ~/Desktop/pkg_build/root/
cp -R "\(appPath)" ~/Desktop/pkg_build/root/\(appName)
pkgbuild --root ~/Desktop/pkg_build/root \
         --identifier com.mrpkg.\(packageName) \
         --version 1.0 \
         --install-location /Applications \
         --ownership recommended \
         ~/Desktop/pkg_build/\(packageName).pkg
mkdir -p ~/Desktop/pkg_build/resources
cp -R "\(licensePath)" ~/Desktop/pkg_build/resources/\(licenseFileName)
cp -R \(distributionPath) ~/Desktop/pkg_build/Distribution.xml
productbuild --distribution ~/Desktop/pkg_build/Distribution.xml \
             --package-path ~/Desktop/pkg_build/ \
             --resources \(outputPath) \
            \(signCommand) \
             ~/Desktop/\(packageName)_Installer.pkg
            rm -rf ~/Desktop/pkg_build
            rm -rf ~/Desktop/Distribution.xml
"""

                Globals.finalOutput = runShellCommand(finalCommand)
                print("productbuild output: \(Globals.finalOutput)")
            } else {
                let finalCommand = """
mkdir -p ~/Desktop/pkg_build/root/
cp -R "\(appPath)" ~/Desktop/pkg_build/root/\(appName)
pkgbuild --root ~/Desktop/pkg_build/root \
         --identifier com.mrpkg.\(packageName) \
         --version 1.0 \
         --install-location /Applications \
         --ownership recommended \
         ~/Desktop/pkg_build/\(packageName).pkg
mkdir -p ~/Desktop/pkg_build/resources
cp -R \(distributionPath) ~/Desktop/pkg_build/Distribution.xml
productbuild --distribution ~/Desktop/pkg_build/Distribution.xml \
             --package-path ~/Desktop/pkg_build/ \
             --resources \(outputPath) \
            \(signCommand) \
             ~/Desktop/\(packageName)_Installer.pkg
            rm -rf ~/Desktop/pkg_build
            rm -rf ~/Desktop/Distribution.xml
"""

                let finalOutput = runShellCommand(finalCommand)
                print("productbuild output: \(finalOutput)")
            }
            
            
            
                
                
                
            
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
        
    private func createDistributionXML(packageName: String, licenseFileName: String, pkgPath: String) -> String {
        let appName = URL(fileURLWithPath: appPath).lastPathComponent
        
        if FileManager.default.fileExists(atPath: licensePath) {
            return """
            <?xml version="1.0" encoding="utf-8"?>
            <installer-gui-script minSpecVersion="1">
                <title>\(packageName) Installer</title>
                <license file="\(licenseFileName)"/>
                <pkg-ref id="com.mrpkg.\(packageName)"/>
                <options customize="never" require-scripts="false"/>
                <choices-outline>
                    <line choice="default">
                        <pkg-ref id="com.mrpkg.\(appName)"/>
                    </line>
                </choices-outline>
                <choice id="default" title="\(packageName)">
                    <pkg-ref id="com.mrpkg.\(packageName)"/>
                </choice>
                <pkg-ref id="com.mrpkg.\(packageName)" installKBytes="50000" version="1.0">
                        \(packageName).pkg
                </pkg-ref>
            </installer-gui-script>
            """
        } else {
            return """
            <?xml version="1.0" encoding="utf-8"?>
            <installer-gui-script minSpecVersion="1">
                <title>\(packageName) Installer</title>
                <pkg-ref id="com.mrpkg.\(packageName)"/>
                <options customize="never" require-scripts="false"/>
                <choices-outline>
                    <line choice="default">
                        <pkg-ref id="com.mrpkg.\(appName)"/>
                    </line>
                </choices-outline>
                <choice id="default" title="\(packageName)">
                    <pkg-ref id="com.mrpkg.\(packageName)"/>
                </choice>
                <pkg-ref id="com.mrpkg.\(packageName)" installKBytes="50000" version="1.0">
                        \(packageName).pkg
                </pkg-ref>
            </installer-gui-script>
            """
        }
        
    }
    
    private func runShellCommand(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}


