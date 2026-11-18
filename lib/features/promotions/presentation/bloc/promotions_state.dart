import 'package:equatable/equatable.dart';

import '../../../../core/widgets/barre_pagination.dart';
import '../../data/models/promotion_model.dart';

abstract class PromotionsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PromotionsInitial extends PromotionsState {}

class PromotionsLoading extends PromotionsState {}

class PromotionsLoaded extends PromotionsState {
  final List<PromotionModel> promotions;

  /// Où l'on se situe dans la liste du vendeur. Les promotions actives de la
  /// vitrine ne sont pas paginées : elles gardent la valeur par défaut, une
  /// page unique, et la barre ne s'affiche alors pas.
  final Pagination pagination;

  PromotionsLoaded(this.promotions, {this.pagination = const Pagination()});
  @override
  List<Object?> get props => [promotions, pagination.page, pagination.pages];
}

class PromotionActionSucces extends PromotionsState {
  final String message;
  PromotionActionSucces(this.message);
  @override
  List<Object?> get props => [message];
}

class PromotionsError extends PromotionsState {
  final String message;
  PromotionsError(this.message);
  @override
  List<Object?> get props => [message];
}
