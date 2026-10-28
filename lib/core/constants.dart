// Configuración de desarrollo: sin secretos en el código.
// Use adb reverse tcp:8080 tcp:8080 y adb reverse tcp:5139 tcp:5139
// en Android (emulador o teléfono conectado por USB) para reutilizar
// Keycloak en Docker y la API que se ejecutan en el PC.
// En iOS Simulator, localhost se refiere al Mac anfitrión.
const String BASE_URL = String.fromEnvironment(
  'VETPAX_API_URL',
  defaultValue: 'http://localhost:5139/api/v1',
);
const String KEYCLOAK_URL = String.fromEnvironment(
  'VETPAX_KEYCLOAK_URL',
  defaultValue: 'http://localhost:8080',
);
const String KEYCLOAK_REALM = String.fromEnvironment(
  'VETPAX_KEYCLOAK_REALM', defaultValue: 'vetpax',
);
const String KEYCLOAK_CLIENT_ID = String.fromEnvironment(
  'VETPAX_KEYCLOAK_CLIENT_ID', defaultValue: 'vetpax-dev',
);
const String KEYCLOAK_REDIRECT_URI = String.fromEnvironment(
  'VETPAX_REDIRECT_URI', defaultValue: 'com.vetpax.app:/oauthredirect',
);
// No habilitar ROPC/password grant en un cliente móvil.
