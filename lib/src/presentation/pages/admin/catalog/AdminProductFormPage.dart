import 'dart:io';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/AttributeType.dart';
import 'package:ecommerce_flutter/src/domain/models/MitaiProduct.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

const Color _kBg      = Color(0xFFFAF8F5);
const Color _kPrimary = Color(0xFF8B6F47);
const Color _kAccent  = Color(0xFFC8966A);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText    = Color(0xFF1A1A1A);
const Color _kSub     = Color(0xFF6B6B6B);

class _Variant {
  int? combinationId;
  String label;
  List<int> valueIds;
  TextEditingController price;
  TextEditingController stock;

  _Variant({
    this.combinationId,
    required this.label,
    required this.valueIds,
    String? initialPrice,
    String? initialStock,
  })  : price = TextEditingController(text: initialPrice ?? ''),
        stock = TextEditingController(text: initialStock ?? '');

  void dispose() {
    price.dispose();
    stock.dispose();
  }

  Map<String, dynamic> toCombo() => {
        'combination_id': combinationId,
        'values': valueIds,
        'price': double.tryParse(price.text) ?? 0,
        'stock': int.tryParse(stock.text) ?? 0,
      };
}

class AdminProductFormPage extends StatefulWidget {
  final MitaiProduct? product;
  final int? categoryId;

  const AdminProductFormPage({super.key, this.product, this.categoryId});

  @override
  State<AdminProductFormPage> createState() => _AdminProductFormPageState();
}

class _AdminProductFormPageState extends State<AdminProductFormPage> {
  final _api        = MitaiApiService();
  final _formKey    = GlobalKey<FormState>();
  final _picker     = ImagePicker();

  // Text controllers
  final _nameCtrl     = TextEditingController();
  final _codeCtrl     = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _priceCtrl    = TextEditingController();
  final _stockCtrl    = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _keywordsCtrl = TextEditingController();

  bool _manageStock = true;
  bool _trending    = false;
  bool _loading     = true;
  bool _saving      = false;
  bool get _isEdit  => widget.product != null;

  // Loaded reference data
  List<dynamic> _allCategories   = [];
  List<AttributeType> _allAttrs  = [];

