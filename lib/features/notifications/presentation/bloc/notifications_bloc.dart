import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/notifications_repository.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository repository;

  NotificationsBloc(this.repository) : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoad);
    on<LoadNombreNonLues>(_onLoadNonLues);
    on<MarquerToutesLues>(_onMarquerToutesLues);
    on<MarquerNotificationLue>(_onMarquerLue);
    on<NotificationRecueTempsReel>(_onRecueTempsReel);
  }

  Future<void> _onLoad(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    final result = await repository.notifications(page: event.page);
    result.fold(
      (f) => emit(NotificationsError(f.errorMessage)),
      (page) => emit(
        NotificationsLoaded(page.notifications, pagination: page.pagination),
      ),
    );
  }

  Future<void> _onLoadNonLues(
    LoadNombreNonLues event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await repository.nombreNonLues();
    result.fold(
      (f) => emit(NotificationsError(f.errorMessage)),
      (n) => emit(NombreNonLuesLoaded(n)),
    );
  }

  Future<void> _onMarquerToutesLues(
    MarquerToutesLues event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await repository.marquerToutesLues();
    if (result.isLeft()) {
      result.fold((f) => emit(NotificationsError(f.errorMessage)), (_) {});
      return;
    }
    // On revient a la premiere page : « tout marquer comme lu » change
    // l'etat de chaque element, et rester sur la page sept n'aurait aucun
    // sens apres une action qui concerne toute la liste.
    final liste = await repository.notifications();
    liste.fold(
      (f) => emit(NotificationsError(f.errorMessage)),
      (page) => emit(
        NotificationsLoaded(
          page.notifications,
          pagination: page.pagination,
          succes: 'Toutes vos notifications sont marquées comme lues.',
        ),
      ),
    );
  }

  Future<void> _onMarquerLue(
    MarquerNotificationLue event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await repository.marquerLue(event.id);
    result.fold(
      (f) => emit(NotificationsError(f.errorMessage)),
      (_) => add(LoadNotifications()),
    );
  }

  Future<void> _onRecueTempsReel(
    NotificationRecueTempsReel event,
    Emitter<NotificationsState> emit,
  ) async {
    // Une nouvelle notification est arrivée : on rafraîchit la liste.
    add(LoadNotifications());
  }
}
