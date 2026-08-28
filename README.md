# BlockApps 📱

BlockApps es una aplicación de macOS diseñada para interactuar con la **Duplicación del iPhone** (iPhone Mirroring) introducida en macOS Sequoia. El objetivo de la aplicación es automatizar el proceso de configurar un código de "Tiempo en Pantalla" en un iPhone directamente desde la Mac.

La aplicación generará un código seguro de 4 dígitos, lo escribirá automáticamente en la pantalla del iPhone y lo guardará en un historial oculto durante un período de tiempo definido por ti (ej. 8 horas).

## Video Tutorial 📺

[![Tutorial Video](https://img.youtube.com/vi/3tXUCl5rpIA/0.jpg)](https://www.youtube.com/watch?v=3tXUCl5rpIA)

## ¿Cómo funciona la automatización? 🤖

Dado que la "Duplicación del iPhone" es una transmisión de video y macOS no detecta los botones nativos del sistema de iOS, **BlockApps utiliza eventos sintéticos de sistema** para funcionar:
- Usa `CGEvent` para simular teclear el código numérico en el teclado (este evento es capturado por la ventana de duplicación).
- Realiza cálculos de proporciones basados en el tamaño de la ventana activa en primer plano para hacer **clics precisos** con el ratón en los botones de "Cancelar" y "Omitir" dentro de la interfaz del iPhone.

## Ejecución y Desarrollo (Modo Xcode) 🛠️

El proyecto está creado utilizando el **Swift Package Manager**. Esto lo hace sumamente ligero y fácil de abrir:

1. Solo haz doble clic en el archivo `Package.swift` o abre la carpeta del proyecto en **Xcode**.
2. Xcode descargará y preparará el proyecto automáticamente.
3. Asegúrate de que el destino (target) arriba en la barra de herramientas sea `BlockApps (My Mac)`.
4. Presiona el botón de **Play** (`Cmd + R`) para compilar y ejecutar la aplicación.

> [!WARNING]
> **Permisos de Accesibilidad requeridos**
> La primera vez que la aplicación o Xcode intenten automatizar los clics del teclado o del ratón, macOS mostrará un aviso de seguridad.
> Para que funcione, ve a **Preferencias del Sistema -> Privacidad y Seguridad -> Accesibilidad** y asegúrate de habilitar el interruptor para Xcode (o para la terminal si corres un script).

## ¿Cómo usar la app? 📱

1. En tu iPhone duplicado, navega hasta la pantalla de "Configurar código de Tiempo en pantalla".
2. En **BlockApps**, elige cuánto tiempo quieres que el código generado permanezca oculto (ej. 8 horas o tiempo Personalizado).
3. Haz clic en **Iniciar configuración**.
4. ¡Rápido! Tienes unos segundos de cuenta regresiva. Haz clic en la ventana de **Duplicación del iPhone** para ponerla en primer plano.
5. Suelta el ratón y el teclado; BlockApps tecleará el código y hará clic en omitir para terminar la configuración.

Si notas que la aplicación hace los clics ligeramente por encima o por debajo de los botones de la interfaz, puedes ajustarlos:
1. Abre la pestaña de **Configuración Avanzada (Coordenadas)** en la app.
2. Cada paso del proceso (Botón Cancelar, Omitir, Límites, etc.) tiene un control deslizable de `X` y `Y` de 0.0 (inicio) a 1.0 (final de la ventana).
3. Cada paso cuenta con una imagen de referencia. Puedes hacer clic en las imágenes para verlas en **pantalla completa** (y cerrarlas con otro clic).
4. El botón de **Probar** te permite lanzar una simulación instantánea del clic con los valores actuales, para que puedas calibrar cada coordenada visualmente sobre el iPhone duplicado sin necesidad de ejecutar toda la secuencia completa.

> [!WARNING]
> **Limitación en Xcode (Imágenes):** 
> Al ejecutar el proyecto directamente desde Xcode, es posible que las imágenes de referencia en la Configuración Avanzada no se muestren y aparezcan como "Sin imagen". Esto se debe a la resolución de rutas relativas durante la compilación en Xcode. **No te preocupes:** la aplicación es completamente funcional y, una vez que la empaquetes en el `.dmg`, las imágenes cargarán correctamente.

## Generar el archivo ejecutable Instalable (.dmg) 📦

Para exportar la aplicación lista para producción o para compartirla con alguien, el repositorio incluye un script llamado `build_dmg.sh`.

Este script se encarga de:
- Compilar la app usando `swift build -c release` para optimización.
- Empaquetar todo en una carpeta `.app` de Mac.
- Tomar tu archivo `Icon.png` y usar comandos del sistema para generar de forma dinámica y perfecta el archivo `AppIcon.icns`.
- Crear el instalador final de disco `BlockApps.dmg`.

### Pasos para generar el .dmg:
1. Abre tu **Terminal** y ve a la carpeta del proyecto.
2. Haz el script ejecutable (solo es necesario la primera vez):
   ```bash
   chmod +x build_dmg.sh
   ```
3. Ejecútalo:
   ```bash
   ./build_dmg.sh
   ```
4. Verás aparecer el archivo `BlockApps.dmg`. ¡Ábrelo, arrastra la app a Aplicaciones y listo!

> [!NOTE]
> Recuerda que al abrir la app final instalada desde el `.dmg`, deberás darle permisos de Accesibilidad específicamente a esa app.

## Solución de Problemas (Troubleshooting) 🛠️

### "La aplicación está dañada y no se puede abrir"
Dado que esta es una aplicación compilada localmente y no está firmada con un certificado de desarrollador de pago de Apple, macOS Gatekeeper podría ponerla en cuarentena por seguridad al intentar abrirla.

Si al instalarla en Aplicaciones y abrirla te aparece un mensaje de que la app está dañada, puedes quitar la cuarentena fácilmente:

1. Abre la **Terminal**.
2. Ejecuta el siguiente comando para limpiar los atributos extendidos:
   ```bash
   xattr -cr /Applications/BlockApps.app
   ```
3. Vuelve a intentar abrir la aplicación. Ahora debería ejecutarse sin problemas.

## Autor y Créditos
Creado por: **Angel Banderas**
