import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/TenantConfig.dart';
import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF2D2D2D);
const _kAccent  = Color(0xFF8B6F47);
const _kBg      = Color(0xFFFAFAFA);
const _kCard    = Colors.white;
const _kSub     = Color(0xFF757575);
const _kDivider = Color(0xFFEEEEEE);

class _Tenant {
  final String name;
  final String subtitle;
  final String domain;
  final IconData icon;
  const _Tenant({
    required this.name,
    required this.subtitle,
    required this.domain,
    required this.icon,
  });
}

const _kTenants = [
  _Tenant(
    name: 'Mitai CR',
    subtitle: 'Ropa y accesorios para bebé',
    domain: 'mitaicr.com',
    icon: Icons.child_care_outlined,
  ),
  _Tenant(
    name: 'Solo Ciclismo',
    subtitle: 'Equipos y accesorios de ciclismo',
    domain: 'solociclismocrc.safeworsolutions.com',
    icon: Icons.directions_bike_outlined,
  ),
  _Tenant(
    name: 'Mueblería Sarchi',
    subtitle: 'Muebles y decoración artesanal',
    domain: 'muebleriasarchi.com',
    icon: Icons.chair_outlined,
  ),
];

class TenantSelectPage extends StatefulWidget {
  const TenantSelectPage({super.key});

  @override
  State<TenantSelectPage> createState() => _TenantSelectPageState();
}

class _TenantSelectPageState extends State<TenantSelectPage> {
  int? _loadingIndex;

  Future<void> _select(int index, _Tenant tenant) async {
    setState(() => _loadingIndex = index);
    await TenantSession.save(TenantConfig(domain: tenant.domain));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'catalog/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  for (int i = 0; i < _kTenants.length; i++) ...[
                    _TenantCard(
                      tenant: _kTenants[i],
                      isLoading: _loadingIndex == i,
                      onTap: _loadingIndex != null ? null : () => _select(i, _kTenants[i]),
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B4F30), _kAccent],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bienvenido',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Seleccioná la tienda que querés explorar',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  final _Tenant tenant;
  final bool isLoading;
  final VoidCallback? onTap;

  const _TenantCard({
    required this.tenant,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null && !isLoading ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(color: _kDivider, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(tenant.icon, color: _kAccent, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tenant.subtitle,
                      style: const TextStyle(fontSize: 12, color: _kSub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(_kAccent),
                  ),
                )
              else
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _kSub),
            ],
          ),
        ),
      ),
    );
  }
}
