import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/Department.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/catalog/AdminAttributePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/catalog/AdminCatalogCategoriesPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/catalog/AdminCatalogProductsPage.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminCatalogPage extends StatefulWidget {
  const AdminCatalogPage({super.key});

  @override
  State<AdminCatalogPage> createState() => _AdminCatalogPageState();
}

class _AdminCatalogPageState extends State<AdminCatalogPage> {
  final _api = MitaiApiService();

  bool _loading = true;
  String? _error;
  String _type = '';
  List<Department> _departments = [];
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _api.getHomeAdmin();
    if (!mounted) return;
    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;
      final type = data['type']?.toString() ?? '';
      if (type == 'departments') {
        final list = data['data'] as List<dynamic>? ?? [];
        setState(() {
          _type = 'departments';
          _departments = Department.fromJsonList(list);
          _loading = false;
        });
      } else {
        final list = data['data'] as List<dynamic>? ?? [];
        setState(() {
          _type = 'categories';
          _categories = list;
          _loading = false;
        });
      }
    } else if (result is Error<Map<String, dynamic>>) {
      setState(() {
        _error = result.message;
        _loading = false;
      });
      _showErrorDialog(result.message);
    }
  }

  void _showErrorDialog(String message) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 24),
            const SizedBox(width: 8),
            Text('Error del servidor', style: TextStyle(color: cs.onBackground)),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 14, color: tokens.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cerrar', style: TextStyle(color: tokens.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _loadData();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _openWebAdmin() {
    final path = _type == 'departments' ? '/departments' : '/categories';
    launchUrl(
      Uri.https(TenantSession.host, path),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Scaffold(
      body: _buildBody(cs, tokens),
      floatingActionButton: !_loading && _error == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'attrs',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminAttributePage()),
                  ),
                  backgroundColor: cs.surface,
                  elevation: 2,
                  mini: true,
                  tooltip: 'Atributos',
                  child: Icon(Icons.label_outline, color: cs.primary, size: 20),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'webAdmin',
                  onPressed: _openWebAdmin,
                  icon: const Icon(Icons.edit),
                  label: const Text('Gestionar'),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildBody(ColorScheme cs, AppTokens tokens) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: cs.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_type == 'departments') {
      return _buildDepartmentsGrid(cs, tokens);
    }
    return _buildCategoriesGrid(cs, tokens);
  }

  Widget _buildDepartmentsGrid(ColorScheme cs, AppTokens tokens) {
    if (_departments.isEmpty) {
      return Center(
        child: Text('No hay departamentos disponibles',
            style: TextStyle(color: tokens.textMuted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: cs.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _departments.length,
        itemBuilder: (context, index) {
          final dept = _departments[index];
          return _DepartmentCard(
            department: dept,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminCatalogCategoriesPage(
                    deptId: dept.id,
                    deptName: dept.name,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoriesGrid(ColorScheme cs, AppTokens tokens) {
    if (_categories.isEmpty) {
      return Center(
        child: Text('No hay categorías disponibles',
            style: TextStyle(color: tokens.textMuted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: cs.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index] as Map<String, dynamic>;
          final catId = cat['id'] as int? ?? 0;
          final catName = cat['name']?.toString() ?? '';
          final catImage = cat['image']?.toString();
          final imageUrl = catImage != null && catImage.isNotEmpty
              ? 'https://${TenantSession.host}/file/$catImage'
              : '';
          return _CategoryCard(
            name: catName,
            imageUrl: imageUrl,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminCatalogProductsPage(
                    categoryId: catId,
                    categoryName: catName,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final Department department;
  final VoidCallback onTap;

  const _DepartmentCard({required this.department, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: department.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: department.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(tokens),
                        errorWidget: (_, __, ___) => _placeholder(tokens),
                      )
                    : _placeholder(tokens),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                department.name,
                style: TextStyle(
                  color: cs.onBackground,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(AppTokens tokens) {
    return Container(
      color: tokens.surfaceAlt,
      child: Center(
        child: Icon(Icons.store, size: 48, color: tokens.textSubtle),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(tokens),
                        errorWidget: (_, __, ___) => _placeholder(tokens),
                      )
                    : _placeholder(tokens),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                name,
                style: TextStyle(
                  color: cs.onBackground,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(AppTokens tokens) {
    return Container(
      color: tokens.surfaceAlt,
      child: Center(
        child: Icon(Icons.category, size: 48, color: tokens.textSubtle),
      ),
    );
  }
}
