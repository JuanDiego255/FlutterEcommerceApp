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
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const _kAccent  = Color(0xFF8B6F47);
const _kPrimary = Color(0xFF2D2D2D);
const _kBg      = Color(0xFFFAFAFA);
const _kCard    = Colors.white;
const _kDivider = Color(0xFFEEEEEE);
const _kSub     = Color(0xFF757575);

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

    // Pre-fill user data if logged in
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
      // Clear cart after successful order
      for (final p in _products) {
        await locator<ShoppingBagUseCases>().deleteItem.run(p);
      }
      CartNotifier.instance.update(0);

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('¡Pedido recibido!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 8),
              Text(
                'Revisá tu correo (${_emailCtrl.text.trim()}) para los detalles de tu pedido.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _kSub),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    'catalog/home',
                    (route) => false,
                  );
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
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: _kDivider,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Formulario de compra',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kAccent))
          : _buildForm(),
      bottomNavigationBar: _products.isNotEmpty ? _buildBottomBar() : null,
    );
  }

  Widget _buildForm() {
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
            _field(controller: _countryCtrl, label: 'País', icon: Icons.flag_outlined,
                readOnly: true),
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
                color: _kAccent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kAccent.withOpacity(0.25)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: _kAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Realizá una transferencia bancaria o SINPE Móvil y adjuntá el comprobante aquí. Requerido para completar el pedido.',
                      style: TextStyle(fontSize: 12, color: _kAccent),
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

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: _kSub),
          prefixIcon: Icon(icon, size: 18, color: _kSub),
          filled: true,
          fillColor: readOnly ? const Color(0xFFF5F5F5) : _kCard,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kDivider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kDivider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kAccent),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
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
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                      if (p.selectedVariant != null)
                        Text(p.selectedVariant!,
                            style: const TextStyle(fontSize: 11, color: _kSub)),
                    ],
                  ),
                ),
                Text(
                  'x${p.quantity ?? 1}',
                  style: const TextStyle(fontSize: 12, color: _kSub),
                ),
                const SizedBox(width: 8),
                Text(
                  '₡${fmtPrice(p.effectivePrice * (p.quantity ?? 1))}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kAccent),
                ),
              ],
            ),
          )),
          const Divider(height: 1, color: _kDivider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary)),
                Text('₡${fmtPrice(_total)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kAccent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofUpload() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: _proofImage == null ? 100 : null,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _proofImage != null ? _kAccent : _kDivider,
            width: _proofImage != null ? 1.5 : 1,
          ),
        ),
        child: _proofImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file_outlined, size: 28, color: Colors.grey[400]),
                  const SizedBox(height: 6),
                  Text('Toca para adjuntar comprobante',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: _kCard,
          border: Border(top: BorderSide(color: _kDivider)),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
