import 'package:ecommerce_flutter/src/data/dataSource/remote/services/LegalService.dart';
import 'package:ecommerce_flutter/src/domain/models/LegalContent.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Resource<LegalContent>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data is Loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final resource = snapshot.data!;
          if (resource is Error<LegalContent>) {
            return const Center(child: Text('No se pudo cargar el contenido'));
          }
          final content = (resource as Success<LegalContent>).data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(content),
              ...content.sections.map((s) => _buildSection(s)),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(LegalContent content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.company,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text('Última actualización: ${content.updatedAt}'),
          const SizedBox(height: 4),
          Text(content.email),
          if (content.whatsapp != null) ...[
            const SizedBox(height: 4),
            Text(content.whatsapp!),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(LegalSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFDDDDDD))),
          ),
          child: Text(
            section.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a1a2e),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (section.note != null) _buildNoteBox(section.note!),
        ..._buildParagraphs(section.paragraphs),
        ..._buildItems(section.items),
        ...section.subsections.map((sub) => _buildSubsection(sub)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSubsection(LegalSubsection sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            sub.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
        if (sub.note != null) _buildNoteBox(sub.note!),
        ..._buildParagraphs(sub.paragraphs),
        ..._buildItems(sub.items),
      ],
    );
  }

  Widget _buildNoteBox(String note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F8FF),
        border: Border(left: BorderSide(color: Color(0xFF1877F2), width: 4)),
      ),
      child: Text(note),
    );
  }

  List<Widget> _buildParagraphs(List<String> paragraphs) {
    return paragraphs
        .map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(p),
          ),
        )
        .toList();
  }

  List<Widget> _buildItems(List<String> items) {
    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 14)),
                Expanded(child: Text(item)),
              ],
            ),
          ),
        )
        .toList();
  }
}
