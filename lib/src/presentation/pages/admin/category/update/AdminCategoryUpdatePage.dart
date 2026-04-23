import 'package:ecommerce_flutter/src/domain/models/Category.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/category/list/bloc/AdminCategoryListBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/category/list/bloc/AdminCategoryListEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/category/update/AdminCategoryUpdateContent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/category/update/bloc/AdminCategoryUpdateBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/category/update/bloc/AdminCategoryUpdateEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/category/update/bloc/AdminCategoryUpdateState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdminCategoryUpdatePage extends StatefulWidget {
  const AdminCategoryUpdatePage({super.key});

  @override
  State<AdminCategoryUpdatePage> createState() =>
      _AdminCategoryUpdatePageState();
}

class _AdminCategoryUpdatePageState extends State<AdminCategoryUpdatePage> {

  Category? category;
  AdminCategoryUpdateBloc? _bloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _bloc?.add(AdminCategoryUpdateInitEvent(category: category));
    });
  }

  @override
  void dispose() {
    super.dispose();
    _bloc?.add(ResetForm());
  }

  @override
  Widget build(BuildContext context) {
    _bloc = BlocProvider.of<AdminCategoryUpdateBloc>(context);
    category = ModalRoute.of(context)?.settings.arguments as Category;
    return Scaffold(
      body: BlocListener<AdminCategoryUpdateBloc, AdminCategoryUpdateState>(
        listener: (context, state) {
          final responseState = state.response;
          if (responseState is Success) {
            context.read<AdminCategoryListBloc>().add(GetCategories());
            Fluttertoast.showToast(msg: 'La categoria se actualizo correctamente', toastLength: Toast.LENGTH_LONG);
          }
          else if (responseState is Error) {
            Fluttertoast.showToast(msg: responseState.message, toastLength: Toast.LENGTH_LONG);
          }
        },
        child:  BlocBuilder<AdminCategoryUpdateBloc, AdminCategoryUpdateState>(
          builder: (context, state) {
            return AdminCategoryUpdateContent(_bloc, state, category);
          },
        ),
      ),
    );
  }
}
