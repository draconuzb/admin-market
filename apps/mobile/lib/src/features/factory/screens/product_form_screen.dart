import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/config.dart';
import '../../../core/theme.dart';
import '../../../models/catalog.dart';
import '../../../providers.dart';
import '../../../shared/widgets/async_views.dart';
import '../../catalog/catalog_providers.dart';
import '../factory_providers.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});
  final int? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameUz = TextEditingController();
  final _nameRu = TextEditingController();
  final _nameEn = TextEditingController();
  final _descUz = TextEditingController();
  final _price = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final _minQty = TextEditingController(text: '1');
  final _stock = TextEditingController(text: '0');
  int? _categoryId;
  bool _saving = false;
  bool _initialized = false;
  bool _uploading = false;
  List<String> _images = [];

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      // Prefill from the already-loaded factory products list.
      final products = ref.read(factoryProductsProvider).valueOrNull ?? const <Product>[];
      final p = products.where((e) => e.id == widget.productId).firstOrNull;
      if (p != null) {
        _nameUz.text = p.nameUz;
        _nameRu.text = p.nameRu;
        _nameEn.text = p.nameEn;
        _descUz.text = p.descriptionUz ?? '';
        _price.text = p.price.toString();
        _discount.text = '${p.discountPercent}';
        _minQty.text = '${p.minOrderQty}';
        _stock.text = '${p.stockQty}';
        _categoryId = p.categoryId;
        _images = List.of(p.images);
      }
    }
  }

  Future<void> _addPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref
          .read(factoryRepositoryProvider)
          .uploadImage(widget.productId!, bytes, picked.name);
      setState(() => _images = [..._images, url]);
      ref.invalidate(factoryProductsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _imageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('factory.photos'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final url in _images)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(AppConfig.mediaUrl(url),
                        width: 88, height: 88, fit: BoxFit.cover),
                  ),
                ),
              GestureDetector(
                onTap: _uploading ? null : _addPhoto,
                child: Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    color: AppTheme.fill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.separator),
                  ),
                  child: _uploading
                      ? const Center(
                          child: SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : const Icon(Icons.add_a_photo_outlined,
                          color: AppTheme.accent, size: 28),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    for (final c in [_nameUz, _nameRu, _nameEn, _descUz, _price, _discount, _minQty, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      if (_categoryId == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('factory.field_category'.tr())));
      }
      return;
    }
    setState(() => _saving = true);
    final data = {
      'category_id': _categoryId,
      'name_uz': _nameUz.text.trim(),
      'name_ru': _nameRu.text.trim(),
      'name_en': _nameEn.text.trim(),
      'description_uz': _descUz.text.trim(),
      'price': _price.text.trim(),
      'discount_percent': int.tryParse(_discount.text.trim()) ?? 0,
      'min_order_qty': int.tryParse(_minQty.text.trim()) ?? 1,
      'stock_qty': int.tryParse(_stock.text.trim()) ?? 0,
    };
    try {
      final repo = ref.read(factoryRepositoryProvider);
      if (_isEdit) {
        await repo.update(widget.productId!, data);
      } else {
        await repo.create(data);
      }
      ref.invalidate(factoryProductsProvider);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'factory.edit_product'.tr() : 'factory.add_product'.tr()),
      ),
      body: categories.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (cats) {
          if (!_initialized && _categoryId == null && cats.isNotEmpty && !_isEdit) {
            _categoryId = cats.first.id;
          }
          _initialized = true;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  decoration: InputDecoration(labelText: 'factory.field_category'.tr()),
                  items: [
                    for (final c in cats)
                      DropdownMenuItem(value: c.id, child: Text(c.name(lang))),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 16),
                if (_isEdit) _imageSection(),
                _text(_nameUz, 'auth.company_name'.tr() + ' (UZ)', required: true),
                _text(_nameRu, 'RU', required: true),
                _text(_nameEn, 'EN', required: true),
                _text(_descUz, 'UZ ...', maxLines: 2),
                _text(_price, 'factory.field_price'.tr(), number: true, required: true),
                _text(_discount, 'factory.field_discount'.tr(), number: true),
                _text(_minQty, 'factory.field_min_qty'.tr(), number: true, required: true),
                _text(_stock, 'factory.field_stock'.tr(), number: true, required: true),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('common.save'.tr()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _text(TextEditingController c, String label,
      {bool number = false, bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? '—' : null : null,
      ),
    );
  }
}
