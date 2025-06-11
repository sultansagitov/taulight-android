abstract class Source {
  final DateTime datetime;
  final String type;

  Source({required this.type, DateTime? datetime})
      : datetime = datetime ?? DateTime.now();

  factory Source.fromMap(Map map) {
    String type = map["type"];
    DateTime datetime = DateTime.parse(map["datetime"]);

    switch (type) {
      case "qr":
        return QRSource(datetime: datetime);
      case "hub":
        String address = map["address"];
        return HubSource(address: address, datetime: datetime);
      default:
        throw Exception("Unknown type \"$type\"");
    }
  }

  Map<String, String> toMap() => {
    "type": type,
    "datetime": datetime.toIso8601String(),
  };
}

class QRSource extends Source {
  QRSource({super.datetime}) : super(type: "qr");
}

class HubSource extends Source {
  final String address;

  HubSource({required this.address, super.datetime}) : super(type: "hub");

  @override
  Map<String, String> toMap() => {...super.toMap(), "address": address};
}