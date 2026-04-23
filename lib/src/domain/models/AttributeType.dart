class AttributeValue {
  final int id;
  final String value;

  AttributeValue({required this.id, required this.value});

  factory AttributeValue.fromJson(Map<String, dynamic> j) =>
      AttributeValue(id: j['id'] ?? 0, value: j['value'] ?? '');
}

class AttributeType {
  final int id;
  final String name;
  final int main;
  List<AttributeValue> values;

  AttributeType({
    required this.id,
    required this.name,
    required this.main,
    required this.values,
  });

  factory AttributeType.fromJson(Map<String, dynamic> j) => AttributeType(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        main: j['main'] ?? 0,
        values: (j['values'] as List<dynamic>? ?? [])
            .map((v) => AttributeValue.fromJson(v))
            .toList(),
      );

  static List<AttributeType> fromJsonList(List<dynamic> list) =>
      list.map((e) => AttributeType.fromJson(e)).toList();
}
