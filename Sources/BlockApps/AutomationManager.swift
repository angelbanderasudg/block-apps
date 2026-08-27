import Foundation
import AppKit
import ApplicationServices

@MainActor
class AutomationManager: ObservableObject {
    @Published var statusMessage: String = "Listo"
    @Published var countdown: Int = 0
    @Published var cancelXRatio: Double = 0.5
    @Published var cancelYRatio: Double = 0.9
    @Published var skipXRatio: Double = 0.5
    @Published var skipYRatio: Double = 0.6
    
    // Limits automation config
    @Published var numberOfLimits: Int = 1
    @Published var limitsMenuYRatio: Double = 0.75
    @Published var firstListItemYRatio: Double = 0.35
    @Published var listItemHeightRatio: Double = 0.08
    @Published var blockToggleYRatio: Double = 0.47
    @Published var backButtonXRatio: Double = 0.10
    @Published var backButtonYRatio: Double = 0.15
    @Published var statusBarXRatio: Double = 0.20
    @Published var statusBarYRatio: Double = 0.07
    
    // Configurable delays
    @Published var delayBeforeTyping: Double = 3.0
    @Published var delayBetweenTyping: Double = 1.0
    @Published var delayBeforeCancel: Double = 3.0
    @Published var delayBeforeSkip: Double = 2.0
    

    
    func startAutomation(code: String, onSuccess: @escaping () -> Void) {
        // Check for accessibility permissions and prompt if missing
        let options: NSDictionary = ["AXTrustedCheckOptionPrompt": true]
        if !AXIsProcessTrustedWithOptions(options) {
            statusMessage = "Error: Faltan permisos de Accesibilidad."
            return
        }
        
        if code.count != 4 {
            statusMessage = "Error: El código no tiene 4 dígitos."
            return
        }
        
        statusMessage = "Por favor, enfoca la ventana de Duplicación del iPhone."
        countdown = Int(delayBeforeTyping)
        
        Task { @MainActor in
            for i in stride(from: countdown, to: 1, by: -1) {
                self.countdown = i
                self.statusMessage = "Iniciando en \(i)..."
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            
            self.countdown = 0
            self.statusMessage = "Ejecutando automatización..."
            let success = await self.executeSequence(code: code)
            if success {
                onSuccess()
            }
        }
    }
    
    private func executeSequence(code: String) async -> Bool {
        // 0. Activar la app de Duplicación del iPhone
        guard let mirrorApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.ScreenContinuity" }) else {
            DispatchQueue.main.async {
                self.statusMessage = "Error: Duplicación del iPhone no está abierta."
            }
            return false
        }
        
        mirrorApp.activate(options: .activateIgnoringOtherApps)
        try? await Task.sleep(nanoseconds: 500_000_000) // Esperar medio segundo a que traiga la ventana al frente
        
        // --- Fase 1: Configurar código de tiempo en pantalla ---
        self.typeString(code)
        try? await Task.sleep(nanoseconds: UInt64(self.delayBetweenTyping * 1_000_000_000))
        self.typeString(code)
        
        try? await Task.sleep(nanoseconds: UInt64(self.delayBeforeCancel * 1_000_000_000))
        let cancelSuccess = self.clickRelative(xRatio: self.cancelXRatio, yRatio: self.cancelYRatio)
        if !cancelSuccess { return false }
        
        try? await Task.sleep(nanoseconds: UInt64(self.delayBeforeSkip * 1_000_000_000))
        let skipSuccess = self.clickRelative(xRatio: self.skipXRatio, yRatio: self.skipYRatio)
        if !skipSuccess { return false }
        
        // Si no hay límites configurados, terminar aquí
        if self.numberOfLimits == 0 {
            self.statusMessage = "¡Automatización completada (Sin límites)!"
            return true
        }
        
        // --- Fase 2: Bloquear límites de apps ---
        self.statusMessage = "Fase 2: Bloqueando límites..."
        try? await Task.sleep(nanoseconds: 2_000_000_000) // Esperar regreso al menú
        
        // Clic en la barra superior para Scroll Up
        _ = self.clickRelative(xRatio: self.statusBarXRatio, yRatio: self.statusBarYRatio)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Clic en "Límites para apps"
        _ = self.clickRelative(xRatio: 0.5, yRatio: self.limitsMenuYRatio)
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        for i in 0..<self.numberOfLimits {
            let itemY = self.firstListItemYRatio + (Double(i) * self.listItemHeightRatio)
            
            // Clic en el elemento de la lista
            _ = self.clickRelative(xRatio: 0.5, yRatio: itemY)
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            // El primero pide el código
            if i == 0 {
                self.typeString(code)
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }
            
            // Clic en "Bloquear al terminar límite"
            _ = self.clickRelative(xRatio: 0.85, yRatio: self.blockToggleYRatio)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Clic en "< Regresar"
            _ = self.clickRelative(xRatio: self.backButtonXRatio, yRatio: self.backButtonYRatio)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        // Salir del menú de límites
        _ = self.clickRelative(xRatio: self.backButtonXRatio, yRatio: self.backButtonYRatio)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Tercer click en regresar (para salir completamente al menú inicial)
        _ = self.clickRelative(xRatio: self.backButtonXRatio, yRatio: self.backButtonYRatio)
        
        self.statusMessage = "¡Automatización completada!"
        return true
    }
    
    private func typeString(_ string: String) {
        for char in string {
            if let key = keycodeForChar(char) {
                let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: true)
                let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: false)
                keyDown?.post(tap: .cghidEventTap)
                keyUp?.post(tap: .cghidEventTap)
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
    }
    
    private func keycodeForChar(_ char: Character) -> CGKeyCode? {
        // Códigos ANSI estándar para números
        switch char {
        case "0": return 29
        case "1": return 18
        case "2": return 19
        case "3": return 20
        case "4": return 21
        case "5": return 23
        case "6": return 22
        case "7": return 26
        case "8": return 28
        case "9": return 25
        default: return nil
        }
    }
    
    func testClick(xRatio: Double, yRatio: Double) {
        guard let mirrorApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.ScreenContinuity" }) else {
            self.statusMessage = "Error: Duplicación del iPhone no está abierta."
            return
        }
        
        mirrorApp.activate(options: .activateIgnoringOtherApps)
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            let success = self.clickRelative(xRatio: xRatio, yRatio: yRatio)
            self.statusMessage = success ? "Clic de prueba exitoso" : "Error en el clic de prueba"
        }
    }
    
    private func clickRelative(xRatio: Double, yRatio: Double) -> Bool {
        guard let windowFrame = getMirroringWindowFrame() else {
            DispatchQueue.main.async {
                self.statusMessage = "Error: No se pudo obtener la ventana de Duplicación."
            }
            return false
        }
        
        let targetX = windowFrame.origin.x + (windowFrame.size.width * CGFloat(xRatio))
        let targetY = windowFrame.origin.y + (windowFrame.size.height * CGFloat(yRatio))
        let targetPoint = CGPoint(x: targetX, y: targetY)
        
        let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: targetPoint, mouseButton: .left)
        let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: targetPoint, mouseButton: .left)
        
        mouseDown?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.1)
        mouseUp?.post(tap: .cghidEventTap)
        return true
    }
    
    private func getMirroringWindowFrame() -> CGRect? {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.ScreenContinuity" }) else {
            return nil
        }
        let pid = app.processIdentifier
        
        // Método 1: CGWindowList (Más confiable si Accessibility API falla por estructura rara)
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        if let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
            for info in windowListInfo {
                if let windowPid = info[kCGWindowOwnerPID as String] as? Int32, windowPid == pid {
                    // Validar que la ventana esté en la capa normal (0)
                    if let layer = info[kCGWindowLayer as String] as? Int, layer == 0 {
                        if let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                           let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) {
                            return bounds
                        }
                    }
                }
            }
        }
        
        // Método 2: API de Accesibilidad como respaldo
        let axApp = AXUIElementCreateApplication(pid)
        
        var axWindow: CFTypeRef?
        if AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &axWindow) == .success,
           let window = axWindow {
            if let frame = getFrame(for: window as! AXUIElement) {
                return frame
            }
        }
        
        var axWindows: CFTypeRef?
        if AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &axWindows) == .success,
           let windowsArray = axWindows as? [AXUIElement], !windowsArray.isEmpty {
            for win in windowsArray {
                if let frame = getFrame(for: win) {
                    return frame
                }
            }
        }
        
        return nil
    }
    
    private func getFrame(for axWindow: AXUIElement) -> CGRect? {
        var position: CFTypeRef?
        var size: CFTypeRef?
        
        AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &position)
        AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &size)
        
        var pt = CGPoint.zero
        var sz = CGSize.zero
        
        if let p = position, let s = size {
            AXValueGetValue(p as! AXValue, .cgPoint, &pt)
            AXValueGetValue(s as! AXValue, .cgSize, &sz)
            return CGRect(origin: pt, size: sz)
        }
        
        return nil
    }
}
