enum AppLanguage {
  english('English', 'en'),
  hindi('हिन्दी', 'hi'),
  bengali('বাংলা', 'bn');

  const AppLanguage(this.nativeName, this.code);

  final String nativeName;

  /// ISO 639-1 code the backend's `/translate` endpoint expects as `target`.
  final String code;
}
