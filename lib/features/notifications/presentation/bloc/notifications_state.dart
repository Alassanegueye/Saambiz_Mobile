import 'package:saambiz/core/widgets/barre_pagination.dart';
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

  /// Confirmation d'une action (« tout marquer comme lu »), `null` sinon.
  final String? succes;

  /// Où l'on est dans la liste. Une page unique replie la barre.
  final Pagination pagination;

  NotificationsLoaded(
    this.notifications, {
    this.succes,
    this.pagination = const Pagination(),
  });
  @override
  List<Object?> get props => [
    notifications,
    succes,
    pagination.page,
    pagination.pages,
  ];
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
