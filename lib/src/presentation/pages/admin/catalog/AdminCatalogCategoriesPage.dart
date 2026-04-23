import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/catalog/AdminCatalogProductsPage.dart';
import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAF8F5);
const Color _kPrimary = Color(0xFF8B6F47);
const Color _kAccent = Color(0xFFC8966A);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kTextPrimary = Color(0xFF1A1A1A);
const Color _kTextSecondary = Color(0xFF6B6B6B);

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
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          widget.deptName,
          style: const TextStyle(
            color: _kTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _kPrimary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
              child: const Text('Reintentar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_categories.isEmpty) {
      return const Center(
        child: Text('No hay categorías en este departamento',
            style: TextStyle(color: _kTextSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
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
                        placeholder: (_, __) => _placeholder(),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                name,
                style: const TextStyle(
                  color: _kTextPrimary,
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

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF0EBE3),
      child: const Center(
        child: Icon(Icons.category, size: 48, color: _kAccent),
      ),
    );
  }
}
