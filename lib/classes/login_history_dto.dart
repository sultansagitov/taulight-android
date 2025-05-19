class LoginHistoryDTO {
  final DateTime time;
  final String ip;
  final String device;

  const LoginHistoryDTO({
    required this.time,
    required this.ip,
    required this.device,
  });

  factory LoginHistoryDTO.fromMap(Map<String, dynamic> map) {
    return LoginHistoryDTO(
      time: DateTime.parse(map['time']).toUtc().toLocal(),
      ip: map['ip'],
      device: map['device'],
    );
  }
}
