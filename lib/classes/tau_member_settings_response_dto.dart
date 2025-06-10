class TauMemberSettingsResponseDTO {
  final bool showStatus;

  const TauMemberSettingsResponseDTO({
    required this.showStatus,
  });

  factory TauMemberSettingsResponseDTO.fromMap(obj) {
    return TauMemberSettingsResponseDTO(
      showStatus: obj["show-status"]!,
    );
  }
}
