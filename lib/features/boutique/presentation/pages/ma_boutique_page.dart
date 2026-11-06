import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:saambiz/core/utils/texte.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../bloc/boutique_bloc.dart';
import '../bloc/boutique_event.dart';
import '../bloc/boutique_state.dart';
import 'boutique_form_page.dart';

class _C {
  static const green = Color(0xFF01154B);
  static const black = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F5F8);
  static const sub = Color(0xFF5B6C8A);
  static const border = Color(0xFFE3E8F0);
  static const orange = Color(0xFFFF8F00);
}

/// Écran de gestion de la boutique du vendeur connecté.
class MaBoutiquePage extends StatelessWidget {
  const MaBoutiquePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BoutiqueBloc>()..add(LoadMaBoutique()),
      child: const _MaBoutiqueView(),
    );
  }
}

class _MaBoutiqueView extends StatelessWidget {
  const _MaBoutiqueView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(title: const Text('Ma boutique')),
      body: BlocConsumer<BoutiqueBloc, BoutiqueState>(
        listener: (context, state) {
          if (state is BoutiqueError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BoutiqueLoading || state is BoutiqueInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BoutiqueInexistante) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      color: _C.sub,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Vous n\'avez pas encore de boutique',
                      style: TextStyle(color: _C.sub),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final res = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BoutiqueFormPage(),
                          ),
                        );
                        if (res != null && context.mounted) {
                          context.read<BoutiqueBloc>().add(LoadMaBoutique());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.green,
                        foregroundColor: _C.white,
                      ),
                      child: const Text('Créer ma boutique'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is BoutiqueLoaded) {
            final b = state.boutique;
            Future<void> modifier() async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BoutiqueFormPage(boutique: b),
                ),
              );
              if (context.mounted) {
                context.read<BoutiqueBloc>().add(LoadMaBoutique());
              }
            }

            final telephone = b.telephone;
            return ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // Identité sur le bleu de l'en-tête.
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                  decoration: const BoxDecoration(
                    color: AppColor.kPrimary,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 72,
                          height: 72,
                          color: _C.white,
                          child: (b.logo ?? '').isNotEmpty
                              ? ImageReseau(b.logo!, fit: BoxFit.cover, repli: _initiales(b.nom))
                              : _initiales(b.nom),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.nom,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                                color: _C.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: b.enPause
                                    ? AppColor.kSecondary
                                    : AppColor.kSuccesLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                b.enPause ? 'En pause' : 'Ouverte',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: b.enPause
                                      ? AppColor.kPrimary
                                      : AppColor.kSucces,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _C.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _C.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _info(
                              Icons.notes_rounded,
                              'Description',
                              b.description.trim().isEmpty
                                  ? 'Non renseignée'
                                  : b.description,
                            ),
                            _info(
                              Icons.location_on_outlined,
                              'Localisation',
                              b.localisation,
                            ),
                            if (telephone != null && telephone.isNotEmpty)
                              _info(
                                Icons.phone_outlined,
                                'Téléphone',
                                telephone,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: modifier,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: const Text('Modifier la boutique'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColor.kPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          context.read<BoutiqueBloc>().add(
                            b.enPause
                                ? ReactiverBoutiqueRequested()
                                : PauseBoutiqueRequested(),
                          );
                        },
                        icon: Icon(
                          b.enPause
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                        ),
                        label: Text(
                          b.enPause
                              ? 'Réactiver la boutique'
                              : 'Mettre en pause',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: b.enPause
                              ? AppColor.kSucces
                              : AppColor.kSecondaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _initiales(String nom) => Center(
    child: Text(
      initialesDe(nom),
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColor.kPrimary,
      ),
    ),
  );

  Widget _info(IconData icon, String libelle, String texte) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColor.kPrimaryMedium),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                libelle,
                style: const TextStyle(fontSize: 12.5, color: _C.sub),
              ),
              const SizedBox(height: 1),
              Text(
                texte,
                style: const TextStyle(fontSize: 14, color: _C.black),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
