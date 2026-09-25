import 'package:equatable/equatable.dart';

import '../../data/models/promotion_model.dart';

abstract class PromotionsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PromotionsInitial extends PromotionsState {}

class PromotionsLoading extends PromotionsState {}

class PromotionsLoaded extends PromotionsState {
  final List<PromotionModel> promotions;
  PromotionsLoaded(this.promotions);
  @override
  List<Object?> get props => [promotions];
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
