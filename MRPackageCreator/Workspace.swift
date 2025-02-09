import SwiftUI

class ConsoleWindowManager {
    static let shared = ConsoleWindowManager()
    private var consoleWindow: NSWindow?

    private init() {}

    func showConsole() {
        if consoleWindow == nil {
            let newWindow = NSWindow(
                contentRect: NSMakeRect(0, 0, 400, 300),
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            )
            newWindow.title = "Console"
            newWindow.center()

            let hostingController = NSHostingController(rootView: DebugConsoleView())
            newWindow.contentView = hostingController.view
            newWindow.makeKeyAndOrderFront(nil)
            
            self.consoleWindow = newWindow
            
            // Event Listener: Falls das Fenster geschlossen wird, referenz löschen
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: newWindow, queue: nil) { _ in
                self.consoleWindow = nil
            }
        } else {
            consoleWindow?.makeKeyAndOrderFront(nil)
        }
    }
}

struct Workspace: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: ContentView()) {
                    Label("Project", systemImage: "folder")
                }
                Button(action: {
                    ConsoleWindowManager.shared.showConsole()
                }) {
                    Label("Console", systemImage: "terminal")
                }
                .buttonStyle(.plain)
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Sidebar")
            Text("Select an option")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    Workspace()
}
