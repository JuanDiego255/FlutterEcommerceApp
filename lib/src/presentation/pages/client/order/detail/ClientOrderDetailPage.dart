import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/detail/ClientOrderDetailBottom.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/detail/ClientOrderDetailItem.dart';
import 'package:flutter/material.dart';

class ClientOrderDetailPage extends StatefulWidget {
  const ClientOrderDetailPage({super.key});

  @override
  State<ClientOrderDetailPage> createState() => _ClientOrderDetailPageState();
}

class _ClientOrderDetailPageState extends State<ClientOrderDetailPage> {
  Order? order;

  @override
  Widget build(BuildContext context) {
    order = ModalRoute.of(context)?.settings.arguments as Order;
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del pedido'),
      ),
      body: ListView.builder(
        itemCount: order?.orderHasProducts?.length,
        itemBuilder: (context, index) {
          return ClientOrderDetailItem(order?.orderHasProducts![index]);
        }
      ),
      bottomNavigationBar: ClientOrderDetailBottom(order),
    );
  }
}
