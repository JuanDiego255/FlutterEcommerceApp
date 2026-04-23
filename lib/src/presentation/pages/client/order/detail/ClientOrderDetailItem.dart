import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:flutter/material.dart';

class ClientOrderDetailItem extends StatelessWidget {

  OrderHasProduct? orderHasProduct;

  ClientOrderDetailItem(this.orderHasProduct);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: orderHasProduct != null 
        ? Container(
          width: 70,
          child: FadeInImage.assetNetwork(
            placeholder: 'assets/img/no-image.png', 
            image: orderHasProduct!.product.image1!,
            fit: BoxFit.contain,
            fadeInDuration: Duration(seconds: 1),
          ),
        ) 
        : Container(),
      title: Text(
        orderHasProduct?.product.name ?? ''
      ),
      subtitle: Text(
        'Cantidad: ${orderHasProduct?.quantity}'
      ),
    );
  }
}