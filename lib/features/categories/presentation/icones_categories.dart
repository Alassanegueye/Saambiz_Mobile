import 'package:flutter/material.dart';

/// Nom d'icône choisi dans le dashboard admin → icône de l'application.
///
/// Le dashboard propose exactement cette liste (Dashboard/src/pages/
/// categories/icones.js). Un nom inconnu retombe sur une icône neutre :
/// une catégorie créée avec une icône plus récente reste affichable.
IconData iconeCategorie(String? nom) {
  switch (nom) {
    case 'checkroom':
      return Icons.checkroom_outlined;
    case 'man':
      return Icons.man;
    case 'woman':
      return Icons.woman;
    case 'shopping_bag':
      return Icons.shopping_bag_outlined;
    case 'spa':
      return Icons.spa_outlined;
    case 'diamond':
      return Icons.diamond_outlined;
    case 'watch':
      return Icons.watch_outlined;
    case 'smartphone':
      return Icons.smartphone_outlined;
    case 'computer':
      return Icons.computer_outlined;
    case 'chair':
      return Icons.chair_outlined;
    case 'kitchen':
      return Icons.kitchen_outlined;
    case 'shopping_basket':
      return Icons.shopping_basket_outlined;
    case 'restaurant':
      return Icons.restaurant_outlined;
    case 'lunch_dining':
      return Icons.lunch_dining_outlined;
    case 'local_drink':
      return Icons.local_drink_outlined;
    case 'local_cafe':
      return Icons.local_cafe_outlined;
    case 'cake':
      return Icons.cake_outlined;
    case 'bakery_dining':
      return Icons.bakery_dining_outlined;
    case 'child_care':
      return Icons.child_care_outlined;
    case 'toys':
      return Icons.toys_outlined;
    case 'favorite':
      return Icons.favorite_border_rounded;
    case 'sports_soccer':
      return Icons.sports_soccer_outlined;
    case 'palette':
      return Icons.palette_outlined;
    case 'handyman':
      return Icons.handyman_outlined;
    case 'content_cut':
      return Icons.content_cut_outlined;
    case 'directions_car':
      return Icons.directions_car_outlined;
    case 'pets':
      return Icons.pets_outlined;
    case 'menu_book':
      return Icons.menu_book_outlined;
    case 'local_florist':
      return Icons.local_florist_outlined;
    case 'more_horiz':
      return Icons.more_horiz_rounded;
    default:
      return Icons.local_offer_outlined;
  }
}
