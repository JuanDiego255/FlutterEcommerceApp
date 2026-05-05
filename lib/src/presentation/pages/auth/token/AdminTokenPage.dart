import 'dart:convert';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/TenantConfig.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color _kPrimary = Color(0xFF8B6F47);
const Color _kAccent  = Color(0xFFC8966A);
const Color _kBg      = Color(0xFFFAF8F5);

class AdminTokenPage extends StatefulWidget {
  const AdminTokenPage({super.key});

  @override
  State<AdminTokenPage> createState() => _AdminTokenPageState();
}

class _AdminTokenPageState extends State<AdminTokenPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenCtrl = TextEditingController();
  bool _tokenVisible = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    final domain = TenantSession.host;
    final token  = _tokenCtrl.text.trim();

    try {
      final response = await http
          .get(
            Uri.https(domain, '/api/app/ping'),
            headers: {'X-App-Token': token, 'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        final msg  = body['message'] as String? ?? 'Token inválido o servidor incorrecto';
        setState(() { _saving = false; _error = msg; });
        return;
      }
    } catch (_) {
      setState(() {
        _saving = false;
        _error  = 'No se pudo conectar. Verificá tu conexión.';
      });
      return;
    }

    await TenantSession.save(TenantConfig(
      domain:   domain,
      appToken: token,
    ));

    if (!mounted) return;
    // If a nextRoute was passed (e.g., 'admin/home' from RolesItem), go there directly.
    // Otherwise fall back to the login screen (original behaviour).
    final args = ModalRoute.of(context)?.settings.arguments;
    final nextRoute = (args is Map) ? (args['nextRoute'] as String?) : null;
    Navigator.pushReplacementNamed(context, nextRoute ?? 'login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Container(
      height: h * 0.30,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B4F30), _kPrimary, _kAccent],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_outlined, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Text(
                  TenantSession.host,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Acceso al panel de administración',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Token de acceso',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ingresá el token generado desde el panel web de esta tienda.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _tokenCtrl,
              obscureText: !_tokenVisible,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresá el token de acceso' : null,
              style: const TextStyle(fontSize: 14),
              decoration: _inputDecoration('Token de acceso', Icons.vpn_key_outlined).copyWith(
                hintText: 'Token generado desde el panel web',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                suffixIcon: IconButton(
                  icon: Icon(
                    _tokenVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  onPressed: () => setState(() => _tokenVisible = !_tokenVisible),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _connect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.link_rounded, size: 18),
                label: Text(
                  _saving ? 'Verificando...' : 'Acceder al panel',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, 'tenant/select'),
                icon: const Icon(Icons.swap_horiz_outlined, size: 16, color: Color(0xFF757575)),
                label: const Text(
                  'Cambiar tienda',
                  style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _kPrimary, size: 20),
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
