import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../injection_container.dart';
import '../utils/app_logger.dart';

/// Dernière position connue, conservée localement.
/// Sert aux invités, qui n'ont pas de ligne de préférences côté serveur.
const String kLatitudeKey = 'client_latitude';
const String kLongitudeKey = 'client_longitude';
const String kLocalisationDemandeeKey = 'localisation_demandee';

/// Position du client, pour lui proposer les boutiques proches.
///
/// Tout est facultatif : un refus n'empêche rien, l'accueil se contente
/// alors des centres d'intérêt. C'est pourquoi aucune méthode ne lève —
/// elles retournent `null` et l'appelant continue.
class LocalisationService {
  const LocalisationService();

  /// Demande l'autorisation puis relève la position.
  /// Retourne `null` si le service est coupé ou l'autorisation refusée.
  Future<Position?> demanderPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      await _memoriser(position.latitude, position.longitude);
      return position;
    } catch (e) {
      logDebug('⚠️ localisation indisponible: $e');
      return null;
    }
  }

  Future<void> _memoriser(double latitude, double longitude) async {
    try {
      final prefs = sl<SharedPreferences>();
      await prefs.setDouble(kLatitudeKey, latitude);
      await prefs.setDouble(kLongitudeKey, longitude);
      await prefs.setBool(kLocalisationDemandeeKey, true);
    } catch (_) {/* non bloquant */}
  }

  /// Position retenue au dernier passage, sans redemander l'autorisation.
  ({double latitude, double longitude})? positionMemorisee() {
    try {
      final prefs = sl<SharedPreferences>();
      final lat = prefs.getDouble(kLatitudeKey);
      final lng = prefs.getDouble(kLongitudeKey);
      if (lat == null || lng == null) return null;
      return (latitude: lat, longitude: lng);
    } catch (_) {
      return null;
    }
  }

  /// Vrai si l'écran d'autorisation a déjà été présenté : on ne le repropose
  /// pas à chaque ouverture, un refus doit être respecté.
  bool dejaDemandee() {
    try {
      return sl<SharedPreferences>().getBool(kLocalisationDemandeeKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> marquerDemandee() async {
    try {
      await sl<SharedPreferences>().setBool(kLocalisationDemandeeKey, true);
    } catch (_) {/* non bloquant */}
  }
}
