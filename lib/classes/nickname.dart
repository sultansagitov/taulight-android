class Nickname {
  final String _value;

  const Nickname(this._value);

  factory Nickname.checked(String? n) {
    if (n == null) {
      throw ArgumentError('Nickname is null');
    }

    if (n.isEmpty) {
      throw ArgumentError('Empty nickname');
    }

    final regex = RegExp(r'^[a-zA-Z0-9_.]+$');
    if (!regex.hasMatch(n)) {
      throw ArgumentError('Invalid nickname');
    }
    return Nickname(n);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Nickname &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => _value;

  static Nickname? checkedNullable(String? n) {
    return n != null ? Nickname.checked(n) : null;
  }
}
