import 'package:ecommerce_flutter/src/domain/models/User.dart';
import 'package:flutter/material.dart';

const _kAccent  = Color(0xFF8B6F47);
const _kPrimary = Color(0xFF2D2D2D);
const _kSub     = Color(0xFF757575);
const _kBg      = Color(0xFFFAFAFA);

class ProfileInfoContent extends StatelessWidget {
  final User? user;
  const ProfileInfoContent(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildInfoCard(context),
            const SizedBox(height: 16),
            _buildActionsCard(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6B4F30), _kAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            children: [
              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x30000000),
                            blurRadius: 12,
                            offset: Offset(0, 4)),
                      ],
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
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 14, color: _kAccent),
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
              // Role badge
              if (user?.roles?.isNotEmpty ?? false)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4)),
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

  Widget _buildInfoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            _buildInfoTile(
              Icons.person_outline,
              'Nombre completo',
              '${user?.name ?? ''} ${user?.lastname ?? ''}'.trim().isNotEmpty
                  ? '${user?.name ?? ''} ${user?.lastname ?? ''}'.trim()
                  : 'No especificado',
            ),
            const Divider(color: Color(0xFFEEEEEE), height: 1, indent: 16, endIndent: 16),
            _buildInfoTile(
              Icons.email_outlined,
              'Correo electrónico',
              user?.email?.isNotEmpty ?? false ? user!.email! : 'No especificado',
            ),
            const Divider(color: Color(0xFFEEEEEE), height: 1, indent: 16, endIndent: 16),
            _buildInfoTile(
              Icons.phone_outlined,
              'Teléfono',
              user?.phone.isNotEmpty ?? false ? user!.phone : 'No especificado',
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kAccent),
                    foregroundColor: _kAccent,
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

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _kAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _kAccent, size: 18),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 11, color: _kSub),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
            fontSize: 14, color: _kPrimary, fontWeight: FontWeight.w500),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            _buildActionTile(
              context,
              Icons.privacy_tip_outlined,
              'Política de Privacidad',
              onTap: () => Navigator.pushNamed(
                context, 'legal',
                arguments: {'type': 'privacy', 'title': 'Política de Privacidad'},
              ),
            ),
            const Divider(color: Color(0xFFEEEEEE), height: 1, indent: 16, endIndent: 16),
            _buildActionTile(
              context,
              Icons.description_outlined,
              'Términos y Condiciones',
              onTap: () => Navigator.pushNamed(
                context, 'legal',
                arguments: {'type': 'terms', 'title': 'Términos y Condiciones'},
              ),
            ),
            const Divider(color: Color(0xFFEEEEEE), height: 1, indent: 16, endIndent: 16),
            _buildActionTile(
              context,
              Icons.logout,
              'Cerrar sesión',
              color: Colors.red,
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String label, {
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? _kPrimary;
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
      trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFFBDBDBD)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text('¿Estás seguro que querés cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: _kSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate back to catalog
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
