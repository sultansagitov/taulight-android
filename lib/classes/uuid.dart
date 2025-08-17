import 'package:uuid/uuid.dart';

class UUID {
  static final UUID nil = UUID(List.filled(16, 0));

  final List<int> _value;

  UUID(this._value);

  factory UUID.random() => UUID.fromString(Uuid().v4());

  factory UUID.fromString(String s) => UUID(Uuid.parse(s));

  static UUID? fromNullableString(String? s) =>
      s != null ? UUID.fromString(s) : null;

  @override
  String toString() => Uuid.unparse(_value);

  @override
  bool operator ==(Object other) {
    return toString() == other.toString();
  }

  @override
  int get hashCode => toString().hashCode;
}