  // Selected
  Set<int> _selectedCategoryIds = {};
  List<_Variant> _variants       = [];
  List<File> _newImages          = [];
  List<Map<String, dynamic>> _existingImages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _discountCtrl.dispose();
    _keywordsCtrl.dispose();
    for (final v in _variants) v.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _api.getAllCategories(),
      _api.getAllAttributes(),
      if (_isEdit) _api.getProductForEdit(widget.product!.id!),
    ]);

    if (!mounted) return;

    if (results[0] is Success<List<dynamic>>) {
      _allCategories = (results[0] as Success<List<dynamic>>).data;
    }
    if (results[1] is Success<List<AttributeType>>) {
      _allAttrs = (results[1] as Success<List<AttributeType>>).data;
    }

    if (_isEdit && results.length > 2 && results[2] is Success<Map<String, dynamic>>) {
      final data = (results[2] as Success<Map<String, dynamic>>).data;
      final p    = data['product'] as Map<String, dynamic>? ?? {};
      _nameCtrl.text     = p['name']?.toString() ?? '';
      _codeCtrl.text     = p['code']?.toString() ?? '';
      _descCtrl.text     = (p['description']?.toString() ?? '').replaceAll('&quot;', '"');
      _priceCtrl.text    = p['price']?.toString() ?? '';
      _stockCtrl.text    = p['stock']?.toString() ?? '';
      _discountCtrl.text = p['discount']?.toString() ?? '';
      _keywordsCtrl.text = p['meta_keywords']?.toString() ?? '';
      _manageStock       = p['manage_stock'] == 1;
      _trending          = p['trending'] == 1;
      _selectedCategoryIds = Set<int>.from(
          (data['category_ids'] as List<dynamic>? ?? []).map((e) => e as int));
      _existingImages = List<Map<String, dynamic>>.from(data['images'] ?? []);
      for (final combo in (data['combinations'] as List<dynamic>? ?? [])) {
        final c = combo as Map<String, dynamic>;
        _variants.add(_Variant(
          combinationId: c['combination_id'] as int?,
          label: c['label']?.toString() ?? '',
          valueIds: (c['values'] as List<dynamic>? ?? [])
              .map((v) => (v as Map<String, dynamic>)['value_id'] as int)
              .toList(),
          initialPrice: c['price']?.toString() ?? '0',
          initialStock: c['stock']?.toString() ?? '0',
        ));
      }
    } else if (!_isEdit && widget.categoryId != null) {
      _selectedCategoryIds = {widget.categoryId!};
    }

    setState(() => _loading = false);
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      final current = _existingImages.length + _newImages.length;
      final canAdd  = 4 - current;
      if (canAdd <= 0) {
        _snack('Máximo 4 imágenes permitidas');
        return;
      }
      setState(() {
        _newImages.addAll(picked.take(canAdd).map((x) => File(x.path)));
      });
    }
  }

  void _addVariantFromValue(AttributeType attr, AttributeValue val) {
    final label = '${attr.name}: ${val.value}';
    if (_variants.any((v) => v.valueIds.contains(val.id))) {
      _snack('Ya existe una variante con ese valor');
      return;
    }
    setState(() {
      _variants.add(_Variant(label: label, valueIds: [val.id]));
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants[index].dispose();
      _variants.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryIds.isEmpty) {
      _snack('Seleccioná al menos una categoría');
      return;
    }
    setState(() => _saving = true);

    final combos = _variants.map((v) => v.toCombo()).toList();

    Resource result;
    if (_isEdit) {
      result = await _api.updateProduct(
        id: widget.product!.id!,
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text) ?? 0,
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        manageStock: _manageStock,
        trending: _trending,
        discount: double.tryParse(_discountCtrl.text),
        metaKeywords: _keywordsCtrl.text.trim().isEmpty ? null : _keywordsCtrl.text.trim(),
        categoryIds: _selectedCategoryIds.toList(),
        combos: combos,
        newImages: _newImages,
      );
    } else {
      result = await _api.createProduct(
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text) ?? 0,
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        manageStock: _manageStock,
        trending: _trending,
        discount: double.tryParse(_discountCtrl.text),
        metaKeywords: _keywordsCtrl.text.trim().isEmpty ? null : _keywordsCtrl.text.trim(),
        categoryIds: _selectedCategoryIds.toList(),
        combos: combos,
        images: _newImages,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (result is Success) {
      _snack(_isEdit ? 'Producto actualizado' : 'Producto creado', isError: false);
      Navigator.pop(context, true);
    } else if (result is Error) {
      _snack(result.message);
    }
  }

  void _snack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : _kPrimary,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar producto' : 'Nuevo producto',
            style: const TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _kSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _saving
                  ? const Center(child: SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2)))
                  : TextButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined, color: _kPrimary, size: 20),
                      label: const Text('Guardar', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
                    ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('Categorías', _buildCategories()),
                    _section('Información básica', _buildBasicInfo()),
                    _section('Descripción', _buildDescription()),
                    _section('Precio y stock', _buildPriceStock()),
                    _section('Variantes / Atributos', _buildVariants()),
                    _section('Imágenes (máx. 4)', _buildImages()),
                    _section('Opciones adicionales', _buildExtras()),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: _kSub, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: child,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategories() {
    if (_allCategories.isEmpty) {
      return const Text('Sin categorías disponibles', style: TextStyle(color: _kSub));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _allCategories.map((c) {
        final id   = c['id'] as int? ?? 0;
        final name = c['name']?.toString() ?? '';
        final sel  = _selectedCategoryIds.contains(id);
        return FilterChip(
          label: Text(name, style: TextStyle(
              fontSize: 12, color: sel ? Colors.white : _kText,
              fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
          selected: sel,
          onSelected: (_) => setState(() {
            if (sel) _selectedCategoryIds.remove(id);
            else _selectedCategoryIds.add(id);
          }),
          selectedColor: _kPrimary,
          backgroundColor: const Color(0xFFF0EBE3),
          checkmarkColor: Colors.white,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList(),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      children: [
        _field('Nombre del producto', _nameCtrl, required: true),
        const SizedBox(height: 12),
        _field('Código (SKU)', _codeCtrl, hint: 'Auto-generado si se deja vacío'),
      ],
    );
  }

  Widget _buildDescription() {
    return TextFormField(
      controller: _descCtrl,
      minLines: 3,
      maxLines: 6,
      style: const TextStyle(fontSize: 14, color: _kText),
      decoration: _inputDeco('Descripción del producto', null),
    );
  }

  Widget _buildPriceStock() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _field('Precio (₡)', _priceCtrl,
                keyboardType: TextInputType.number, required: true,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))])),
            const SizedBox(width: 12),
            Expanded(child: _field('Descuento (%)', _discountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Controla stock', style: TextStyle(fontSize: 14, color: _kText)),
                value: _manageStock,
                onChanged: (v) => setState(() => _manageStock = v),
                activeColor: _kPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _field('Stock base', _stockCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          ],
        ),
      ],
    );
  }

  Widget _buildVariants() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_allAttrs.isEmpty)
          const Text('No hay tipos de atributo. Creá uno en Gestión de atributos.',
              style: TextStyle(color: _kSub, fontSize: 13))
        else ...[
          const Text('Seleccioná un valor para agregar variante:',
              style: TextStyle(fontSize: 12, color: _kSub)),
          const SizedBox(height: 10),
          ..._allAttrs.map((attr) => _buildAttrSection(attr)),
        ],
        if (_variants.isNotEmpty) ...[
          const Divider(height: 24),
          const Text('Variantes del producto',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kText)),
          const SizedBox(height: 8),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EDE0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Combinación', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kSub))),
                Expanded(flex: 3, child: Text('Precio (₡)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kSub))),
                Expanded(flex: 3, child: Text('Stock', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kSub))),
                SizedBox(width: 28),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ..._variants.asMap().entries.map((e) => _buildVariantRow(e.key, e.value)),
        ],
      ],
    );
  }

  Widget _buildAttrSection(AttributeType attr) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(attr.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: attr.values.map((val) {
              final alreadyAdded = _variants.any((v) => v.valueIds.contains(val.id));
              return ActionChip(
                label: Text(val.value,
                    style: TextStyle(
                        fontSize: 11,
                        color: alreadyAdded ? _kSub : _kPrimary,
                        fontWeight: FontWeight.w500)),
                avatar: Icon(
                  alreadyAdded ? Icons.check : Icons.add,
                  size: 14,
                  color: alreadyAdded ? _kSub : _kPrimary,
                ),
                backgroundColor: alreadyAdded ? const Color(0xFFF0EBE3) : const Color(0xFFF5EDE0),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onPressed: alreadyAdded ? null : () => _addVariantFromValue(attr, val),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantRow(int index, _Variant v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF0EBE3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(v.label, style: const TextStyle(fontSize: 12, color: _kText))),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: v.price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(), hintText: '0',
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: v.stock,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(), hintText: '0',
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            onPressed: () => _removeVariant(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildImages() {
    final total = _existingImages.length + _newImages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_existingImages.isNotEmpty) ...[
          const Text('Imágenes actuales:', style: TextStyle(fontSize: 12, color: _kSub)),
          const SizedBox(height: 6),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(_existingImages[i]['url']?.toString() ?? '',
                    width: 80, height: 80, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 80, height: 80,
                        color: const Color(0xFFF0EBE3),
                        child: const Icon(Icons.image, color: _kAccent))),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_newImages.isNotEmpty) ...[
          const Text('Nuevas imágenes:', style: TextStyle(fontSize: 12, color: _kSub)),
          const SizedBox(height: 6),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _newImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_newImages[i], width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _newImages.removeAt(i)),
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (total < 4)
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate_outlined, color: _kPrimary),
            label: Text('Agregar imágenes (${4 - total} disponibles)',
                style: const TextStyle(color: _kPrimary, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )
        else
          const Text('Máximo de imágenes alcanzado (4)',
              style: TextStyle(color: _kSub, fontSize: 12)),
      ],
    );
  }

  Widget _buildExtras() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Es tendencia', style: TextStyle(fontSize: 14, color: _kText)),
          subtitle: const Text('Aparece en la sección destacada', style: TextStyle(fontSize: 12, color: _kSub)),
          value: _trending,
          onChanged: (v) => setState(() => _trending = v),
          activeColor: _kPrimary,
        ),
        const Divider(height: 1),
        const SizedBox(height: 12),
        _field('Meta keywords (SEO)', _keywordsCtrl, hint: 'Ej: ropa, mujer, talla M'),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {
    bool required = false,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14, color: _kText),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null : null,
      decoration: _inputDeco(label, hint),
    );
  }

  InputDecoration _inputDeco(String label, String? hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: _kSub, fontSize: 13),
    hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFF8F4F0),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5DDD5))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5DDD5))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
  );
}
