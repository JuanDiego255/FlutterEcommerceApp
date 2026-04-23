import 'package:ecommerce_flutter/src/domain/models/Category.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/category/list/bloc/AdminCategoryListBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/category/list/bloc/AdminCategoryListEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/product/list/bloc/AdminProductListBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/product/list/bloc/AdminProductListEvent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AdminProductListItem extends StatelessWidget {

  AdminProductListBloc? bloc;
  Product? product;

  AdminProductListItem(this.bloc, this.product);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigator.pushNamed(context, 'admin/product/list', arguments: category);
      },
      child: ListTile(
        leading: product != null 
        ? Container(
          width: 70,
          child: product!.image1!.isNotEmpty ? 
          FadeInImage.assetNetwork(
            placeholder: 'assets/img/no-image.png', 
            image: product!.image1!,
            fit: BoxFit.contain,
            fadeInDuration: Duration(seconds: 1),
          ) : Container(),
        ) 
        : Container(),
        title: Text(product?.name ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5),
            Text(product?.description ?? ''),
            SizedBox(height: 5),
            Text(
              '\$ ${product?.price.toString() ?? ''}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        // contentPadding: EdgeInsets.only(left: 10, right: 10, top: 10),
        trailing: Wrap(
          direction: Axis.horizontal,
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, 'admin/product/update', arguments: product);
              }, 
              icon: Icon(
                Icons.edit
              )
            ),
            IconButton(
              onPressed: () {
                bloc?.add(DeleteProduct(id: product!.id!));
              }, 
              icon: Icon(
                Icons.delete
              )
            ),
          ],
        ),
      ),
    );
  }
}