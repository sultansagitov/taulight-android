class LoginHistoryDTO {
  final DateTime time;
  final String ip;
  final String device;
  final bool online;

  const LoginHistoryDTO({
    required this.time,
    required this.ip,
    required this.device,
    required this.online,
  });

  factory LoginHistoryDTO.fromMap(Map<String, dynamic> map) {
    return LoginHistoryDTO(
      time: DateTime.parse(map['time']).toUtc().toLocal(),
      ip: map['ip'],
      device: map['device'],
      online: map['online'],
    );
  }
}
