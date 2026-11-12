import 'package:saambiz/core/widgets/messages.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/errors/message_erreur.dart';
import '../../../core/services/token_service.dart';
import '../../../core/theme/app_color.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/image_reseau.dart';
import '../../../injection_container.dart';
import '../data/avis_remote_datasource.dart';

/// Avis d'une boutique : les lire, laisser le sien, le corriger, le retirer.
///
/// Le backend servait ces quatre routes depuis le début sans qu'aucun écran
/// ne les appelle : seule la note moyenne apparaissait sur la fiche boutique,
/// sans qu'on puisse savoir d'où elle venait ni la contredire.
///
/// Ouvert aux visiteurs sans compte en lecture : la liste s'affiche, et
/// l'invitation à se connecter remplace le formulaire.
Future<void> ouvrirAvisBoutique(
  BuildContext context, {
  required String boutiqueId,
  required String nomBoutique,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _FeuilleAvis(boutiqueId: boutiqueId, nomBoutique: nomBoutique),
  );
}

class _FeuilleAvis extends StatefulWidget {
  final String boutiqueId;
  final String nomBoutique;

  const _FeuilleAvis({required this.boutiqueId, required this.nomBoutique});

  @override
  State<_FeuilleAvis> createState() => _FeuilleAvisState();
}

class _FeuilleAvisState extends State<_FeuilleAvis> {
  late final AvisRemoteDataSource _source = AvisRemoteDataSource(sl<Dio>());
  final _commentaire = TextEditingController();

  AvisBoutique _boutique = AvisBoutique.vide;
  Avis? _mien;
  int _note = 0;

  bool _chargement = true;
  bool _envoi = false;
  bool _connecte = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _commentaire.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final connecte = await sl<TokenService>().isAuthenticated;
      final liste = await _source.avisBoutique(widget.boutiqueId);

      // L'avis personnel n'est demandé que si quelqu'un est connecté : la
      // route exige une session, et l'appeler en invité produirait un 401
      // qui n'apprendrait rien à personne.
      Avis? mien;
      if (connecte) {
        try {
          mien = await _source.monAvis(widget.boutiqueId);
        } on DioException {
          // Pas d'avis, ou session expirée : la lecture publique suffit.
          mien = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _connecte = connecte;
        _boutique = liste;
        _mien = mien;
        _note = mien?.note ?? 0;
        _commentaire.text = mien?.commentaire ?? '';
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = messageErreurReseau(e);
        _chargement = false;
      });
    }
  }

  Future<void> _envoyer() async {
    if (_note < 1) {
      setState(() => _erreur = 'Choisissez une note entre 1 et 5 étoiles.');
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await _source.laisser(
        boutiqueId: widget.boutiqueId,
        note: _note,
        commentaire: _commentaire.text,
      );
      if (!mounted) return;
      afficherSucces(
        context,
        _mien == null
            ? 'Merci, votre avis est publié.'
            : 'Avis mis à jour avec succès',
      );
      await _charger();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = messageErreurReseau(e);
        _envoi = false;
      });
      return;
    }
    if (mounted) setState(() => _envoi = false);
  }

  Future<void> _supprimer() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer votre avis ?'),
        content: const Text(
          'Votre note et votre commentaire seront effacés. '
          'Vous pourrez en laisser un autre plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    setState(() => _envoi = true);
    try {
      await _source.supprimer(widget.boutiqueId);
      if (!mounted) return;
      afficherSucces(context, 'Votre avis a été retiré.');
      setState(() {
        _mien = null;
        _note = 0;
        _commentaire.clear();
      });
      await _charger();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = messageErreurReseau(e);
        _envoi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // La feuille monte avec le clavier : sans cela, le champ de commentaire
    // se retrouve caché dès qu'on le touche.
    final clavier = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: clavier),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controleur) => DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _chargement
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(child: CircularProgressIndicator()),
                )
              : ListView(
                  controller: controleur,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    const _Poignee(),
                    const SizedBox(height: 12),
                    _enTete(),
                    const SizedBox(height: 20),
                    if (_connecte) _formulaire() else _inviteConnexion(),
                    if (_erreur != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _erreur!,
                        style: const TextStyle(color: Color(0xFFC6382B)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _listeAvis(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _enTete() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.nomBoutique,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColor.kPrimary,
        ),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          const Icon(Icons.star_rounded, color: AppColor.kSecondary, size: 22),
          const SizedBox(width: 4),
          Text(
            _boutique.total == 0 ? '—' : _boutique.moyenne.toString(),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Text(
            _boutique.total == 0
                ? 'Aucun avis pour le moment'
                : '${_boutique.total} avis',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    ],
  );

  Widget _inviteConnexion() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F5F8),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Text(
      'Connectez-vous pour laisser votre avis sur cette boutique.',
      style: TextStyle(color: Colors.black87),
    ),
  );

  Widget _formulaire() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _mien == null ? 'Votre avis' : 'Votre avis (modifiable)',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Row(
        children: List.generate(5, (i) {
          final valeur = i + 1;
          return IconButton(
            onPressed: _envoi ? null : () => setState(() => _note = valeur),
            icon: Icon(
              valeur <= _note ? Icons.star_rounded : Icons.star_border_rounded,
              color: AppColor.kSecondary,
              size: 32,
            ),
            tooltip: '$valeur étoile${valeur > 1 ? 's' : ''}',
          );
        }),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _commentaire,
        enabled: !_envoi,
        maxLines: 3,
        maxLength: 500,
        decoration: const InputDecoration(
          hintText: 'Votre commentaire (facultatif)',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: _envoi ? null : _envoyer,
              child: Text(_mien == null ? 'Publier mon avis' : 'Enregistrer'),
            ),
          ),
          if (_mien != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: _envoi ? null : _supprimer,
              child: const Text('Retirer'),
            ),
          ],
        ],
      ),
    ],
  );

  Widget _listeAvis() {
    if (_boutique.avis.isEmpty) {
      return const Text(
        'Soyez le premier à donner votre avis.',
        style: TextStyle(color: Colors.black54),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ce qu’en disent les clients',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final avis in _boutique.avis) _ligneAvis(avis),
      ],
    );
  }

  Widget _ligneAvis(Avis avis) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: ImageReseau(
            avis.photoAuteur,
            width: 38,
            height: 38,
            largeurServeur: 114,
            repli: const ColoredBox(
              color: Color(0xFFEDF0F8),
              child: Icon(Icons.person_outline, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      avis.auteur,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (avis.date != null)
                    Text(
                      dateCourte.format(avis.date!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avis.note
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 15,
                    color: AppColor.kSecondary,
                  ),
                ),
              ),
              if (avis.commentaire.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(avis.commentaire),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _Poignee extends StatelessWidget {
  const _Poignee();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFD9DEE8),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
