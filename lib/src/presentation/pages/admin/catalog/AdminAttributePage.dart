import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/AttributeType.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:flutter/material.dart';

const Color _kBg      = Color(0xFFFAF8F5);
const Color _kPrimary = Color(0xFF8B6F47);
const Color _kAccent  = Color(0xFFC8966A);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText    = Color(0xFF1A1A1A);
const Color _kSub     = Color(0xFF6B6B6B);

class AdminAttributePage extends StatefulWidget {
  const AdminAttributePage({super.key});

  @override
  State<AdminAttributePage> createState() => _AdminAttributePageState();
}

class _AdminAttributePageState extends State<AdminAttributePage> {
  final _api = MitaiApiService();
  bool _loading = true;
  List<AttributeType> _attributes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _api.getAllAttributes();
    if (!mounted) return;
    if (result is Success<List<AttributeType>>) {
      setState(() { _attributes = result.data; _loading = false; });
    } else {
      setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : _kPrimary,
    ));
  }

  Future<void> _createAttrDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nuevo tipo de atributo'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre (ej: Talla, Color)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
            child: const Text('Crear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    final result = await _api.createAttribute(ctrl.text.trim());
    if (!mounted) return;
    if (result is Success<AttributeType>) {
      setState(() => _attributes.add(result.data));
      _snack('Atributo creado', isError: false);
    } else if (result is Error<AttributeType>) {
      _snack(result.message);
    }
  }

  Future<void> _deleteAttr(AttributeType attr, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar "${attr.name}"'),
        content: Text('Se eliminarán también los ${attr.values.length} valores. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _api.deleteAttribute(attr.id);
    if (!mounted) return;
    if (result is Success<bool>) {
      setState(() => _attributes.removeAt(index));
      _snack('Atributo eliminado', isError: false);
    } else if (result is Error<bool>) {
      _snack(result.message);
    }
  }

  Future<void> _createValueDialog(AttributeType attr, int attrIndex) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Agregar valor a "${attr.name}"'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Valor (ej: S, M, L, Rojo)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    final result = await _api.createAttributeValue(attr.id, ctrl.text.trim());
    if (!mounted) return;
    if (result is Success<AttributeValue>) {
      setState(() => _attributes[attrIndex].values.add(result.data));
      _snack('Valor agregado', isError: false);
    } else if (result is Error<AttributeValue>) {
      _snack(result.message);
    }
  }

  Future<void> _deleteValue(AttributeType attr, int attrIndex, AttributeValue val, int valIndex) async {
    final result = await _api.deleteAttributeValue(val.id);
    if (!mounted) return;
    if (result is Success<bool>) {
      setState(() => _attributes[attrIndex].values.removeAt(valIndex));
      _snack('Valor eliminado', isError: false);
    } else if (result is Error<bool>) {
      _snack(result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Gestión de atributos',
            style: TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _kSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAttrDialog,
        backgroundColor: _kPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo tipo', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _attributes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.label_outline, size: 64, color: _kAccent),
                      const SizedBox(height: 16),
                      const Text('Sin tipos de atributo', style: TextStyle(color: _kSub)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _createAttrDialog,
                        style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Crear primero', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _attributes.length,
                    itemBuilder: (ctx, i) => _buildAttrCard(i),
                  ),
                ),
    );
  }

  Widget _buildAttrCard(int index) {
    final attr = _attributes[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Row(
            children: [
              Expanded(child: Text(attr.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _kText))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${attr.values.length} valores',
                    style: const TextStyle(fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: _kPrimary, size: 22),
                tooltip: 'Agregar valor',
                onPressed: () => _createValueDialog(attr, index),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22),
                tooltip: 'Eliminar tipo',
                onPressed: () => _deleteAttr(attr, index),
              ),
            ],
          ),
          children: [
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: attr.values.isEmpty
                  ? const Text('Sin valores. Toca + para agregar.',
                      style: TextStyle(color: _kSub, fontSize: 13))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: attr.values.asMap().entries.map((e) {
                        final vi  = e.key;
                        final val = e.value;
                        return Chip(
                          label: Text(val.value,
                              style: const TextStyle(fontSize: 12, color: _kText)),
                          backgroundColor: const Color(0xFFF0EBE3),
                          deleteIcon: Icon(Icons.close, size: 14, color: Colors.red.shade400),
                          onDeleted: () => _deleteValue(attr, index, val, vi),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
