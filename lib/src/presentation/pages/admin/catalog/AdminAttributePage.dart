import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/AttributeType.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

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
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? cs.error : cs.primary,
    ));
  }

  Future<void> _createAttrDialog() async {
    final cs = Theme.of(context).colorScheme;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Nuevo tipo de atributo',
            style: TextStyle(color: cs.onBackground, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: cs.onBackground),
          decoration: const InputDecoration(labelText: 'Nombre (ej: Talla, Color)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Crear'),
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
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Eliminar "${attr.name}"',
            style: TextStyle(color: cs.onBackground, fontWeight: FontWeight.w700)),
        content: Text('Se eliminarán también los ${attr.values.length} valores. ¿Continuar?',
            style: TextStyle(color: tokens.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
            child: const Text('Eliminar'),
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
    final cs = Theme.of(context).colorScheme;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Agregar valor a "${attr.name}"',
            style: TextStyle(color: cs.onBackground, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: cs.onBackground),
          decoration: const InputDecoration(labelText: 'Valor (ej: S, M, L, Rojo)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Agregar'),
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
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text('Gestión de atributos',
            style: TextStyle(color: cs.onBackground, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAttrDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo tipo'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _attributes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.label_outline, size: 64, color: tokens.textSubtle),
                      const SizedBox(height: 16),
                      Text('Sin tipos de atributo', style: TextStyle(color: tokens.textMuted)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _createAttrDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear primero'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: cs.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _attributes.length,
                    itemBuilder: (ctx, i) => _buildAttrCard(i, cs, tokens),
                  ),
                ),
    );
  }

  Widget _buildAttrCard(int index, ColorScheme cs, AppTokens tokens) {
    final attr = _attributes[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Row(
            children: [
              Expanded(child: Text(attr.name,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: cs.onBackground))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${attr.values.length} valores',
                    style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: cs.primary, size: 22),
                tooltip: 'Agregar valor',
                onPressed: () => _createValueDialog(attr, index),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: cs.error, size: 22),
                tooltip: 'Eliminar tipo',
                onPressed: () => _deleteAttr(attr, index),
              ),
            ],
          ),
          children: [
            Divider(height: 1, indent: 16, endIndent: 16, color: cs.outline),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: attr.values.isEmpty
                  ? Text('Sin valores. Toca + para agregar.',
                      style: TextStyle(color: tokens.textMuted, fontSize: 13))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: attr.values.asMap().entries.map((e) {
                        final vi  = e.key;
                        final val = e.value;
                        return Chip(
                          label: Text(val.value,
                              style: TextStyle(fontSize: 12, color: cs.onBackground)),
                          backgroundColor: tokens.surfaceAlt,
                          deleteIcon: Icon(Icons.close, size: 14, color: cs.error),
                          onDeleted: () => _deleteValue(attr, index, val, vi),
                          side: BorderSide(color: cs.outline),
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
