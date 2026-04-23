import 'dart:convert';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/TenantConfig.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/login/bloc/LoginBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/login/bloc/LoginEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/login/bloc/LoginState.dart';
import 'package:ecommerce_flutter/src/presentation/utils/BlocFormItem.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const Color _kPrimary = Color(0xFF8B6F47);
const Color _kAccent = Color(0xFFC8966A);
const Color _kBg = Color(0xFFFAF8F5);

class LoginContent extends StatefulWidget {
  final LoginBloc? bloc;
  final LoginState state;

  const LoginContent(this.bloc, this.state, {super.key});

  @override
  State<LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends State<LoginContent> {
  // ─── Server-config step ───────────────────────────────────────────────────
  late bool _showServerConfig;
  final _serverFormKey = GlobalKey<FormState>();
  late final TextEditingController _domainCtrl;
  final TextEditingController _tokenCtrl = TextEditingController();
  bool _tokenVisible = false;
  bool _savingServer = false;
  String? _serverError;

  // ─── Credential step ──────────────────────────────────────────────────────
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _showServerConfig = !TenantSession.isConfigured;
    _domainCtrl = TextEditingController(text: TenantSession.host);
  }

  @override
  void dispose() {
    _domainCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  // ─── Save server config with token validation ─────────────────────────────

  Future<void> _saveServer() async {
    if (!_serverFormKey.currentState!.validate()) return;
    setState(() {
      _savingServer = true;
      _serverError = null;
    });

    final raw = _domainCtrl.text.trim();
    final domain = raw
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/$'), '');
    final token = _tokenCtrl.text.trim();

    // Validate token against the server before saving anything.
    try {
      final response = await http
          .get(
            Uri.https(domain, '/api/app/ping'),
            headers: {'X-App-Token': token, 'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        final msg = body['message'] as String? ?? 'Token inválido o servidor incorrecto';
        setState(() {
          _savingServer = false;
          _serverError = msg;
        });
        return;
      }
    } catch (_) {
      setState(() {
        _savingServer = false;
        _serverError = 'No se pudo conectar al servidor. Verificá el dominio.';
      });
      return;
    }

    // Token validated — persist and proceed to credential step.
    await TenantSession.save(TenantConfig(
      domain: domain,
      appToken: token,
    ));

    if (!mounted) return;
    setState(() {
      _savingServer = false;
      _showServerConfig = false;
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _header(context),
              _showServerConfig ? _serverConfigCard() : _credentialCard(context),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _header(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Container(
      height: h * 0.34,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, size: 42, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            TenantSession.isConfigured ? TenantSession.host : 'Admin',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _showServerConfig ? 'Configurar servidor' : 'Panel de administración',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Server config card ───────────────────────────────────────────────────

  Widget _serverConfigCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Form(
        key: _serverFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dns_outlined, size: 18, color: _kPrimary),
                const SizedBox(width: 8),
                const Text(
                  'Conectar servidor',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ingresá el dominio y el token de acceso generado desde el panel web.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Domain
            TextFormField(
              controller: _domainCtrl,
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresá el dominio';
                final d = v.trim().replaceAll(RegExp(r'^https?://'), '');
                if (!d.contains('.')) return 'Dominio inválido (ej: ejemplo.com)';
                return null;
              },
              style: const TextStyle(fontSize: 14),
              decoration: _inputDecoration('Dominio del tenant', Icons.language_outlined)
                  .copyWith(hintText: 'ejemplo.com'),
            ),
            const SizedBox(height: 14),

            // App token
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

            if (_serverError != null) ...[
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
                        _serverError!,
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
                onPressed: _savingServer ? null : _saveServer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _savingServer
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : const Icon(Icons.link_rounded, size: 18),
                label: Text(
                  _savingServer ? 'Verificando...' : 'Conectar',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            if (TenantSession.isConfigured) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _showServerConfig = false),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            _privacyLink(),
          ],
        ),
      ),
    );
  }

  // ─── Credential card ──────────────────────────────────────────────────────

  Widget _credentialCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kPrimary.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.dns_outlined, size: 15, color: _kPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    TenantSession.host,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _domainCtrl.text = TenantSession.host;
                    _tokenCtrl.clear();
                    setState(() {
                      _showServerConfig = true;
                      _serverError = null;
                    });
                  },
                  child: Text(
                    'Cambiar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Bienvenido',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 4),
          Text('Ingresá tus credenciales para continuar',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 24),

          Form(
            key: _formKey,
            child: Column(
              children: [
                _emailField(),
                const SizedBox(height: 14),
                _passwordField(),
                const SizedBox(height: 28),
                _loginButton(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _privacyLink(),
        ],
      ),
    );
  }

  // ─── Form fields ──────────────────────────────────────────────────────────

  Widget _emailField() {
    return TextFormField(
      keyboardType: TextInputType.emailAddress,
      onChanged: (v) =>
          widget.bloc?.add(EmailChanged(email: BlocFormItem(value: v))),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Ingresá el correo' : null,
      style: const TextStyle(fontSize: 14),
      decoration: _inputDecoration('Correo electrónico', Icons.email_outlined),
    );
  }

  Widget _passwordField() {
    return TextFormField(
      obscureText: _obscurePassword,
      onChanged: (v) =>
          widget.bloc?.add(PasswordChanged(password: BlocFormItem(value: v))),
      validator: (v) =>
          (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
      style: const TextStyle(fontSize: 14),
      decoration: _inputDecoration('Contraseña', Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey[500],
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  Widget _loginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            widget.bloc?.add(LoginSubmit());
          } else {
            Fluttertoast.showToast(
                msg: 'Completá todos los campos',
                toastLength: Toast.LENGTH_SHORT);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'Iniciar sesión',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
    );
  }

  // ─── Privacy policy link ──────────────────────────────────────────────────

  Widget _privacyLink() {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final host = TenantSession.isConfigured
              ? TenantSession.host
              : _domainCtrl.text
                  .trim()
                  .replaceAll(RegExp(r'^https?://'), '')
                  .replaceAll(RegExp(r'/$'), '');
          if (host.isEmpty) return;
          final uri = Uri.https(host, '/privacy-policy');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Text(
          'Política de privacidad',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  // ─── Shared decoration ────────────────────────────────────────────────────

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
