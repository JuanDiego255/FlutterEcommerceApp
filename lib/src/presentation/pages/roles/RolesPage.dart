import 'package:ecommerce_flutter/src/domain/models/Role.dart';
import 'package:ecommerce_flutter/src/presentation/pages/roles/RolesItem.dart';
import 'package:ecommerce_flutter/src/presentation/pages/roles/bloc/RolesBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/roles/bloc/RolesEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/roles/bloc/RolesState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RolesPage extends StatefulWidget {
  const RolesPage({super.key});

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  @override
  void initState() {
    super.initState();
    // Re-fetch roles each time this page opens so the list reflects the
    // session that was just saved during login (fixes the blank-screen bug
    // caused by the bloc loading before login at app startup).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RolesBloc>().add(GetRolesList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<RolesBloc, RolesState>(
        listener: (context, state) {
          // If the user only has the client role, skip the selection screen
          // and navigate directly to catalog/home.
          if (state.roles != null &&
              state.roles!.length == 1 &&
              state.roles!.first != null) {
            final role = state.roles!.first!;
            if (!role.route.contains('admin')) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                role.route,
                (r) => false,
              );
            }
          }
        },
        builder: (context, state) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            alignment: Alignment.center,
            child: state.roles == null
                ? const CircularProgressIndicator()
                : ListView(
                    shrinkWrap: true,
                    children: state.roles!.map((Role? role) {
                      return role != null ? RolesItem(role) : const SizedBox.shrink();
                    }).toList(),
                  ),
          );
        },
      ),
    );
  }
}