enum Permission {
  invite, kick;

  static Permission fromStr(String s) {
    return Permission.values.firstWhere((p) => p.name == s.toLowerCase());
  }
}
