import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/detail/bloc/AdminOrderDetailBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/detail/bloc/AdminOrderDetailEvent.dart';
import 'package:ecommerce_flutter/src/presentation/widgets/DefaultButton.dart';
import 'package:flutter/material.dart';

class AdminOrderDetailBottom extends StatelessWidget {
  final Order? order;
  final AdminOrderDetailBloc? bloc;
  const AdminOrderDetailBottom(this.bloc, this.order, {super.key});

  @override
  Widget build(BuildContext context) {
    double total = 0;
    order?.orderHasProducts?.forEach((ohp) {
      total = total + (ohp.product.price * ohp.quantity);
    });
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.45,
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
            leading: Icon(Icons.person, color: Colors.grey[400],),
            title: Text('Cliente y telefono'),
            subtitle: Text('${order?.user?.name} ${order?.user?.lastname} - ${order?.user?.phone}'),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Total: \$${total}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18
                ),
              ),
              Container(
                width: 150,
                child: order?.status == 'PAGADO' 
                ? DefaultButton(
                  text: 'DESPACHAR', 
                  onPressed: () {
                    bloc?.add(UpdateStatusOrder(id: order!.id));
                  }
                )
                : Container()
              )
            ],
          )
        ],
      )
    );
  }
}