import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/Department.dart';
import 'package:ecommerce_flutter/src/domain/models/MitaiProduct.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/catalog/AdminAttributePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/catalog/AdminCatalogCategoriesPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/catalog/AdminCatalogProductsPage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kBg = Color(0xFFFAF8F5);
const Color kPrimary = Color(0xFF8B6F47);
const Color kAccent = Color(0xFFC8966A);
const Color kSurface = Color(0xFFFFFFFF);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF6B6B6B);

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Error del servidor'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
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
    return Scaffold(
      backgroundColor: kBg,
      body: _buildBody(),
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
                  backgroundColor: Colors.white,
                  elevation: 2,
                  mini: true,
                  tooltip: 'Atributos',
                  child: const Icon(Icons.label_outline, color: kPrimary, size: 20),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'webAdmin',
                  onPressed: _openWebAdmin,
                  backgroundColor: kPrimary,
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('Gestionar', style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimary),
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
              style: const TextStyle(color: kTextSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_type == 'departments') {
      return _buildDepartmentsGrid();
    }
    return _buildCategoriesGrid();
  }

  Widget _buildDepartmentsGrid() {
    if (_departments.isEmpty) {
      return const Center(
        child: Text('No hay departamentos disponibles', style: TextStyle(color: kTextSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: kPrimary,
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

  Widget _buildCategoriesGrid() {
    if (_categories.isEmpty) {
      return const Center(
        child: Text('No hay categorías disponibles', style: TextStyle(color: kTextSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: kPrimary,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kSurface,
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: department.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: department.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                department.name,
                style: const TextStyle(
                  color: kTextPrimary,
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
        child: Icon(Icons.store, size: 48, color: kAccent),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kSurface,
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                name,
                style: const TextStyle(
                  color: kTextPrimary,
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
        child: Icon(Icons.category, size: 48, color: kAccent),
      ),
    );
  }
}
