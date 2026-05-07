import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/list/ClientOrderListItem.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/list/bloc/ClientOrderListBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/list/bloc/ClientOrderListEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/list/bloc/ClientOrderListState.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ClientOrderListPage extends StatefulWidget {
  const ClientOrderListPage({super.key});

  @override
  State<ClientOrderListPage> createState() => _ClientOrderListPageState();
}

class _ClientOrderListPageState extends State<ClientOrderListPage> {

  ClientOrderListBloc? _bloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bloc?.add(GetOrders());
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    _bloc = BlocProvider.of<ClientOrderListBloc>(context);
    return Scaffold(
      body: BlocListener<ClientOrderListBloc, ClientOrderListState>(
        listener: (context, state) {
          final responseState = state.response;
          if (responseState is Error) {
            Fluttertoast.showToast(
                msg: responseState.message, toastLength: Toast.LENGTH_LONG);
          }
        },
        child: BlocBuilder<ClientOrderListBloc, ClientOrderListState>(
          builder: (context, state) {
            final responseState = state.response;
            if (responseState is Loading) {
              return Center(child: CircularProgressIndicator(color: cs.primary));
            }
            if (responseState is Success) {
              final List<Order> orders = responseState.data as List<Order>;
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 72, color: tokens.textSubtle),
                      const SizedBox(height: 16),
                      Text(
                        'No tenés pedidos aún',
                        style: TextStyle(
                            fontSize: 16,
                            color: cs.onBackground,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tus pedidos aparecerán aquí',
                        style: TextStyle(fontSize: 13, color: tokens.textMuted),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: cs.primary,
                onRefresh: () async => _bloc?.add(GetOrders()),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return ClientOrderListItem(orders[index]);
                  },
                ),
              );
            }
            if (responseState is Error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: tokens.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      (responseState as Error).message,
                      style: TextStyle(color: tokens.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _bloc?.add(GetOrders()),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            return Center(child: CircularProgressIndicator(color: cs.primary));
          },
        ),
      ),
    );
  }
}
