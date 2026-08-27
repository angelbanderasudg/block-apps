#!/bin/bash

# Exit on error
set -e

APP_NAME="BlockApps"
APP_DIR="${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"

echo "🔨 Construyendo el proyecto en modo release..."
swift build -c release

echo "📦 Creando el bundle de la aplicación (.app)..."
# Limpiar build anterior si existe
rm -rf "$APP_DIR"

# Crear estructura de carpetas de macOS
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Generar el archivo .icns a partir de Icon.png
if [ -f "Icon.png" ]; then
    echo "🎨 Generando icono de la aplicación..."
    mkdir -p BlockApps.iconset
    sips -z 16 16     Icon.png --out BlockApps.iconset/icon_16x16.png > /dev/null
    sips -z 32 32     Icon.png --out BlockApps.iconset/icon_16x16@2x.png > /dev/null
    sips -z 32 32     Icon.png --out BlockApps.iconset/icon_32x32.png > /dev/null
    sips -z 64 64     Icon.png --out BlockApps.iconset/icon_32x32@2x.png > /dev/null
    sips -z 128 128   Icon.png --out BlockApps.iconset/icon_128x128.png > /dev/null
    sips -z 256 256   Icon.png --out BlockApps.iconset/icon_128x128@2x.png > /dev/null
    sips -z 256 256   Icon.png --out BlockApps.iconset/icon_256x256.png > /dev/null
    sips -z 512 512   Icon.png --out BlockApps.iconset/icon_256x256@2x.png > /dev/null
    sips -z 512 512   Icon.png --out BlockApps.iconset/icon_512x512.png > /dev/null
    sips -z 1024 1024 Icon.png --out BlockApps.iconset/icon_512x512@2x.png > /dev/null
    
    iconutil -c icns BlockApps.iconset -o "$APP_DIR/Contents/Resources/AppIcon.icns"
    rm -rf BlockApps.iconset
fi

# Copiar el ejecutable
cp .build/release/"$APP_NAME" "$APP_DIR/Contents/MacOS/"

# Crear Info.plist con metadata y referencia al icono
cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.angelbanderas.${APP_NAME}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHumanReadableCopyright</key>
    <string>Creado por Angel Banderas</string>
</dict>
</plist>
EOF

echo "💿 Creando imagen de disco (.dmg)..."
# Limpiar dmg anterior si existe
rm -f "$DMG_NAME"

# Crear directorio temporal (staging) para el DMG
DMG_STAGING="dmg_staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

# Mover la app al directorio temporal
mv "$APP_DIR" "$DMG_STAGING/"

# Crear el acceso directo a la carpeta Applications
ln -s /Applications "$DMG_STAGING/Applications"

# Crear el archivo DMG a partir de la carpeta temporal
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_NAME"

# Limpiar el directorio temporal
rm -rf "$DMG_STAGING"

echo "✅ Proceso completado. El archivo $DMG_NAME está listo en tu directorio."
