import 'dart:io';
import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/compte_model.dart';

abstract class CompteRemoteDataSource {
  Future<CompteModel> getMe();

  Future<CompteModel> modifierProfil({
    String? nom,
    String? prenom,
    String? adresse,
    String? telephone,
    String? photoProfilPath,
  });

  Future<void> changePassword({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  });

  Future<void> forgotPassword(String email);

  Future<void> resetPassword({
    required String email,
    required String code,
    required String nouveauMotDePasse,
  });

  Future<void> deleteAccount({String? motif});
}

class CompteRemoteDataSourceImpl implements CompteRemoteDataSource {
  final Dio dio;
  CompteRemoteDataSourceImpl(this.dio);

  @override
  Future<CompteModel> getMe() async {
    final res = await dio.get(CompteEndpoints.me);
    return CompteModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<CompteModel> modifierProfil({
    String? nom,
    String? prenom,
    String? adresse,
    String? telephone,
    String? photoProfilPath,
  }) async {
    final form = FormData.fromMap({
      if (nom != null) 'nom': nom,
      if (prenom != null) 'prenom': prenom,
      if (adresse != null) 'adresse': adresse,
      if (telephone != null) 'telephone': telephone,
      if (photoProfilPath != null)
        'photoProfil': await MultipartFile.fromFile(photoProfilPath,
            filename: File(photoProfilPath).uri.pathSegments.last),
    });
    final res = await dio.put(CompteEndpoints.modifierProfil, data: form);
    return CompteModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  }) async {
    await dio.put(CompteEndpoints.changePassword, data: {
      'ancienMotDePasse': ancienMotDePasse,
      'nouveauMotDePasse': nouveauMotDePasse,
    });
  }

  @override
  Future<void> forgotPassword(String email) async {
    await dio.post(CompteEndpoints.forgotPassword, data: {'email': email});
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String nouveauMotDePasse,
  }) async {
    await dio.post(CompteEndpoints.resetPassword, data: {
      'email': email,
      'code': code,
      'nouveauMotDePasse': nouveauMotDePasse,
    });
  }

  @override
  Future<void> deleteAccount({String? motif}) async {
    await dio.delete(
      CompteEndpoints.deleteAccount,
      data: motif != null && motif.isNotEmpty ? {'motif': motif} : null,
    );
  }
}
