import SwiftUI

enum DurationOption: Hashable, Equatable {
    case preset(Double)
    case custom
}

struct ContentView: View {
    @StateObject private var codeManager = CodeManager()
    @StateObject private var automationManager = AutomationManager()
    @State private var showingSettings = false
    @State private var showingHistory = false
    
    @State private var selectedOption: DurationOption = .preset(8.0)
    let presetOptions: [Double] = [2, 4, 8, 12, 24, 48, 72]
    
    @AppStorage("savedNumberOfLimits") private var savedNumberOfLimits: Int = 1
    @AppStorage("savedPresetHours") private var savedPresetHours: Double = 8.0
    @AppStorage("savedIsCustom") private var savedIsCustom: Bool = false
    @AppStorage("customHours") private var customHours: Int = 1
    @AppStorage("customMinutes") private var customMinutes: Int = 30
    
    @State private var currentDate = Date()
    @State private var isCodeRevealed = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var hasAccessibilityPermission: Bool = AXIsProcessTrusted()
    let accessibilityTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if !hasAccessibilityPermission {
            VStack(spacing: 20) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                Text("Se requiere Accesibilidad")
                    .font(.title)
                    .bold()
                Text("BlockApps necesita controlar el ratón para configurar los límites en la Duplicación del iPhone.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Otorgar Permiso") {
                    let options: NSDictionary = ["AXTrustedCheckOptionPrompt": true]
                    AXIsProcessTrustedWithOptions(options)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .frame(minWidth: 400, minHeight: 520)
            .onReceive(accessibilityTimer) { _ in
                hasAccessibilityPermission = AXIsProcessTrusted()
            }
        } else {
            VStack(spacing: 20) {
                Text("BlockApps")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            
            if let revealDate = codeManager.currentRevealDate {
                if currentDate < revealDate {
                    // Temporizador activo
                    VStack(spacing: 5) {
                        Text("Código Oculto")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        Text(timerInterval: Date()...revealDate, countsDown: true)
                            .font(.system(.title2, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                    .padding()
                } else {
                    // El tiempo ya pasó, mostrar botón de revelado manual
                    VStack(spacing: 15) {
                        if isCodeRevealed {
                            Text(codeManager.currentCode)
                                .font(.system(size: 60, weight: .heavy, design: .monospaced))
                                .padding()
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(12)
                        } else {
                            Text("Código Oculto")
                                .font(.title)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        
                        Button(isCodeRevealed ? "Ocultar código" : "Mostrar código") {
                            isCodeRevealed.toggle()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isCodeRevealed ? .secondary : .blue)
                    }
                }
            } else {
                // Ningún código generado
                Text("----")
                    .font(.system(size: 60, weight: .heavy, design: .monospaced))
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(12)
            }
            
            if let date = codeManager.currentGeneratedDate {
                Text("Último Generado: \(date.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("Ver códigos previos") {
                showingHistory.toggle()
            }
            .buttonStyle(.bordered)
            .popover(isPresented: $showingHistory) {
                VStack {
                    Text("Historial de Códigos")
                        .font(.headline)
                        .padding()
                    
                    if codeManager.visibleHistory.isEmpty {
                        Text("No hay códigos previos disponibles.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        List(codeManager.visibleHistory) { entry in
                            HStack {
                                Text(entry.code)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(entry.date.formatted())
                                        .font(.caption)
                                    let hrs = Int(entry.lockDurationHours)
                                    let mins = Int((entry.lockDurationHours - Double(hrs)) * 60)
                                    if mins > 0 {
                                        Text("Retraso: \(hrs)h \(mins)m")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    } else {
                                        Text("Retraso: \(hrs)h")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    }
                                }
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(width: 300, height: 300)
            }
            
            Divider()
            
            Text(automationManager.statusMessage)
                .font(.headline)
                .foregroundColor(automationManager.countdown > 0 ? .orange : .primary)
            
            let isTimerActive = (codeManager.currentRevealDate != nil) && (Date() < codeManager.currentRevealDate!)
            
            if !isTimerActive {
                VStack {
                    HStack {
                        Text("Ocultar por:")
                        Picker("", selection: $selectedOption) {
                            ForEach(presetOptions, id: \.self) { hours in
                                Text("\(Int(hours))h").tag(DurationOption.preset(hours))
                            }
                            Text("Personalizado...").tag(DurationOption.custom)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                    
                    if selectedOption == .custom {
                        HStack {
                            Stepper(value: $customHours, in: 0...999) {
                                Text("\(customHours) h")
                            }
                            Stepper(value: $customMinutes, in: 0...59) {
                                Text("\(customMinutes) m")
                            }
                        }
                        .padding(.top, 5)
                    }
                }
                
                Stepper(value: $automationManager.numberOfLimits, in: 0...50) {
                    Text("Cantidad de límites a bloquear: \(automationManager.numberOfLimits)")
                }
                .padding(.bottom, 10)
                
                Button("Iniciar configuración") {
                    let finalDuration: Double
                    switch selectedOption {
                    case .preset(let hrs):
                        finalDuration = hrs
                    case .custom:
                        finalDuration = Double(customHours) + (Double(customMinutes) / 60.0)
                    }
                    
                    isCodeRevealed = false
                    
                    let newCode = codeManager.generateNewCodeString()
                    automationManager.startAutomation(code: newCode) {
                        codeManager.saveGeneratedCode(newCode, lockDurationHours: finalDuration)
                        isCodeRevealed = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(automationManager.countdown > 0)
                
                Button("Configuración Avanzada (Coordenadas)") {
                    showingSettings.toggle()
                }
                .font(.footnote)
                .padding(.top)
                .sheet(isPresented: $showingSettings) {
                    SettingsView(automationManager: automationManager)
                }
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 520)
        .onReceive(timer) { input in
            currentDate = input
        }
        .onAppear {
            automationManager.numberOfLimits = savedNumberOfLimits
            if savedIsCustom {
                selectedOption = .custom
            } else {
                selectedOption = .preset(savedPresetHours)
            }
        }
        .onChange(of: automationManager.numberOfLimits) { newValue in
            savedNumberOfLimits = newValue
        }
        .onChange(of: selectedOption) { newValue in
            switch newValue {
            case .preset(let hrs):
                savedIsCustom = false
                savedPresetHours = hrs
            case .custom:
                savedIsCustom = true
            }
        }
        }
    }
}
