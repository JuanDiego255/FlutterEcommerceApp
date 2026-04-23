import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/detail/AdminOrderDetailBottom.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/detail/AdminOrderDetailItem.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/detail/bloc/AdminOrderDetailBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/detail/bloc/AdminOrderDetailState.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/list/bloc/AdminOrderListBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/list/bloc/AdminOrderListEvent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdminOrderDetailPage extends StatefulWidget {
  const AdminOrderDetailPage({super.key});

  @override
  State<AdminOrderDetailPage> createState() => _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<AdminOrderDetailPage> {
  AdminOrderDetailBloc? _bloc;
  Order? order;

  @override
  Widget build(BuildContext context) {
    order = ModalRoute.of(context)?.settings.arguments as Order;
    _bloc = BlocProvider.of<AdminOrderDetailBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del pedido'),
      ),
      body: BlocListener<AdminOrderDetailBloc, AdminOrderDetailState>(
        listener: (context, state) {
          final responseState = state.response;
          if (responseState is Error) {
            Fluttertoast.showToast(msg: responseState.message, toastLength: Toast.LENGTH_LONG);
          }
          else if (responseState is Success) {
            Fluttertoast.showToast(msg: 'El pedido se actualizo correctamente', toastLength: Toast.LENGTH_LONG);
            context.read<AdminOrderListBloc>().add(GetOrders());
            Navigator.pop(context);
          }
        },
        child: ListView.builder(
            itemCount: order?.orderHasProducts?.length,
            itemBuilder: (context, index) {
              return AdminOrderDetailItem(order?.orderHasProducts![index]);
            }),
      ),
      bottomNavigationBar: AdminOrderDetailBottom(_bloc, order),
    );
  }
}
