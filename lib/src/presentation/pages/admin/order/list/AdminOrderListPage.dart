import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/list/AdminOrderListItem.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/list/bloc/AdminOrderListBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/list/bloc/AdminOrderListEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/list/bloc/AdminOrderListState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdminOrderListPage extends StatefulWidget {
  const AdminOrderListPage({super.key});

  @override
  State<AdminOrderListPage> createState() => _AdminOrderListPageState();
}

class _AdminOrderListPageState extends State<AdminOrderListPage> {

  AdminOrderListBloc? _bloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _bloc?.add(GetOrders());
    });
  }

  @override
  Widget build(BuildContext context) {
    _bloc = BlocProvider.of<AdminOrderListBloc>(context);
    return Scaffold(
      body: BlocListener<AdminOrderListBloc, AdminOrderListState>(
        listener: (context, state) {
          final responseState = state.response;
          if (responseState is Error) {
            Fluttertoast.showToast(msg: responseState.message, toastLength: Toast.LENGTH_LONG);
          }
        },
        child: BlocBuilder<AdminOrderListBloc, AdminOrderListState>(
          builder: (context, state) {
            final responseState = state.response;
            if (responseState is Success) {
              List<Order> orders = responseState.data as List<Order>;
              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  return AdminOrderListItem(orders[index]);
                }
              );
            }
            return Container();
          },
        ),
      ),
    );
  }
}