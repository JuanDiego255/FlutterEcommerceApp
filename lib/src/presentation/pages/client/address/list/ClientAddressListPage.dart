import 'package:ecommerce_flutter/src/domain/models/Address.dart';
import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/ClientAddressListItem.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/bloc/ClientAddressListBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/bloc/ClientAddressListEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/bloc/ClientAddressListState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

const _kAccent  = Color(0xFF8B6F47);
const _kPrimary = Color(0xFF2D2D2D);
const _kSub     = Color(0xFF757575);

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
    _bloc = BlocProvider.of<ClientAddressListBloc>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Dirección de entrega',
          style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, 'client/address/create').then((_) {
                _bloc?.add(GetUserAddress());
              });
            },
            icon: const Icon(Icons.add_location_alt_outlined, color: _kAccent),
            tooltip: 'Nueva dirección',
          ),
        ],
      ),
      body: BlocListener<ClientAddressListBloc, ClientAddressListState>(
        listener: (context, state) {
          final responseState = state.response;
          if (responseState is Success) {
            if (responseState.data is bool) {
              // Address deleted → reload list
              _bloc?.add(GetUserAddress());
            } else if (responseState.data is Order) {
              // Order created successfully
              final order = responseState.data as Order;
              _showOrderSuccessDialog(context, order);
            }
          }
          if (responseState is Error) {
            Fluttertoast.showToast(
                msg: responseState.message,
                toastLength: Toast.LENGTH_LONG,
                backgroundColor: Colors.red[700]);
          }
        },
        child: Stack(
          children: [
            BlocBuilder<ClientAddressListBloc, ClientAddressListState>(
              builder: (context, state) {
                final responseState = state.response;
                if (responseState is Loading) {
                  return const Center(
                      child: CircularProgressIndicator(color: _kAccent));
                }
                if (responseState is Success && responseState.data is List<Address>) {
                  final List<Address> addresses =
                      responseState.data as List<Address>;
                  _bloc?.add(SetAddressSession(addressList: addresses));

                  if (addresses.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return Column(
                    children: [
                      // Header
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kAccent.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline, color: _kAccent, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Seleccioná la dirección donde querés recibir tu pedido',
                                style: TextStyle(fontSize: 12, color: _kAccent),
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
                        const Icon(Icons.error_outline, size: 48, color: _kSub),
                        const SizedBox(height: 12),
                        Text(responseState.message,
                            style: const TextStyle(color: _kSub)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _bloc?.add(GetUserAddress()),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(
                    child: CircularProgressIndicator(color: _kAccent));
              },
            ),
            // Loading overlay while creating order
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: canOrder ? _kPrimary : Colors.grey[300],
                  foregroundColor: canOrder ? Colors.white : Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No tenés direcciones guardadas',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Agregá una para continuar con tu pedido',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF43A047), size: 42),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Pedido confirmado!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2D2D2D)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu pedido #${order.id} fue recibido y está siendo procesado.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF757575), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2D2D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  // Navigate to order detail
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
