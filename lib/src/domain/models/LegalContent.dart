class LegalSubsection {
  final String title;
  final List<String> paragraphs;
  final List<String> items;
  final String? note;

  const LegalSubsection({required this.title, required this.paragraphs, required this.items, this.note});

  factory LegalSubsection.fromJson(Map<String, dynamic> j) => LegalSubsection(
    title: j['title'] as String? ?? '',
    paragraphs: (j['paragraphs'] as List?)?.map((e) => e.toString()).toList() ?? [],
    items: (j['items'] as List?)?.map((e) => e.toString()).toList() ?? [],
    note: j['note'] as String?,
  );
}

class LegalSection {
  final String title;
  final List<String> paragraphs;
  final List<String> items;
  final String? note;
  final List<LegalSubsection> subsections;

  const LegalSection({required this.title, required this.paragraphs, required this.items, this.note, required this.subsections});

  factory LegalSection.fromJson(Map<String, dynamic> j) => LegalSection(
    title: j['title'] as String? ?? '',
    paragraphs: (j['paragraphs'] as List?)?.map((e) => e.toString()).toList() ?? [],
    items: (j['items'] as List?)?.map((e) => e.toString()).toList() ?? [],
    note: j['note'] as String?,
    subsections: (j['subsections'] as List?)?.map((e) => LegalSubsection.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );
}

class LegalContent {
  final String company;
  final String email;
  final String? whatsapp;
  final String updatedAt;
  final List<LegalSection> sections;

  const LegalContent({required this.company, required this.email, this.whatsapp, required this.updatedAt, required this.sections});

  factory LegalContent.fromJson(Map<String, dynamic> j) => LegalContent(
    company: j['company'] as String? ?? 'Safewor Solutions',
    email: j['email'] as String? ?? '',
    whatsapp: j['whatsapp'] as String?,
    updatedAt: j['updated_at'] as String? ?? '',
    sections: (j['sections'] as List?)?.map((e) => LegalSection.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );
}
