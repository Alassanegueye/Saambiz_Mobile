import 'package:saambiz/core/widgets/page_vendeur.dart';
import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/widgets/confirmation.dart';
import 'package:saambiz/core/widgets/libelle_obligatoire.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/police.dart';
import '../../../../injection_container.dart';
import '../bloc/signalements_bloc.dart';
import '../bloc/signalements_event.dart';
import '../bloc/signalements_state.dart';

/// Le motif « Autre » : le seul qui oblige à préciser.
const kMotifAutre = 'Autre';

/// Les motifs proposés, selon ce qu'on signale. Le libellé choisi part tel
/// quel comme `raison` : c'est ce que l'équipe lit dans l'administration.
List<String> motifsSignalement(String type) => type == 'boutique'
    ? const [
        'Arnaque ou fraude',
        'Commande payée jamais livrée',
        'Usurpation d’identité',
        'Comportement abusif',
        'Contenu choquant ou inapproprié',
        kMotifAutre,
      ]
    : const [
        'Contrefaçon ou faux produit',
        'Arnaque ou fraude',
        'Produit interdit ou dangereux',
        'Prix ou description trompeurs',
        'Contenu choquant ou inapproprié',
        kMotifAutre,
      ];

/// Formulaire générique de signalement (POST /signalements), utilisable
/// pour signaler un produit ou une boutique.
class SignalerFormPage extends StatelessWidget {
  final String type; // 'produit' | 'boutique'
  final String cibleId;
  const SignalerFormPage({
    super.key,
    required this.type,
    required this.cibleId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SignalementsBloc>(),
      child: _SignalerFormView(type: type, cibleId: cibleId),
    );
  }
}

class _SignalerFormView extends StatefulWidget {
  final String type;
  final String cibleId;
  const _SignalerFormView({required this.type, required this.cibleId});
  @override
  State<_SignalerFormView> createState() => _SignalerFormViewState();
}

class _SignalerFormViewState extends State<_SignalerFormView> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();

  /// Le motif choisi ; rien ne part tant qu'il n'y en a pas.
  String? _motif;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  /// Un signalement part vers une équipe qui va le lire et agir : il se
  /// confirme. Il partait au premier appui, sans rien demander.
  Future<void> _envoyer() async {
    final motif = _motif;
    if (motif == null || !_formKey.currentState!.validate()) return;
    final bloc = context.read<SignalementsBloc>();
    final confirme = await confirmerAction(
      context,
      icone: Icons.flag_outlined,
      titre: 'Envoyer ce signalement ?',
      message:
          'Il sera transmis à l’équipe SaamBiz, qui examinera votre demande.',
      action: 'Envoyer le signalement',
      // Rien n'est détruit : ce qui est engagé, c'est un examen.
      destructive: false,
    );
    if (!confirme) return;
    bloc.add(
      CreerSignalement(
        type: widget.type,
        raison: motif,
        description: _descCtrl.text.trim(),
        cibleId: widget.cibleId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boutique = widget.type == 'boutique';
    final autre = _motif == kMotifAutre;
    return BlocConsumer<SignalementsBloc, SignalementsState>(
      listener: (context, state) {
        if (state is SignalementsError) {
          afficherErreur(context, state.message);
        } else if (state is SignalementEnvoye) {
          afficherSucces(context, 'Signalement envoyé, merci.');
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final loading = state is SignalementsLoading;
        return ScaffoldMarine(
          backgroundColor: AppColor.kBackground,
          appBar: AppBar(
            title: Text(
              boutique ? 'Signaler cette boutique' : 'Signaler ce produit',
            ),
          ),
          // Le bouton reste en bas, visible sans défiler, et remonte avec le
          // clavier pendant qu'on précise.
          bottomNavigationBar: _BarreEnvoi(
            chargement: loading,
            onEnvoyer: loading || _motif == null ? null : _envoyer,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Des motifs à choisir plutôt qu'un champ « Raison » vide :
                // plus simple pour le client, plus clair pour l'équipe.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColor.kWhite,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColor.kLine),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColor.kErreurLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.flag_outlined,
                              color: AppColor.kErreur,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Qu’est-ce qui ne va pas ?',
                                  style: TextStyle(
                                    fontFamily: kPolice,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.kGrayscaleDark100,
                                  ),
                                ),
                                Text(
                                  boutique
                                      ? 'Choisissez ce qui décrit le mieux le problème avec cette boutique.'
                                      : 'Choisissez ce qui décrit le mieux le problème avec ce produit.',
                                  style: const TextStyle(
                                    fontFamily: kPolice,
                                    fontSize: 12.5,
                                    height: 1.35,
                                    color: AppColor.kGrayscale40,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (final m in motifsSignalement(widget.type)) ...[
                        _Motif(
                          libelle: m,
                          choisi: _motif == m,
                          onTap: loading
                              ? null
                              : () => setState(() => _motif = m),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  // Facultatif, sauf pour « Autre » : le motif seul ne dit
                  // alors rien. Le serveur l'accepte vide.
                  validator: (v) => autre && (v == null || v.trim().isEmpty)
                      ? 'Précisez ce qui ne va pas'
                      : null,
                  decoration: InputDecoration(
                    label: autre
                        ? const LibelleObligatoire('Précisez')
                        : const Text('Précisez (facultatif)'),
                    hintText:
                        'Ce que vous avez constaté, un numéro de commande…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'L’équipe SaamBiz examine chaque signalement et peut '
                        'retirer un contenu qui enfreint les règles.',
                        style: TextStyle(
                          fontFamily: kPolice,
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColor.kGrayscale40,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// La barre du bas : « Envoyer le signalement », grisé tant qu'aucun motif
/// n'est choisi.
class _BarreEnvoi extends StatelessWidget {
  final bool chargement;
  final VoidCallback? onEnvoyer;
  const _BarreEnvoi({required this.chargement, required this.onEnvoyer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColor.kWhite,
        border: Border(top: BorderSide(color: AppColor.kLine)),
      ),
      child: ElevatedButton(
        onPressed: onEnvoyer,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.kErreur,
          foregroundColor: AppColor.kWhite,
          disabledBackgroundColor: AppColor.kGrayscale20,
          disabledForegroundColor: AppColor.kGrayscale40,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: chargement
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColor.kWhite,
                ),
              )
            : const Text(
                'Envoyer le signalement',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

/// Un motif, comme un bouton radio : un rond, le libellé, la ligne marine
/// quand il est choisi.
class _Motif extends StatelessWidget {
  final String libelle;
  final bool choisi;
  final VoidCallback? onTap;
  const _Motif({required this.libelle, required this.choisi, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: choisi,
      button: true,
      child: Material(
        color: choisi ? AppColor.kPrimaryLight : AppColor.kWhite,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: choisi ? AppColor.kPrimary : AppColor.kLine,
                width: choisi ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  choisi
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: choisi ? AppColor.kPrimary : AppColor.kGrayscale30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    libelle,
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 14,
                      fontWeight: choisi ? FontWeight.w700 : FontWeight.w500,
                      color: AppColor.kGrayscaleDark100,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
