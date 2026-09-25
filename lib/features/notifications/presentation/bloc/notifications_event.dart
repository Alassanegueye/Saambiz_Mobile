import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {}

class LoadNombreNonLues extends NotificationsEvent {}

class MarquerToutesLues extends NotificationsEvent {}

class MarquerNotificationLue extends NotificationsEvent {
  final String id;
  MarquerNotificationLue(this.id);
  @override
  List<Object?> get props => [id];
}

/// Notification reçue en temps réel via le socket (événement `notification:new`).
class NotificationRecueTempsReel extends NotificationsEvent {
  final Map<String, dynamic> data;
  NotificationRecueTempsReel(this.data);
  @override
  List<Object?> get props => [data];
}
