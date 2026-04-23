import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/presentation/widgets/DefaultButton.dart';
import 'package:flutter/material.dart';

class ClientOrderDetailBottom extends StatelessWidget {
  Order? order;
  ClientOrderDetailBottom(this.order);

  @override
  Widget build(BuildContext context) {
    double total = 0;
    order?.orderHasProducts?.forEach((ohp) {
      total = total + (ohp.product.price * ohp.quantity);
    });
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.37,
      decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.all(Radius.circular(25))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // VERTICAL
        crossAxisAlignment: CrossAxisAlignment.center, // HORIZANTAL
        children: [
          ListTile(
            leading: Icon(Icons.calendar_month, color: Colors.grey[400],),
            title: Text('Fecha del pedido'),
            subtitle: Text(order?.createdAt.toString() ?? ''),
          ),
          ListTile(
            leading: Icon(Icons.location_on, color: Colors.grey[400],),
            title: Text('Direccion de entrega'),
            subtitle: Text('${order?.address?.neighborhood} ${order?.address?.address}'),
          ),
          ListTile(
            leading: Icon(Icons.change_circle, color: Colors.grey[400],),
            title: Text('Estado de la orden'),
            subtitle: Text(order?.status ?? ''),
          ),
          ListTile(
            leading: Icon(Icons.currency_exchange, color: Colors.grey[400],),
            title: Text('Total'),
            subtitle: Text('\$${total}'),
          ),
          
        ],
      )
    );
  }
}