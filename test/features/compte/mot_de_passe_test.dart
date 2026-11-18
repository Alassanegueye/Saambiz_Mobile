import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/errors/failure.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';
import 'package:saambiz/features/auth/presentation/signup/signup_kit.dart';
import 'package:saambiz/features/compte/domain/repositories/compte_repository.dart';
import 'package:saambiz/features/compte/domain/usecases/change_password.dart';
import 'package:saambiz/features/compte/domain/usecases/delete_account.dart';
import 'package:saambiz/features/compte/domain/usecases/forgot_password.dart';
import 'package:saambiz/features/compte/domain/usecases/get_me.dart';
import 'package:saambiz/features/compte/domain/usecases/modifier_profil.dart';
import 'package:saambiz/features/compte/domain/usecases/reset_password.dart';
import 'package:saambiz/features/compte/presentation/bloc/compte_bloc.dart';
import 'package:saambiz/features/compte/presentation/pages/change_password_page.dart';
import 'package:saambiz/features/compte/presentation/pages/reset_password_page.dart';
import 'package:saambiz/injection_container.dart';

/// Retient ce qui partirait au serveur, et répond par une erreur pour que
/// la page reste affichée.
class _DepotFactice implements CompteRepository {
  final reinitialisations = <String>[];
  final changements = <(String, String)>[];

  Future<Either<Failure, T>> _refus<T>() async =>
      Left(ServerFailure(errorMessage: 'hors ligne'));

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String code,
    required String nouveauMotDePasse,
  }) {
    reinitialisations.add(nouveauMotDePasse);
    return _refus();
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  }) {
    changements.add((ancienMotDePasse, nouveauMotDePasse));
    return _refus();
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) => _refus();
  @override
  Future<Either<Failure, User>> getMe() => _refus();
  @override
  Future<Either<Failure, User>> modifierProfil({
    String? nom,
    String? prenom,
    String? adresse,
    String? telephone,
    String? photoProfilPath,
  }) => _refus();
  @override
  Future<Either<Failure, void>> deleteAccount({String? motif}) => _refus();
}

/// Un champ, par le texte d'aide qu'il affiche vide.
Finder _champ(String indice) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == indice,
);

void main() {
  late _DepotFactice depot;

  setUp(() async {
    await sl.reset();
    depot = _DepotFactice();
    sl.registerFactory<CompteBloc>(
      () => CompteBloc(
        getMe: GetMe(depot),
        modifierProfil: ModifierProfil(depot),
        changePassword: ChangePassword(depot),
        forgotPassword: ForgotPassword(depot),
        resetPassword: ResetPassword(depot),
        deleteAccount: DeleteAccount(depot),
      ),
    );
  });

  Future<void> ouvrir(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pump();
  }

  group('Les règles du mot de passe, celles du serveur', () {
    test('8 caractères, une majuscule, un chiffre, un caractère spécial', () {
      expect(reglesMotDePasse('abcdef').where((r) => r.$2), isEmpty);
      expect(reglesMotDePasse('Abcdef1!').every((r) => r.$2), isTrue);
    });

    test('une espace compte comme caractère spécial, comme au serveur', () {
      expect(reglesMotDePasse('Abcdefg1 ').last.$2, isTrue);
    });

    test('les messages ont leurs accents', () {
      expect(validateMotDePasse('Ab1!'), 'Au moins 8 caractères.');
      expect(validateMotDePasse('Abcdefg1'), 'Au moins un caractère spécial.');
      expect(validateMotDePasse('Abcdefg1!'), isNull);
    });
  });

  testWidgets(
    'réinitialiser : « abcdef » ne part plus (il fallait 8 caractères)',
    (tester) async {
      await ouvrir(tester, const ResetPasswordPage(email: 'awa@exemple.sn'));

      await tester.enterText(_champ('Votre nouveau mot de passe'), 'abcdef');
      await tester.pump();
      await tester.tap(find.text('Changer mon mot de passe'));
      await tester.pump();

      expect(find.text('Au moins 8 caractères.'), findsOneWidget);
      expect(depot.reinitialisations, isEmpty);

      // L'œil montre ce qu'on tape.
      TextField champ() =>
          tester.widget<TextField>(_champ('Votre nouveau mot de passe'));
      expect(champ().obscureText, isTrue);
      await tester.tap(find.byTooltip('Afficher le mot de passe'));
      await tester.pump();
      expect(champ().obscureText, isFalse);

      // Le renvoi du code attend, comme à l'inscription.
      expect(find.textContaining('Renvoyer le code dans'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'changer : la coche quand la confirmation correspond, puis l’envoi',
    (tester) async {
      await ouvrir(tester, const ChangePasswordPage());

      await tester.enterText(_champ('Votre mot de passe actuel'), 'Ancien1!');
      await tester.enterText(_champ('Votre nouveau mot de passe'), 'Nouveau1!');
      await tester.enterText(_champ('Le même, une seconde fois'), 'Nouveau1!');
      await tester.pump();
      expect(
        find.text('Les deux mots de passe sont identiques'),
        findsOneWidget,
      );

      await tester.tap(find.text('Enregistrer le nouveau mot de passe'));
      await tester.pumpAndSettle();
      expect(depot.changements, [('Ancien1!', 'Nouveau1!')]);
    },
  );

  testWidgets('changer : une confirmation différente ne part pas', (
    tester,
  ) async {
    await ouvrir(tester, const ChangePasswordPage());

    await tester.enterText(_champ('Votre mot de passe actuel'), 'Ancien1!');
    await tester.enterText(_champ('Votre nouveau mot de passe'), 'Nouveau1!');
    await tester.enterText(_champ('Le même, une seconde fois'), 'Nouveau2!');
    await tester.tap(find.text('Enregistrer le nouveau mot de passe'));
    await tester.pump();

    expect(
      find.text('Les mots de passe ne correspondent pas.'),
      findsOneWidget,
    );
    expect(depot.changements, isEmpty);
  });
}
