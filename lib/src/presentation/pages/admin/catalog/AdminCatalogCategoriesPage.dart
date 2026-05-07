import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/catalog/AdminCatalogProductsPage.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AdminCatalogCategoriesPage extends StatefulWidget {
  final int deptId;
  final String deptName;

  const AdminCatalogCategoriesPage({
    super.key,
    required this.deptId,
    required this.deptName,
  });

  @override
  State<AdminCatalogCategoriesPage> createState() =>
      _AdminCatalogCategoriesPageState();
}

class _AdminCatalogCategoriesPageState
    extends State<AdminCatalogCategoriesPage> {
  final _api = MitaiApiService();

  bool _loading = true;
  String? _error;
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
    final result = await _api.getCategoriesByDepartment(widget.deptId);
    if (!mounted) return;
    if (result is Success<List<dynamic>>) {
      setState(() {
        _categories = result.data;
        _loading = false;
      });
    } else if (result is Error<List<dynamic>>) {
      setState(() {
        _error = result.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.deptName,
          style: TextStyle(
            color: cs.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _buildBody(cs, tokens),
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
    if (_categories.isEmpty) {
      return Center(
        child: Text('No hay categorías en este departamento',
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
          return _CatalogCategoryCard(
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

class _CatalogCategoryCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  const _CatalogCategoryCard({
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
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
