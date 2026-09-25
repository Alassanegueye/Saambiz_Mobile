import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../injection_container.dart';
import '../../../home/data/models/produit_model.dart';
import '../../data/datasources/vendeur_produit_datasource.dart';
import '../../data/models/categorie_model.dart';

class _C {
  static const green = Color(0xFF1B3A6B);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7F2);
  static const sub = Color(0xFF7A8473);
  static const border = Color(0xFFE3EAD0);
}

class ProduitFormPage extends StatefulWidget {
  final ProduitModel? produit; // null = création
  const ProduitFormPage({super.key, this.produit});

  @override
  State<ProduitFormPage> createState() => _ProduitFormPageState();
}

class _ProduitFormPageState extends State<ProduitFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _qteCtrl = TextEditingController();

  final _ds = sl<VendeurProduitDataSource>();
  List<CategorieModel> _categories = [];
  String? _categorieId;
  String? _imagePath;
  bool _loading = false;
  bool _loadingCats = true;
  String? _erreurCats;

  // ── Galerie multi-images (mode édition uniquement) ────────────────────
  late List<ProduitImage> _imagesExistantes;
  bool _uploadingImages = false;
  String? _suppressionImageId;

  bool get _isEdit => widget.produit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produit;
    _imagesExistantes = List<ProduitImage>.from(p?.images ?? const []);
    if (p != null) {
      _nomCtrl.text = p.nom;
      _descCtrl.text = p.description;
      _prixCtrl.text = p.prix;
      _qteCtrl.text = p.quantite.toString();
    }
    _chargerCategories();
  }

  Future<void> _chargerCategories() async {
    setState(() {
      _loadingCats = true;
      _erreurCats = null;
    });
    try {
      final cats = await _ds.categories();
      setState(() {
        _categories = cats;
        _loadingCats = false;
        // Pré-sélection en édition si la catégorie existe
        if (_isEdit) {
          final match = cats.where((c) => c.nom == widget.produit!.categorie);
          if (match.isNotEmpty) _categorieId = match.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _loadingCats = false;
        _erreurCats = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    _prixCtrl.dispose();
    _qteCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
    if (x != null) setState(() => _imagePath = x.path);
  }

  Future<void> _ajouterPhotosSupplementaires() async {
    if (!_isEdit) return;
    final picker = ImagePicker();
    final fichiers =
        await picker.pickMultiImage(imageQuality: 80, maxWidth: 1200);
    if (fichiers.isEmpty) return;
    setState(() => _uploadingImages = true);
    try {
      await _ds.ajouterImages(
          widget.produit!.id, fichiers.map((f) => f.path).toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photos ajoutées')),
      );
      // Le produit rafraîchi n'est pas re-fetch ici (pas de usecase dédié
      // dans cet écran) : on affiche un message de succès, la liste sera
      // à jour à la prochaine ouverture / rechargement de "Mes produits".
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur upload : $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _uploadingImages = false);
    }
  }

  Future<void> _supprimerPhoto(ProduitImage image) async {
    if (!_isEdit) return;
    setState(() => _suppressionImageId = image.id);
    try {
      await _ds.supprimerImage(widget.produit!.id, image.id);
      if (!mounted) return;
      setState(() {
        _imagesExistantes.removeWhere((i) => i.id == image.id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _suppressionImageId = null);
    }
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categorieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez une catégorie')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final prix = num.tryParse(_prixCtrl.text.trim()) ?? 0;
      final qte = int.tryParse(_qteCtrl.text.trim()) ?? 0;
      if (_isEdit) {
        await _ds.modifierProduit(
          id: widget.produit!.id,
          nom: _nomCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          prix: prix,
          quantite: qte,
          categorieId: _categorieId,
          imagePath: _imagePath,
        );
      } else {
        await _ds.ajouterProduit(
          nom: _nomCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          prix: prix,
          quantite: qte,
          categorieId: _categorieId!,
          imagePath: _imagePath,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: Text(_isEdit ? 'Modifier le produit' : 'Nouveau produit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _imagePicker(),
            const SizedBox(height: 16),
            _input(_nomCtrl, 'Nom du produit',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom requis' : null),
            const SizedBox(height: 12),
            _input(_descCtrl, 'Description', maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Description requise' : null),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _input(_prixCtrl, 'Prix (FCFA)',
                      keyboard: TextInputType.number,
                      validator: (v) =>
                          (num.tryParse(v ?? '') == null) ? 'Prix invalide' : null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _input(_qteCtrl, 'Quantité',
                      keyboard: TextInputType.number,
                      validator: (v) =>
                          (int.tryParse(v ?? '') == null) ? 'Qté invalide' : null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _categoriePicker(),
            if (_isEdit) ...[
              const SizedBox(height: 24),
              _photosSupplementairesSection(),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _soumettre,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                foregroundColor: _C.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Enregistrer' : 'Publier le produit',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePicker() {
    Widget content;
    if (_imagePath != null) {
      content = Image.file(File(_imagePath!), fit: BoxFit.cover);
    } else if (_isEdit && widget.produit!.image.isNotEmpty) {
      content = CachedNetworkImage(
          imageUrl: widget.produit!.image, fit: BoxFit.cover);
    } else {
      content = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: _C.sub, size: 32),
            SizedBox(height: 8),
            Text('Ajouter une photo', style: TextStyle(color: _C.sub)),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: _choisirImage,
      child: Container(
        height: 170,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }

  Widget _photosSupplementairesSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Photos supplémentaires',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: _C.black)),
              ),
              TextButton.icon(
                onPressed: _uploadingImages ? null : _ajouterPhotosSupplementaires,
                icon: _uploadingImages
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Ajouter'),
                style: TextButton.styleFrom(foregroundColor: _C.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_imagesExistantes.isEmpty)
            const Text('Aucune photo supplémentaire pour ce produit.',
                style: TextStyle(color: _C.sub, fontSize: 13))
          else
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _imagesExistantes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final img = _imagesExistantes[i];
                  final suppression = _suppressionImageId == img.id;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: img.url,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 90,
                            height: 90,
                            color: _C.bg,
                            child: const Icon(Icons.image_not_supported_outlined,
                                color: _C.sub),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: suppression ? null : () => _supprimerPhoto(img),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: suppression
                                ? const SizedBox(
                                    height: 12,
                                    width: 12,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5, color: Colors.white))
                                : const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoriePicker() {
    if (_loadingCats) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (_erreurCats != null) {
      return Row(
        children: [
          const Expanded(child: Text('Catégories indisponibles')),
          TextButton(onPressed: _chargerCategories, child: const Text('Réessayer')),
        ],
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _categorieId,
      isExpanded: true,
      decoration: _decoration('Catégorie'),
      items: _categories
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom)))
          .toList(),
      onChanged: (v) => setState(() => _categorieId = v),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: _C.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.green),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.border),
        ),
      );

  Widget _input(TextEditingController c, String hint,
      {TextInputType? keyboard,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: _decoration(hint),
    );
  }
}
