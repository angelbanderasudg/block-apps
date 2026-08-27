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
        // 1. Escribir el código la primera vez
        self.typeString(code)
        
        // 2. Esperar (ej. 1 segundo)
        try? await Task.sleep(nanoseconds: UInt64(self.delayBetweenTyping * 1_000_000_000))
        
        // 3. Escribir el código la segunda vez
        self.typeString(code)
        
        // 4. Esperar (ej. 3 segundos) a que aparezca la recuperación de cuenta Apple
        try? await Task.sleep(nanoseconds: UInt64(self.delayBeforeCancel * 1_000_000_000))
        
        // 5. Clic en "Cancelar"
        let cancelSuccess = self.clickRelative(xRatio: self.cancelXRatio, yRatio: self.cancelYRatio)
        if !cancelSuccess { return false }
        
        // 6. Esperar (ej. 1 segundo) a que aparezca la alerta "¿Quieres continuar?"
        try? await Task.sleep(nanoseconds: UInt64(self.delayBeforeSkip * 1_000_000_000))
        
        // 7. Clic en "Omitir"
        let skipSuccess = self.clickRelative(xRatio: self.skipXRatio, yRatio: self.skipYRatio)
        if !skipSuccess { return false }
        
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
    
    private func clickRelative(xRatio: Double, yRatio: Double) -> Bool {
        guard let windowFrame = getFrontmostWindowFrame() else {
            DispatchQueue.main.async {
                self.statusMessage = "Error: No se pudo obtener la ventana activa."
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
    
    private func getFrontmostWindowFrame() -> CGRect? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
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
