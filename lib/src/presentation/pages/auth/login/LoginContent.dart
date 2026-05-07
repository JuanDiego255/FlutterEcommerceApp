import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/TenantConfig.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/login/bloc/LoginBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/login/bloc/LoginEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/login/bloc/LoginState.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:ecommerce_flutter/src/presentation/utils/BlocFormItem.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

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
    super.dispose();
  }

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

    await TenantSession.save(TenantConfig(
      domain: domain,
      appToken: TenantSession.appToken,
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: h * 0.34,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bg, const Color(0xFF1C1400), cs.primary],
        ),
        borderRadius: const BorderRadius.only(
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
              color: cs.primary.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.storefront_rounded, size: 42, color: cs.onPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            TenantSession.isConfigured ? TenantSession.host : 'Tienda',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _showServerConfig ? 'Configurar dominio' : 'Iniciá sesión para continuar',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Server config card ───────────────────────────────────────────────────

  Widget _serverConfigCard() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Form(
        key: _serverFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dns_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Conectar tienda',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onBackground),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ingresá el dominio de la tienda para continuar.',
              style: TextStyle(fontSize: 13, color: tokens.textMuted),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _domainCtrl,
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresá el dominio';
                final d = v.trim().replaceAll(RegExp(r'^https?://'), '');
                if (!d.contains('.')) return 'Dominio inválido (ej: ejemplo.com)';
                return null;
              },
              style: TextStyle(fontSize: 14, color: cs.onBackground),
              decoration: _inputDecoration('Dominio de la tienda', Icons.language_outlined)
                  .copyWith(hintText: 'ejemplo.com'),
            ),
            if (_serverError != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: cs.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: cs.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_serverError!, style: TextStyle(fontSize: 12, color: cs.error)),
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
                icon: _savingServer
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                      )
                    : const Icon(Icons.link_rounded, size: 18),
                label: Text(
                  _savingServer ? 'Guardando...' : 'Continuar',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _privacyLink(),
          ],
        ),
      ),
    );
  }

  // ─── Credential card ──────────────────────────────────────────────────────

  Widget _credentialCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: cs.primary.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.dns_outlined, size: 15, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    TenantSession.host,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _domainCtrl.text = TenantSession.host;
                    setState(() {
                      _showServerConfig = true;
                      _serverError = null;
                    });
                  },
                  child: Text(
                    'Cambiar',
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.textMuted,
                      decoration: TextDecoration.underline,
                      decorationColor: tokens.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Bienvenido',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onBackground),
          ),
          const SizedBox(height: 4),
          Text(
            'Ingresá tus credenciales para continuar',
            style: TextStyle(fontSize: 13, color: tokens.textMuted),
          ),
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
          _registerLink(),
          const SizedBox(height: 12),
          _privacyLink(),
        ],
      ),
    );
  }

  // ─── Register link ────────────────────────────────────────────────────────

  Widget _registerLink() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('¿No tenés cuenta? ', style: TextStyle(fontSize: 13, color: tokens.textMuted)),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, 'register'),
            child: Text(
              'Registrate',
              style: TextStyle(
                fontSize: 13,
                color: cs.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Form fields ──────────────────────────────────────────────────────────

  Widget _emailField() {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return TextFormField(
      keyboardType: TextInputType.emailAddress,
      onChanged: (v) => widget.bloc?.add(EmailChanged(email: BlocFormItem(value: v))),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá el correo' : null,
      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onBackground),
      decoration: _inputDecoration('Correo electrónico', Icons.email_outlined),
    );
  }

  Widget _passwordField() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return TextFormField(
      obscureText: _obscurePassword,
      onChanged: (v) => widget.bloc?.add(PasswordChanged(password: BlocFormItem(value: v))),
      validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
      style: TextStyle(fontSize: 14, color: cs.onBackground),
      decoration: _inputDecoration('Contraseña', Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: tokens.textMuted,
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
            Fluttertoast.showToast(msg: 'Completá todos los campos', toastLength: Toast.LENGTH_SHORT);
          }
        },
        child: const Text(
          'Iniciar sesión',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
    );
  }

  // ─── Privacy policy link ──────────────────────────────────────────────────

  Widget _privacyLink() {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Center(
      child: GestureDetector(
        onTap: () async {
          final host = TenantSession.isConfigured
              ? TenantSession.host
              : _domainCtrl.text.trim()
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
            color: tokens.textMuted,
            decoration: TextDecoration.underline,
            decorationColor: tokens.textMuted,
          ),
        ),
      ),
    );
  }

  // ─── Shared decoration ────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String label, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: tokens.textMuted, size: 20),
      labelStyle: TextStyle(color: tokens.textMuted, fontSize: 13),
      filled: true,
      fillColor: cs.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
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
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
    );
  }
}
