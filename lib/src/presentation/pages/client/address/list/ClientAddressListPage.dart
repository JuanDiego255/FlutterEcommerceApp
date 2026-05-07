import 'package:ecommerce_flutter/src/domain/models/Address.dart';
import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/ClientAddressListItem.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/bloc/ClientAddressListBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/bloc/ClientAddressListEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/bloc/ClientAddressListState.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ClientAddressListPage extends StatefulWidget {
  const ClientAddressListPage({super.key});

  @override
  State<ClientAddressListPage> createState() => _ClientAddressListPageState();
}

class _ClientAddressListPageState extends State<ClientAddressListPage> {

  ClientAddressListBloc? _bloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bloc?.add(GetUserAddress());
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    _bloc = BlocProvider.of<ClientAddressListBloc>(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Dirección de entrega',
          style: TextStyle(color: cs.onBackground, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, 'client/address/create').then((_) {
                _bloc?.add(GetUserAddress());
              });
            },
            icon: Icon(Icons.add_location_alt_outlined, color: cs.primary),
            tooltip: 'Nueva dirección',
          ),
        ],
      ),
      body: BlocListener<ClientAddressListBloc, ClientAddressListState>(
        listener: (context, state) {
          final responseState = state.response;
          if (responseState is Success) {
            if (responseState.data is bool) {
              _bloc?.add(GetUserAddress());
            } else if (responseState.data is Order) {
              final order = responseState.data as Order;
              _showOrderSuccessDialog(context, order);
            }
          }
          if (responseState is Error) {
            Fluttertoast.showToast(
                msg: responseState.message,
                toastLength: Toast.LENGTH_LONG,
                backgroundColor: cs.error);
          }
        },
        child: Stack(
          children: [
            BlocBuilder<ClientAddressListBloc, ClientAddressListState>(
              builder: (context, state) {
                final responseState = state.response;
                if (responseState is Loading) {
                  return Center(child: CircularProgressIndicator(color: cs.primary));
                }
                if (responseState is Success && responseState.data is List<Address>) {
                  final List<Address> addresses =
                      responseState.data as List<Address>;
                  _bloc?.add(SetAddressSession(addressList: addresses));

                  if (addresses.isEmpty) {
                    return _buildEmptyState(context, cs, tokens);
                  }

                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.primary.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: cs.primary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Seleccioná la dirección donde querés recibir tu pedido',
                                style: TextStyle(fontSize: 12, color: cs.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: addresses.length,
                          itemBuilder: (context, index) {
                            return ClientAddressListItem(
                                _bloc, state, addresses[index], index);
                          },
                        ),
                      ),
                    ],
                  );
                }
                if (responseState is Error) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: tokens.textMuted),
                        const SizedBox(height: 12),
                        Text(responseState.message,
                            style: TextStyle(color: tokens.textMuted)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _bloc?.add(GetUserAddress()),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                return Center(child: CircularProgressIndicator(color: cs.primary));
              },
            ),
            BlocBuilder<ClientAddressListBloc, ClientAddressListState>(
              builder: (context, state) {
                if (!state.isCreatingOrder) return const SizedBox.shrink();
                return Container(
                  color: Colors.black.withOpacity(0.45),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Procesando tu pedido...',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BlocBuilder<ClientAddressListBloc, ClientAddressListState>(
        builder: (context, state) {
          final canOrder = state.radioValue != null;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 20),
                onPressed: canOrder && !state.isCreatingOrder
                    ? () => _bloc?.add(OnConfirmOrder())
                    : null,
                label: Text(
                  state.isCreatingOrder
                      ? 'Procesando...'
                      : canOrder
                          ? 'Confirmar pedido'
                          : 'Seleccioná una dirección',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme cs, AppTokens tokens) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_outlined, size: 72, color: tokens.textSubtle),
          const SizedBox(height: 16),
          Text(
            'No tenés direcciones guardadas',
            style: TextStyle(
                fontSize: 16,
                color: cs.onBackground,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Agregá una para continuar con tu pedido',
            style: TextStyle(fontSize: 13, color: tokens.textMuted),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_location_alt_outlined, size: 18),
            onPressed: () {
              Navigator.pushNamed(context, 'client/address/create').then((_) {
                _bloc?.add(GetUserAddress());
              });
            },
            label: const Text('Agregar dirección',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showOrderSuccessDialog(BuildContext context, Order order) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: tokens.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: tokens.success, size: 42),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Pedido confirmado!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onBackground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu pedido #${order.id} fue recibido y está siendo procesado.',
              style: TextStyle(fontSize: 13, color: tokens.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacementNamed(
                      context, 'client/order/detail',
                      arguments: order);
                },
                child: const Text('Ver mi pedido',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
