import SwiftUI

struct SettingsView: View {
    @ObservedObject var automationManager: AutomationManager
    @Environment(\.dismiss) var dismiss
    @State private var fullScreenImage: NSImage? = nil
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Configuración de Coordenadas")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                .padding()
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Group {
                            CoordinateSettingRow(
                                title: "Botón Cancelar",
                                xValue: $automationManager.cancelXRatio,
                                yValue: $automationManager.cancelYRatio,
                                imageName: "cancelar.png",
                                fullScreenImage: $fullScreenImage,
                                onTest: { automationManager.testClick(xRatio: automationManager.cancelXRatio, yRatio: automationManager.cancelYRatio) }
                            )
                            
                            CoordinateSettingRow(
                                title: "Botón Omitir",
                                xValue: $automationManager.skipXRatio,
                                yValue: $automationManager.skipYRatio,
                                imageName: "omitir.png",
                                fullScreenImage: $fullScreenImage,
                                onTest: { automationManager.testClick(xRatio: automationManager.skipXRatio, yRatio: automationManager.skipYRatio) }
                            )
                            
                            CoordinateSettingRow(
                                title: "Scroll Arriba (Hora)",
                                xValue: $automationManager.statusBarXRatio,
                                yValue: $automationManager.statusBarYRatio,
                                imageName: "scroll.png",
                                fullScreenImage: $fullScreenImage,
                                onTest: { automationManager.testClick(xRatio: automationManager.statusBarXRatio, yRatio: automationManager.statusBarYRatio) }
                            )
                            
                            CoordinateSettingRow(
                                title: "Menú 'Límites para apps'",
                                xValue: .constant(0.5), // Fijo al centro
                                yValue: $automationManager.limitsMenuYRatio,
                                imageName: "limites.png",
                                showXSlider: false,
                                fullScreenImage: $fullScreenImage,
                                onTest: { automationManager.testClick(xRatio: 0.5, yRatio: automationManager.limitsMenuYRatio) }
                            )
                            
                            CoordinateSettingRow(
                                title: "Primer ítem de la lista",
                                xValue: .constant(0.5),
                                yValue: $automationManager.firstListItemYRatio,
                                imageName: "primer-item.png",
                                showXSlider: false,
                                fullScreenImage: $fullScreenImage,
                                onTest: { automationManager.testClick(xRatio: 0.5, yRatio: automationManager.firstListItemYRatio) }
                            )
                            
                            CoordinateSettingRow(
                                title: "Switch 'Bloquear al terminar'",
                                xValue: .constant(0.85),
                                yValue: $automationManager.blockToggleYRatio,
                                imageName: "bloquear.png",
                                showXSlider: false,
                                fullScreenImage: $fullScreenImage,
                                onTest: { automationManager.testClick(xRatio: 0.85, yRatio: automationManager.blockToggleYRatio) }
                            )
                            
                            CoordinateSettingRow(
                                title: "Botón '< Regresar'",
                                xValue: $automationManager.backButtonXRatio,
                                yValue: $automationManager.backButtonYRatio,
                                imageName: "regresar.png",
                                fullScreenImage: $fullScreenImage,
                                onTest: { automationManager.testClick(xRatio: automationManager.backButtonXRatio, yRatio: automationManager.backButtonYRatio) }
                            )
                        }
                    }
                    .padding()
                }
            }
            
            // Overlay de imagen en pantalla completa
            if let fsImage = fullScreenImage {
                ZStack {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation { fullScreenImage = nil }
                        }
                    
                    Image(nsImage: fsImage)
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .onTapGesture {
                            withAnimation { fullScreenImage = nil }
                        }
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation { fullScreenImage = nil }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                }
                .zIndex(100)
            }
        }
        .frame(minWidth: 600, minHeight: 600)
    }
}

struct CoordinateSettingRow: View {
    let title: String
    @Binding var xValue: Double
    @Binding var yValue: Double
    let imageName: String
    var showXSlider: Bool = true
    @Binding var fullScreenImage: NSImage?
    let onTest: () -> Void
    
    // Función para cargar la imagen (intenta en Bundle o en ruta relativa)
    private var loadedImage: NSImage? {
        // 1. App Bundle (cuando se ejecuta desde el .app)
        if let path = Bundle.main.path(forResource: imageName, ofType: nil), let img = NSImage(contentsOfFile: path) {
            return img
        }
        
        // 2. Directorio actual (pwd)
        let pwdPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Assets")
            .appendingPathComponent(imageName).path
        if let img = NSImage(contentsOfFile: pwdPath) {
            return img
        }
        
        // 3. Relativo al código fuente (útil para Xcode / SwiftPM local)
        let sourceURL = URL(fileURLWithPath: #file)
        let projectRoot = sourceURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let sourceAssetPath = projectRoot.appendingPathComponent("Assets").appendingPathComponent(imageName).path
        if let img = NSImage(contentsOfFile: sourceAssetPath) {
            return img
        }
        
        return nil
    }
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline)
                
                if showXSlider {
                    HStack {
                        Text("X:")
                            .frame(width: 20, alignment: .leading)
                        Slider(value: $xValue, in: 0...1)
                        Text(String(format: "%.2f", xValue))
                            .frame(width: 40)
                    }
                }
                
                HStack {
                    Text("Y:")
                        .frame(width: 20, alignment: .leading)
                    Slider(value: $yValue, in: 0...1)
                    Text(String(format: "%.2f", yValue))
                        .frame(width: 40)
                }
                
                Button("Probar") {
                    onTest()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            
            // Imagen asociada
            Group {
                if let nsImage = loadedImage {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipped()
                        .cornerRadius(8)
                        .border(Color.secondary, width: 1)
                        .onTapGesture {
                            withAnimation {
                                fullScreenImage = nsImage
                            }
                        }
                        .overlay(
                            Image(systemName: "magnifyingglass.circle.fill")
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .padding(5),
                            alignment: .bottomTrailing
                        )
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 150, height: 150)
                        .overlay(Text("Sin imagen").foregroundColor(.secondary))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}
