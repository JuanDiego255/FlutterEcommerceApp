import 'dart:io';

import 'package:ecommerce_flutter/injection.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/CartNotifier.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/OrdersService.dart';
import 'package:ecommerce_flutter/src/domain/models/AuthResponse.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/ShoppingBagUseCases.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GuestCheckoutPage extends StatefulWidget {
  const GuestCheckoutPage({super.key});

  @override
  State<GuestCheckoutPage> createState() => _GuestCheckoutPageState();
}

class _GuestCheckoutPageState extends State<GuestCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl       = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _countryCtrl    = TextEditingController(text: 'Costa Rica');
  final _provinceCtrl   = TextEditingController();
  final _cityCtrl       = TextEditingController();
  final _districtCtrl   = TextEditingController();
  final _addressCtrl    = TextEditingController();
  final _postalCtrl     = TextEditingController();

  List<Product> _products = [];
  double _total = 0;
  bool _loading = false;
  bool _submitting = false;
  XFile? _proofImage;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _countryCtrl.dispose();
    _provinceCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _addressCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final products = await locator<ShoppingBagUseCases>().getProducts.run();
    final total    = await locator<ShoppingBagUseCases>().getTotal.run();

    final AuthResponse? session = await locator<AuthUseCases>().getUserSession.run();
    if (session != null) {
      _nameCtrl.text  = '${session.user.name ?? ''} ${session.user.lastname ?? ''}'.trim();
      _emailCtrl.text = session.user.email ?? '';
      _phoneCtrl.text = session.user.phone ?? '';
    }

    if (mounted) {
      setState(() {
        _products   = products;
        _total      = total;
        _loading    = false;
        _isLoggedIn = session != null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_products.isEmpty) {
      _showError('El carrito está vacío');
      return;
    }
    if (_proofImage == null) {
      _showError('Adjuntá el comprobante de pago antes de confirmar');
      return;
    }

    setState(() => _submitting = true);
    final result = await OrdersService().guestOrder(
      name:        _nameCtrl.text.trim(),
      email:       _emailCtrl.text.trim(),
      telephone:   _phoneCtrl.text.trim(),
      country:     _countryCtrl.text.trim().isEmpty ? 'Costa Rica' : _countryCtrl.text.trim(),
      province:    _provinceCtrl.text.trim(),
      city:        _cityCtrl.text.trim(),
      addressTwo:  _districtCtrl.text.trim(),
      address:     _addressCtrl.text.trim(),
      postalCode:  _postalCtrl.text.trim(),
      products:    _products,
      proofImage:  _proofImage,
    );
    setState(() => _submitting = false);

    if (!mounted) return;
    if (result is Success) {
      for (final p in _products) {
        await locator<ShoppingBagUseCases>().deleteItem.run(p);
      }
      CartNotifier.instance.update(0);

      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      final tokens = Theme.of(context).extension<AppTokens>()!;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: tokens.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: tokens.success, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                '¡Pedido recibido!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onBackground),
              ),
              const SizedBox(height: 8),
              Text(
                'Revisá tu correo (${_emailCtrl.text.trim()}) para los detalles de tu pedido.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: tokens.textMuted),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(context, 'catalog/home', (route) => false);
                },
                child: const Text('Ir al catálogo'),
              ),
            ),
          ],
        ),
      );
    } else if (result is Error) {
      _showError((result as Error).message);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _proofImage = picked);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cs.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Formulario de compra',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onBackground),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _buildForm(),
      bottomNavigationBar: _products.isNotEmpty ? _buildBottomBar() : null,
    );
  }

  Widget _buildForm() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Datos de contacto'),
            const SizedBox(height: 12),
            _field(controller: _nameCtrl, label: 'Nombre completo', icon: Icons.person_outline,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Campo requerido' : null),
            _field(controller: _emailCtrl, label: 'Correo electrónico', icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'Campo requerido';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v!)) return 'Correo inválido';
                  return null;
                }),
            _field(controller: _phoneCtrl, label: 'Teléfono (WhatsApp)', icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Campo requerido' : null),
            const SizedBox(height: 20),
            _sectionTitle('Dirección de entrega'),
            const SizedBox(height: 12),
            _field(controller: _countryCtrl, label: 'País', icon: Icons.flag_outlined, readOnly: true),
            _field(controller: _provinceCtrl, label: 'Provincia', icon: Icons.location_city_outlined,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Campo requerido' : null),
            _field(controller: _cityCtrl, label: 'Cantón', icon: Icons.map_outlined,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Campo requerido' : null),
            _field(controller: _districtCtrl, label: 'Distrito', icon: Icons.place_outlined),
            _field(controller: _addressCtrl, label: 'Dirección exacta', icon: Icons.home_outlined,
                maxLines: 2,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Campo requerido' : null),
            _field(controller: _postalCtrl, label: 'Código postal', icon: Icons.markunread_mailbox_outlined,
                keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            _sectionTitle('Resumen del pedido'),
            const SizedBox(height: 12),
            _buildOrderSummary(),
            const SizedBox(height: 20),
            _sectionTitle('Comprobante de pago'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: cs.primary.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Realizá una transferencia bancaria o SINPE Móvil y adjuntá el comprobante aquí. Requerido para completar el pedido.',
                      style: TextStyle(fontSize: 12, color: cs.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildProofUpload(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onBackground),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(fontSize: 14, color: cs.onBackground),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13, color: tokens.textMuted),
          prefixIcon: Icon(icon, size: 18, color: tokens.textMuted),
          filled: true,
          fillColor: readOnly ? tokens.surfaceAlt : cs.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: cs.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: cs.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: cs.primary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: cs.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: cs.error),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          ..._products.map((p) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onBackground)),
                      if (p.selectedVariant != null)
                        Text(p.selectedVariant!,
                            style: TextStyle(fontSize: 11, color: tokens.textMuted)),
                    ],
                  ),
                ),
                Text('x${p.quantity ?? 1}', style: TextStyle(fontSize: 12, color: tokens.textMuted)),
                const SizedBox(width: 8),
                Text(
                  '₡${fmtPrice(p.effectivePrice * (p.quantity ?? 1))}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
                ),
              ],
            ),
          )),
          Divider(height: 1, color: cs.outline),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onBackground)),
                Text(
                  '₡${fmtPrice(_total)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofUpload() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: _proofImage == null ? 100 : null,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: _proofImage != null ? cs.primary : cs.outline,
            width: _proofImage != null ? 1.5 : 1,
          ),
        ),
        child: _proofImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file_outlined, size: 28, color: tokens.textSubtle),
                  const SizedBox(height: 6),
                  Text(
                    'Toca para adjuntar comprobante',
                    style: TextStyle(fontSize: 12, color: tokens.textMuted),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md - 1),
                    child: Image.file(
                      File(_proofImage!.path),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _proofImage = null),
                      child: Container(
                        width: 28, height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: cs.background,
          border: Border(top: BorderSide(color: cs.outline)),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                )
              : const Icon(Icons.check_circle_outline, size: 20),
          label: Text(
            _submitting ? 'Enviando...' : 'Confirmar pedido',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
