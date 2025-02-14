import SwiftUI




struct Workspace: View {
    @State var showconsoleWindow = false
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: ContentView()) {
                    Label("Project", systemImage: "folder")
                }
                Button(action: {
                    showconsoleWindow = true
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
        .sheet(isPresented: $showconsoleWindow) {
            HStack {
                Spacer()
                Button {
                    showconsoleWindow = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.red)
                }
                .buttonBorderShape(.circle)
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .padding()
            }
            DebugConsoleView()
                .frame(width: 500, height: 300)
        }
        
    }
}

#Preview {
    Workspace()
}
