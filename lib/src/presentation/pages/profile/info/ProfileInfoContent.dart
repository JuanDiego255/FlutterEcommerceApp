import 'package:ecommerce_flutter/src/domain/models/User.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ProfileInfoContent extends StatelessWidget {
  final User? user;
  const ProfileInfoContent(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, cs),
            const SizedBox(height: 16),
            _buildInfoCard(context, cs, tokens),
            const SizedBox(height: 16),
            _buildActionsCard(context, cs, tokens),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.bg, const Color(0xFF1C1400), cs.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipOval(
                      child: user?.image != null && user!.image!.isNotEmpty
                          ? FadeInImage.assetNetwork(
                              placeholder: 'assets/img/user_image.png',
                              image: user!.image!,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 300),
                            )
                          : Image.asset('assets/img/user_image.png',
                              fit: BoxFit.cover),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                        context, 'profile/update',
                        arguments: user),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, size: 14, color: cs.onPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${user?.name ?? ''} ${user?.lastname ?? ''}'.trim().isNotEmpty
                    ? '${user?.name ?? ''} ${user?.lastname ?? ''}'.trim()
                    : 'Mi perfil',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (user?.email?.isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Text(
                  user!.email!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (user?.roles?.isNotEmpty ?? false)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        user!.roles!.first.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ColorScheme cs, AppTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          children: [
            _buildInfoTile(
              Icons.person_outline,
              'Nombre completo',
              '${user?.name ?? ''} ${user?.lastname ?? ''}'.trim().isNotEmpty
                  ? '${user?.name ?? ''} ${user?.lastname ?? ''}'.trim()
                  : 'No especificado',
              cs, tokens,
            ),
            Divider(color: cs.outline, height: 1, indent: 16, endIndent: 16),
            _buildInfoTile(
              Icons.email_outlined,
              'Correo electrónico',
              user?.email?.isNotEmpty ?? false ? user!.email! : 'No especificado',
              cs, tokens,
            ),
            Divider(color: cs.outline, height: 1, indent: 16, endIndent: 16),
            _buildInfoTile(
              Icons.phone_outlined,
              'Teléfono',
              user?.phone.isNotEmpty ?? false ? user!.phone : 'No especificado',
              cs, tokens,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.primary),
                    foregroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar información',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () => Navigator.pushNamed(
                      context, 'profile/update',
                      arguments: user),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value,
      ColorScheme cs, AppTokens tokens) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: cs.primary, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 11, color: tokens.textMuted),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
            fontSize: 14, color: cs.onBackground, fontWeight: FontWeight.w500),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildActionsCard(BuildContext context, ColorScheme cs, AppTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          children: [
            _buildActionTile(
              context,
              Icons.privacy_tip_outlined,
              'Política de Privacidad',
              cs, tokens,
              onTap: () => Navigator.pushNamed(
                context, 'legal',
                arguments: {'type': 'privacy', 'title': 'Política de Privacidad'},
              ),
            ),
            Divider(color: cs.outline, height: 1, indent: 16, endIndent: 16),
            _buildActionTile(
              context,
              Icons.description_outlined,
              'Términos y Condiciones',
              cs, tokens,
              onTap: () => Navigator.pushNamed(
                context, 'legal',
                arguments: {'type': 'terms', 'title': 'Términos y Condiciones'},
              ),
            ),
            Divider(color: cs.outline, height: 1, indent: 16, endIndent: 16),
            _buildActionTile(
              context,
              Icons.logout,
              'Cerrar sesión',
              cs, tokens,
              color: cs.error,
              onTap: () => _confirmLogout(context, cs, tokens),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String label,
    ColorScheme cs,
    AppTokens tokens, {
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? cs.onBackground;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 14, color: c, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, size: 18, color: tokens.textSubtle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
    );
  }

  void _confirmLogout(BuildContext context, ColorScheme cs, AppTokens tokens) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: cs.onBackground)),
        content: Text('¿Estás seguro que querés cerrar sesión?',
            style: TextStyle(color: tokens.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: tokens.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(
                  context, 'catalog/home', (route) => false);
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
