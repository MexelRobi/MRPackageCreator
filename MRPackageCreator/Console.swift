import SwiftUI
import os.log



struct DebugConsoleView: View {
    
    @State var finalOutput = Globals.finalOutput
    
    var body: some View {
        VStack {
            Text("System Console")
                .font(.headline)
            ScrollView {
                Text(finalOutput)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .onAppear() {
                        DispatchQueue.global(qos: .background).async {
                                while true {
                                    DispatchQueue.main.async {
                                        finalOutput = Globals.finalOutput
                                    }
                                    Thread.sleep(forTimeInterval: 1.0) // Wartezeit
                                }
                            }
                    }
                    
            }
            .background(Color.black.opacity(0.1))
            .cornerRadius(8)
            

            
        }
        .padding()
        
        
    }
    
}
