import 'package:ecommerce_flutter/src/data/dataSource/remote/services/LegalService.dart';
import 'package:ecommerce_flutter/src/domain/models/LegalContent.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

class LegalPage extends StatefulWidget {
  const LegalPage({super.key});

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  late Future<Resource<LegalContent>> _future;
  late String _type;
  late String _title;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _type = args?['type'] as String? ?? 'privacy';
    _title = args?['title'] as String? ?? 'Política de Privacidad';
    _future = LegalService().fetch(_type);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(_title, style: TextStyle(color: cs.onBackground, fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<Resource<LegalContent>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data is Loading) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }
          final resource = snapshot.data!;
          if (resource is Error<LegalContent>) {
            return Center(
              child: Text('No se pudo cargar el contenido',
                  style: TextStyle(color: tokens.textMuted)),
            );
          }
          final content = (resource as Success<LegalContent>).data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(content, cs, tokens),
              ...content.sections.map((s) => _buildSection(s, cs, tokens)),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(LegalContent content, ColorScheme cs, AppTokens tokens) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.company,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.onBackground),
          ),
          const SizedBox(height: 4),
          Text('Última actualización: ${content.updatedAt}',
              style: TextStyle(color: tokens.textMuted, fontSize: 13)),
          const SizedBox(height: 4),
          Text(content.email,
              style: TextStyle(color: tokens.textMuted, fontSize: 13)),
          if (content.whatsapp != null) ...[
            const SizedBox(height: 4),
            Text(content.whatsapp!,
                style: TextStyle(color: tokens.textMuted, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(LegalSection section, ColorScheme cs, AppTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: cs.outline)),
          ),
          child: Text(
            section.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onBackground,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (section.note != null) _buildNoteBox(section.note!, cs),
        ..._buildParagraphs(section.paragraphs, tokens),
        ..._buildItems(section.items, tokens),
        ...section.subsections.map((sub) => _buildSubsection(sub, cs, tokens)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSubsection(LegalSubsection sub, ColorScheme cs, AppTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            sub.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: cs.onBackground,
            ),
          ),
        ),
        if (sub.note != null) _buildNoteBox(sub.note!, cs),
        ..._buildParagraphs(sub.paragraphs, tokens),
        ..._buildItems(sub.items, tokens),
      ],
    );
  }

  Widget _buildNoteBox(String note, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.06),
        border: Border(left: BorderSide(color: cs.primary, width: 4)),
      ),
      child: Text(note, style: TextStyle(color: cs.onBackground, fontSize: 13)),
    );
  }

  List<Widget> _buildParagraphs(List<String> paragraphs, AppTokens tokens) {
    return paragraphs
        .map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(p, style: TextStyle(color: tokens.textMuted, fontSize: 13, height: 1.5)),
          ),
        )
        .toList();
  }

  List<Widget> _buildItems(List<String> items, AppTokens tokens) {
    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 14, color: tokens.textMuted)),
                Expanded(child: Text(item, style: TextStyle(color: tokens.textMuted, fontSize: 13, height: 1.5))),
              ],
            ),
          ),
        )
        .toList();
  }
}
