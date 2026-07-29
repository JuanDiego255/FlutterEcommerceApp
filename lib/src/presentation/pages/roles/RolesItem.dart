import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/Role.dart';
import 'package:ecommerce_flutter/src/presentation/utils/TenantRoutes.dart';
import 'package:flutter/material.dart';

class RolesItem extends StatelessWidget {

  Role role;
  RolesItem(this.role);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final isAdmin = role.route.contains('admin');
        // En barbería el destino administrativo es la agenda, no el módulo
        // de e-commerce (TenantRoutes traduce según la vertical).
        final target = TenantRoutes.resolve(role.route);
        if (isAdmin && !TenantSession.hasAdminAccess) {
          // No app token yet — ask for it first, then go straight to target
          Navigator.pushNamedAndRemoveUntil(
            context,
            'admin/token',
            (r) => false,
            arguments: {'nextRoute': target},
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(context, target, (route) => false);
        }
      },
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 10, top: 15),
            height: 150,
            child: FadeInImage(
              image: NetworkImage(role.image),
              fit: BoxFit.contain,
              fadeInDuration: Duration(seconds: 1),
              placeholder: AssetImage('assets/img/no-image.png'),
            ),
          ),
          Text(
            role.name,
            style: TextStyle(
              fontSize: 22,
              color: Colors.black,
              fontWeight: FontWeight.bold
            ),  
          ),
        ],
      ),
    );
  }
}