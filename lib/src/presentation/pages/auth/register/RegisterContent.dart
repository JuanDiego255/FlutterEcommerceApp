import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/register/bloc/RegisterBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/register/bloc/RegisterEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/register/bloc/RegisterState.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:ecommerce_flutter/src/presentation/utils/BlocFormItem.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RegisterContent extends StatefulWidget {
  final RegisterBloc? bloc;
  final RegisterState state;

  const RegisterContent(this.bloc, this.state, {super.key});

  @override
  State<RegisterContent> createState() => _RegisterContentState();
}

class _RegisterContentState extends State<RegisterContent> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _header(context),
              _formCard(context),
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
      height: h * 0.28,
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_add_rounded, size: 36, color: cs.onPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            TenantSession.isConfigured ? TenantSession.host : 'Tienda',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Crear una cuenta',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Form card ────────────────────────────────────────────────────────────

  Widget _formCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Form(
        key: widget.state.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registro',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onBackground),
            ),
            const SizedBox(height: 4),
            Text(
              'Completá tus datos para crear tu cuenta',
              style: TextStyle(fontSize: 13, color: tokens.textMuted),
            ),
            const SizedBox(height: 24),

            _field(
              label: 'Nombre',
              icon: Icons.person_outline,
              onChanged: (v) => widget.bloc?.add(RegisterNameChanged(name: BlocFormItem(value: v))),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Campo requerido' : null,
            ),
            _field(
              label: 'Apellido',
              icon: Icons.person_outline,
              onChanged: (v) => widget.bloc?.add(RegisterLastnameChanged(lastname: BlocFormItem(value: v))),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Campo requerido' : null,
            ),
            _field(
              label: 'Correo electrónico',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => widget.bloc?.add(RegisterEmailChanged(email: BlocFormItem(value: v))),
              validator: (v) {
                if (v?.trim().isEmpty ?? true) return 'Campo requerido';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v!)) return 'Correo inválido';
                return null;
              },
            ),
            _field(
              label: 'Teléfono',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              onChanged: (v) => widget.bloc?.add(RegisterPhoneChanged(phone: BlocFormItem(value: v))),
            ),
            _field(
              label: 'Contraseña',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              onChanged: (v) => widget.bloc?.add(RegisterPasswordChanged(password: BlocFormItem(value: v))),
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Theme.of(context).extension<AppTokens>()!.textMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            _field(
              label: 'Confirmar contraseña',
              icon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              onChanged: (v) => widget.bloc?.add(RegisterConfirmPasswordChanged(confirmPassword: BlocFormItem(value: v))),
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Theme.of(context).extension<AppTokens>()!.textMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.state.formKey!.currentState!.validate()) {
                    widget.bloc?.add(RegisterFormSubmit());
                  } else {
                    Fluttertoast.showToast(
                      msg: 'El formulario no es válido',
                      toastLength: Toast.LENGTH_LONG,
                    );
                  }
                },
                child: const Text(
                  'Crear cuenta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('¿Ya tenés cuenta? ', style: TextStyle(fontSize: 13, color: tokens.textMuted)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, 'login'),
                    child: Text(
                      'Iniciá sesión',
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
            ),
          ],
        ),
      ),
    );
  }

  // ─── Field helper ─────────────────────────────────────────────────────────

  Widget _field({
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
        style: TextStyle(fontSize: 14, color: cs.onBackground),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: tokens.textMuted, size: 20),
          labelStyle: TextStyle(color: tokens.textMuted, fontSize: 13),
          suffixIcon: suffixIcon,
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
        ),
      ),
    );
  }
}
