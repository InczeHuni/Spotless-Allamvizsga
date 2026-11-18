class LicensePlateValidator {
  /// Validálja, hogy a megadott rendszám megfelel-e a romániai vagy magyarországi rendszám formátumoknak.
  ///
  /// **Romániai rendszámok (összes 41 megye + Bukarest):**
  /// - Bukarest: B 12 ABC, B 123 ABC, B 1234 ABC
  /// - Megyék (pl. CJ, HR, TM, IS, AR, BH, CV, MS, SB, BV, SM, TL, stb.): CJ 01 ABC, HR 12 HUS, TM 99 XYZ
  /// - Minta: 1 vagy 2 megyekód betű + 2 vagy 3 számjegy + 3 betű.
  ///
  /// **Magyarországi rendszámok:**
  /// - Régi formátum: ABC-123 vagy ABC 123 (3 betű + 3 szám)
  /// - Új formátum (2022+): AA-AA-123 vagy AA AA 123 vagy AAAA-123 (4 betű + 3 szám)
  static bool isValid(String input) {
    if (input.trim().isEmpty) return false;

    // Eltávolítjuk a szóközöket és kötőjeleket az ellenőrzéshez
    final clean = input.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

    // 1. Romániai rendszámok: 1-2 betű (megye/Bukarest) + 2-3 szám + 3 betű
    final roRegex = RegExp(r'^[A-Z]{1,2}\d{2,3}[A-Z]{3}$');

    // 2. Magyarországi régi rendszámok: 3 betű + 3 szám (pl. ABC123)
    final huOldRegex = RegExp(r'^[A-Z]{3}\d{3}$');

    // 3. Magyarországi új rendszámok (2022+): 4 betű + 3 szám (pl. AAAA123)
    final huNewRegex = RegExp(r'^[A-Z]{4}\d{3}$');

    return roRegex.hasMatch(clean) || huOldRegex.hasMatch(clean) || huNewRegex.hasMatch(clean);
  }

  /// Szépen formázza a rendszámot (pl. "CJ01ABC" -> "CJ 01 ABC", "ABC123" -> "ABC-123", "AAAA123" -> "AA-AA-123")
  static String format(String input) {
    final clean = input.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

    // Románia: B 123 ABC vagy CJ 01 ABC
    final roMatch = RegExp(r'^([A-Z]{1,2})(\d{2,3})([A-Z]{3})$').firstMatch(clean);
    if (roMatch != null) {
      return '${roMatch.group(1)} ${roMatch.group(2)} ${roMatch.group(3)}';
    }

    // Magyarország új: AA-AA-123
    final huNewMatch = RegExp(r'^([A-Z]{2})([A-Z]{2})(\d{3})$').firstMatch(clean);
    if (huNewMatch != null) {
      return '${huNewMatch.group(1)}-${huNewMatch.group(2)}-${huNewMatch.group(3)}';
    }

    // Magyarország régi: ABC-123
    final huOldMatch = RegExp(r'^([A-Z]{3})(\d{3})$').firstMatch(clean);
    if (huOldMatch != null) {
      return '${huOldMatch.group(1)}-${huOldMatch.group(2)}';
    }

    return input.trim().toUpperCase();
  }
}
