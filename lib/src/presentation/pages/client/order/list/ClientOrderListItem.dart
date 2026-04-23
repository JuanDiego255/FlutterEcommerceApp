import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:flutter/material.dart';

class ClientOrderListItem extends StatelessWidget {

  Order order; 
  ClientOrderListItem(this.order);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, 'client/order/detail', arguments: order);
      },
      child: Container(
        margin: EdgeInsets.only(left: 30, right: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pedido: #${order.id}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18
              ),
            ),
            Text(
              'Fecha: ${order.createdAt}',
              style: TextStyle(
                fontSize: 16
              ),
            ),
            Text(
              'Entregar en: ${order.address?.address}',
              style: TextStyle(
                fontSize: 16
              )
            ),
            Text(
              'Estado: ${order.status}',
              style: TextStyle(
                fontSize: 16
              )
            ),
            Divider(color: Colors.grey[300],)
          ],
        ),
      ),
    );
  }
}