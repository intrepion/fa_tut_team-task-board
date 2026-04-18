class TeamTask {
  final String id;
  final String ownerUserId;
  final String text;
  final String visibility;

  const TeamTask({
    required this.id,
    required this.ownerUserId,
    required this.text,
    required this.visibility,
  });

  factory TeamTask.fromJson(Map<String, dynamic> json) {
    return TeamTask(
      id: json['id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      text: json['text'] as String,
      visibility: json['visibility'] as String,
    );
  }
}
