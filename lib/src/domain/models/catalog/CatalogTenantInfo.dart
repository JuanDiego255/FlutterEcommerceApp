import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';

class CatalogTenantInfo {
  final String title;
  final String? logo;
  final String? logoIco;
  final String? whatsapp;
  final String? email;
  final String? footer;
  final String? aboutUs;
  final bool cintillo;
  final String? textCintillo;
  final bool manageDepartment;

  const CatalogTenantInfo({
    required this.title,
    this.logo,
    this.logoIco,
    this.whatsapp,
    this.email,
    this.footer,
    this.aboutUs,
    required this.cintillo,
    this.textCintillo,
    required this.manageDepartment,
  });

  String get logoUrl {
    if (logo == null || logo!.isEmpty) return '';
    return 'https://${TenantSession.host}/file/$logo';
  }

  String get whatsappUrl {
    if (whatsapp == null || whatsapp!.isEmpty) return '';
    final clean = whatsapp!.replaceAll(RegExp(r'[^\d+]'), '');
    return 'https://wa.me/$clean';
  }

  factory CatalogTenantInfo.fromJson(Map<String, dynamic> j) => CatalogTenantInfo(
        title: j['title']?.toString() ?? '',
        logo: j['logo']?.toString(),
        logoIco: j['logo_ico']?.toString(),
        whatsapp: j['whatsapp']?.toString(),
        email: j['email']?.toString(),
        footer: j['footer']?.toString(),
        aboutUs: j['about_us']?.toString(),
        cintillo: j['cintillo'] == true || j['cintillo'] == 1,
        textCintillo: j['text_cintillo']?.toString(),
        manageDepartment: j['manage_department'] == 1 || j['manage_department'] == true,
      );
}
