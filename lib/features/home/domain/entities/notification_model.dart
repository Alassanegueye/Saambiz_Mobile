class NotificationModel {
  final String id;
  final String titre;
  final String message;
  final DateTime date;
  final bool lue;

  NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.date,
    required this.lue,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      date: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lue: json['lue'] ?? false,
    );
  }
}