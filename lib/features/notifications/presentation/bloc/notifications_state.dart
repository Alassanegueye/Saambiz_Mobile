import 'package:equatable/equatable.dart';

import '../../../home/domain/entities/notification_model.dart';

abstract class NotificationsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;
  NotificationsLoaded(this.notifications);
  @override
  List<Object?> get props => [notifications];
}

class NombreNonLuesLoaded extends NotificationsState {
  final int nombre;
  NombreNonLuesLoaded(this.nombre);
  @override
  List<Object?> get props => [nombre];
}

class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);
  @override
  List<Object?> get props => [message];
}
