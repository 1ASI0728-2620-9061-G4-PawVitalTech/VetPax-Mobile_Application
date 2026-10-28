# VetPax — Mobile Application

Aplicación móvil de **VetPax**, desarrollada con **Flutter y Dart** para propietarios de mascotas. Esta guía explica cómo instalar y ejecutar el proyecto en **Android desde Visual Studio Code**, usando los servicios locales de VetPax.

> **Alcance:** este README es solo para la aplicación móvil.

## 1. Requisitos previos

En Windows, instala:

- [Git](https://git-scm.com/downloads), para clonar el repositorio.
- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows/mobile), con Dart incluido. El proyecto requiere **Dart 3.12 o superior** (según `pubspec.yaml`).
- [Visual Studio Code](https://code.visualstudio.com/) con las extensiones **Flutter** y **Dart**.
- [Android Studio](https://developer.android.com/studio), para disponer del **Android SDK**, **Android SDK Platform-Tools** y un **emulador Android**; no es obligatorio usar Android Studio como editor.

Comprueba la instalación desde la terminal de VS Code:

```powershell
flutter --version
flutter doctor -v
```

Si Flutter indica que faltan licencias de Android:

```powershell
flutter doctor --android-licenses
```

Acepta las licencias y comprueba nuevamente con `flutter doctor -v`. La advertencia sobre **Visual Studio para aplicaciones Windows** no impide desarrollar la aplicación para Android.

## 2. Clonar el repositorio

Abre la terminal de VS Code (`Terminal > New Terminal`) y ejecuta:

```powershell
git clone https://github.com/1ASI0728-2620-9061-G4-PawVitalTech/VetPax-Mobile_Application.git
cd VetPax-Mobile_Application
code .
```

Si ya descargaste o clonaste el proyecto, abre directamente esa carpeta en VS Code. Todos los comandos siguientes se ejecutan **desde la carpeta donde está `pubspec.yaml`**.

## 3. Instalar dependencias Flutter

```powershell
flutter pub get
flutter analyze
```

Las dependencias de autenticación y almacenamiento ya están declaradas en `pubspec.yaml`; no necesitas agregarlas manualmente.

## 4. Iniciar un emulador o conectar un Android físico

### Opción A: Emulador Android desde VS Code

1. Abre la **paleta de comandos** con `Ctrl + Shift + P`.
2. Busca **`Flutter: Select Device`** o utiliza el selector de dispositivos de la barra inferior.
3. Selecciona un emulador Android y enciéndelo. También puedes iniciarlo con Android Studio → **Device Manager**.
4. Cuando Android termine de arrancar, verifica:

```powershell
flutter devices
```

Si deseas iniciarlo desde la terminal:

```powershell
flutter emulators
flutter emulators --launch ID_DEL_EMULADOR
```

Reemplaza `ID_DEL_EMULADOR` por uno de los identificadores mostrados. **`flutter run` solo puede ejecutar la app en un dispositivo Android cuando este ya se encuentra conectado o encendido.**

### Opción B: Celular Android por USB

Activa las **Opciones de desarrollador** y **Depuración por USB** en el celular, conéctalo y acepta la autorización del equipo. Comprueba:

```powershell
flutter devices
```

## 5. Conectar la app con los servicios locales

Antes de iniciar sesión o registrar cuentas, verifica que los servicios de VetPax ya estén disponibles **en la computadora**:

| Servicio necesario | Dirección local |
| --- | --- |
| API VetPax | `http://localhost:5139/api/v1` |
| Keycloak | `http://localhost:8080` |

> Estas son dependencias de la app; su instalación y puesta en marcha se documentan en el repositorio correspondiente al backend.

Con el emulador encendido o el celular conectado por USB, abre PowerShell y ejecuta:

```powershell
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" devices
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" reverse tcp:5139 tcp:5139
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" reverse tcp:8080 tcp:8080
```

Los comandos `adb reverse` permiten que **`localhost` dentro del dispositivo Android** apunte a los servicios que se ejecutan en tu computadora. Si `adb` ya está configurado en el `PATH`, también puedes escribir `adb reverse ...` directamente.

**Importante:** vuelve a ejecutar los dos comandos `adb reverse` después de reiniciar el emulador, desconectar el celular o reiniciar ADB. Si `adb devices` no muestra ningún dispositivo con estado `device`, primero resuelve la conexión del dispositivo.

## 6. Configuración de la aplicación

La configuración para desarrollo está en:

```text
lib/core/constants.dart
```

El proyecto ya utiliza estos valores por defecto:

| Configuración | Valor |
| --- | --- |
| URL de la API | `http://localhost:5139/api/v1` |
| URL de Keycloak | `http://localhost:8080` |
| Realm | `vetpax` |
| Cliente OAuth | `vetpax-dev` |
| URI de retorno | `com.vetpax.app:/oauthredirect` |

Si tu entorno local utiliza estos valores, **no hace falta editar el archivo**. La configuración también puede cambiarse al ejecutar Flutter con `--dart-define`.

Para que el inicio de sesión móvil funcione, el cliente `vetpax-dev` de Keycloak debe admitir la URI de retorno **`com.vetpax.app:/oauthredirect`** y usar el flujo de autorización con PKCE. En esta app la contraseña se introduce en la pantalla segura de Keycloak. Para probar las funcionalidades del propietario, utiliza una cuenta con el rol **`owner`**.

## 7. Ejecutar VetPax en Android

Con el dispositivo encendido, los servicios disponibles y `adb reverse` configurado:

```powershell
flutter run
```

Si tienes varios dispositivos, selecciona Android cuando aparezca la lista, o indícalo explícitamente:

```powershell
flutter devices
flutter run -d emulator-5554
```

Sustituye `emulator-5554` por el identificador real que muestre `flutter devices`.

En VS Code también puedes seleccionar el emulador y presionar **F5** para iniciar la depuración.

### Ejecución con URLs explícitas (opcional)

```powershell
flutter run --dart-define=VETPAX_API_URL=http://localhost:5139/api/v1 --dart-define=VETPAX_KEYCLOAK_URL=http://localhost:8080 --dart-define=VETPAX_KEYCLOAK_REALM=vetpax --dart-define=VETPAX_KEYCLOAK_CLIENT_ID=vetpax-dev
```

Durante la ejecución, presiona **`r`** en la terminal para *hot reload* y **`R`** para *hot restart*.

## 8. Validación rápida

Una vez iniciada la aplicación:

1. Comprueba que se abre la pantalla de bienvenida o inicio de sesión.
2. Prueba **registrar una cuenta nueva** desde la app.
3. Inicia sesión; debería abrirse el navegador de autenticación de Keycloak y después regresar a VetPax.
4. Verifica que se muestran las pantallas del propietario y que las solicitudes a la API responden.

> Esta configuración está preparada para **Android en desarrollo local**. Ejecutar `flutter run -d chrome` no equivale a probar la misma autenticación: el login implementado usa `flutter_appauth`, pensado para plataformas móviles, y la versión web requiere una integración OAuth específica.

## 9. Problemas frecuentes

| Problema | Qué revisar |
| --- | --- |
| `flutter run` solo muestra Chrome y Edge | Enciende el emulador o conecta el celular; después ejecuta `flutter devices`. |
| `adb` no se reconoce en PowerShell | Utiliza la ruta completa `& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"`. |
| La aplicación no conecta con `localhost` | Confirma que ambos servicios locales responden y vuelve a ejecutar los comandos `adb reverse`. |
| `HTTP 307` al registrar una cuenta | La API puede estar redirigiendo HTTP a HTTPS. Verifica que la URL HTTP de desarrollo no produzca esa redirección; el móvil no debe depender del certificado HTTPS de desarrollo de Windows. |
| `invalid_redirect_uri` en el login | Revisa que la URI `com.vetpax.app:/oauthredirect` esté autorizada para el cliente móvil de Keycloak. |
| `401 Unauthorized` | Comprueba que el inicio de sesión terminó correctamente y que el token/sesión siguen vigentes. |
| `403 Forbidden` | Verifica que el usuario tenga el rol `owner` y permiso sobre el recurso consultado. |
| `flutter pub get` falla | Confirma la versión de Flutter/Dart, conectividad y que `pubspec.yaml` no contenga dependencias duplicadas. |
| Advertencia sobre Kotlin Gradle Plugin | Es una advertencia de compatibilidad futura de algún plugin; por sí sola no indica que la compilación haya fallado. |

Si hay problemas con dependencias o archivos generados, puedes intentar:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter run
```

## 10. Comandos útiles

```powershell
flutter doctor -v       # Comprobar herramientas instaladas
flutter emulators       # Ver emuladores creados
flutter devices         # Ver dispositivos encendidos/conectados
flutter pub get         # Instalar dependencias
flutter analyze         # Analizar el código Dart
flutter test            # Ejecutar pruebas disponibles
flutter run             # Iniciar la app
```

---

**VetPax Mobile Application — Flutter/Dart · Entorno de desarrollo Android.**
