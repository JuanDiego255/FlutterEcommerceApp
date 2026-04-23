import 'package:ecommerce_flutter/src/presentation/pages/client/ShoppingBag/bloc/ClientShoppingBagBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/ShoppingBag/bloc/ClientShoppingBagState.dart';
import 'package:ecommerce_flutter/src/presentation/widgets/DefaultButton.dart';
import 'package:flutter/material.dart';

class ClientShoppingBagBottomBar extends StatelessWidget {

  ClientShoppingBagState state;

  ClientShoppingBagBottomBar(this.state);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.grey[200],
      child: Column(
        children: [
          Divider(
            color: Colors.grey[300],
            height: 0,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'TOTAL: \$${ state.total }',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              Container(
                width: 180,
                child: DefaultButton(
                  text: 'CONFIRMAR ORDEN', 
                  onPressed: () { Navigator.pushNamed(context, 'client/address/list'); }
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}