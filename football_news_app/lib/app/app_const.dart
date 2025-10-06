class AppConst {
  // Base pública ya existente
  static const publicApiBase = 'https://pidelope.app/api';
  // Base protegida (es la misma, pero enviaremos API Key)
  static const protectedApiBase = 'https://pidelope.app/api';

  // La misma API Key que configuraste en el backend (X-App-Key)
  static const apiKey = '0702963d-2f5e-4a9b-9f0b-1c4f6f3c8e8b';

  // Identificador de la app para fcm_tokens
  static const appId = 'premierfootball';

    static Map<String, String> headers() => {
    'X-App-Key': apiKey,
    'Content-Type': 'application/json',
  };
}