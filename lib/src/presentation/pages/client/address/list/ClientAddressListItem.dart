import 'package:ecommerce_flutter/src/domain/models/Address.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/bloc/ClientAddressListBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/bloc/ClientAddressListEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/bloc/ClientAddressListState.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ClientAddressListItem extends StatelessWidget {

  final ClientAddressListBloc? bloc;
  final ClientAddressListState state;
  final Address address;
  final int index;

  const ClientAddressListItem(this.bloc, this.state, this.address, this.index, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Radio(
            value: index,
            groupValue: state.radioValue,
            onChanged: (value) {
              bloc?.add(ChangeRadioValue(radioValue: value!, address: address));
            },
          ),
          trailing: IconButton(
            onPressed: () {
              bloc?.add(DeleteAddress(id: address.id!));
            }, 
            icon: Icon(Icons.delete, color: Colors.red,)
          ),
          title: Text(
            address.address,
            style: TextStyle(
              fontWeight: FontWeight.bold
            ),
          ),
          subtitle: Text(
            address.neighborhood,
            style: TextStyle(
              fontWeight: FontWeight.bold
            ),
          ),
        ),
        Divider(color: Colors.grey[300], indent: 30, endIndent: 30,)
      ],
    );
  }
}