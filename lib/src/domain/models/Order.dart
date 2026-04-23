
// To parse this JSON data, do
//
//     final order = orderFromJson(jsonString);

import 'dart:convert';

import 'package:ecommerce_flutter/src/domain/models/Address.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/models/User.dart';

List<Order> orderFromJson(String str) => List<Order>.from(json.decode(str).map((x) => Order.fromJson(x)));

String orderToJson(List<Order> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Order {
    int id;
    int idClient;
    int idAddress;
    String status;
    DateTime createdAt;
    DateTime updatedAt;
    User? user;
    Address? address;
    List<OrderHasProduct>? orderHasProducts;

    Order({
        required this.id,
        required this.idClient,
        required this.idAddress,
        required this.status,
        required this.createdAt,
        required this.updatedAt,
        required this.user,
        required this.address,
        required this.orderHasProducts,
    });

     static List<Order> fromJsonList(List<dynamic> jsonList) {
      List<Order> toList = [];
      jsonList.forEach((item) { 
        Order orders = Order.fromJson(item);
        toList.add(orders);
      });
      return toList;
    }

    factory Order.fromJson(Map<String, dynamic> json) {
      print('Order Data: ${json}');
      return Order(
        id: json["id"],
        idClient: json["id_user"],
        idAddress: json["id_address"],
        status: json["status"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        user: json["user"] != null ? User.fromJson(json["user"]) : null,
        address: json["address"] != null ? Address.fromJson(json["address"]) : null,
        orderHasProducts: json["orderHasProducts"] != null ? List<OrderHasProduct>.from(json["orderHasProducts"].map((x) => OrderHasProduct.fromJson(x))) : null,
      );
    }

    Map<String, dynamic> toJson() => {
        "id": id,
        "id_user": idClient,
        "id_address": idAddress,
        "status": statusValues.reverse[status],
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "user": user?.toJson(),
        "address": address?.toJson(),
        "orderHasProducts": orderHasProducts != null ? List<dynamic>.from(orderHasProducts!.map((x) => x.toJson())) : [],
    };
}



enum AddressEnum {
    AVENIDA_5_CARRERA_32,
    CALLE_26_CARRERA_54,
    CALLE_5_AVENIDA_40
}

final addressEnumValues = EnumValues({
    "Avenida 5 Carrera 32": AddressEnum.AVENIDA_5_CARRERA_32,
    "Calle 26 Carrera 54": AddressEnum.CALLE_26_CARRERA_54,
    "Calle 5 Avenida 40": AddressEnum.CALLE_5_AVENIDA_40
});

enum Neighborhood {
    FATIMA,
    NEW_BRIGHTON,
    PALERMO
}

final neighborhoodValues = EnumValues({
    "Fatima": Neighborhood.FATIMA,
    "New brighton": Neighborhood.NEW_BRIGHTON,
    "Palermo": Neighborhood.PALERMO
});

class OrderHasProduct {
    int idOrder;
    int idProduct;
    int quantity;
    DateTime createdAt;
    DateTime updatedAt;
    Product product;

    OrderHasProduct({
        required this.idOrder,
        required this.idProduct,
        required this.quantity,
        required this.createdAt,
        required this.updatedAt,
        required this.product,
    });

    factory OrderHasProduct.fromJson(Map<String, dynamic> json) => OrderHasProduct(
        idOrder: json["id_order"],
        idProduct: json["id_product"],
        quantity: json["quantity"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        product: Product.fromJson(json["product"]),
    );

    Map<String, dynamic> toJson() => {
        "id_order": idOrder,
        "id_product": idProduct,
        "quantity": quantity,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "product": product.toJson(),
    };
}


enum Description {
    CAMISETAS_DEPORTIVAS_DE_ENTRENAMIENTO,
    CAMISETAS_NIKE_DE_ENTRENAMIENTO,
    ZAPATOS_DEPORTIVOS,
    ZAPATOS_DE_LUJO
}

final descriptionValues = EnumValues({
    "Camisetas deportivas de entrenamiento": Description.CAMISETAS_DEPORTIVAS_DE_ENTRENAMIENTO,
    "Camisetas nike de entrenamiento": Description.CAMISETAS_NIKE_DE_ENTRENAMIENTO,
    "Zapatos deportivos": Description.ZAPATOS_DEPORTIVOS,
    "Zapatos de lujo ": Description.ZAPATOS_DE_LUJO
});

enum Status {
    DESPACHADO,
    PAGADO
}

final statusValues = EnumValues({
    "DESPACHADO": Status.DESPACHADO,
    "PAGADO": Status.PAGADO
});


enum Email {
    DAVID_GMAIL_COM,
    JONATHAN_GMAIL_COM
}

final emailValues = EnumValues({
    "david@gmail.com": Email.DAVID_GMAIL_COM,
    "jonathan@gmail.com": Email.JONATHAN_GMAIL_COM
});

enum Lastname {
    GOYES,
    MARTINEZ
}

final lastnameValues = EnumValues({
    "Goyes": Lastname.GOYES,
    "Martinez": Lastname.MARTINEZ
});

enum Name {
    DAVID_ESTEBAN,
    JONATHAN
}

final nameValues = EnumValues({
    "David Esteban": Name.DAVID_ESTEBAN,
    "Jonathan ": Name.JONATHAN
});

enum Password {
    THE_2_B_106_IY_YT3_H_GE_JZA_GKC2_J_EWD_LOD_K7_Q_DC_QJ3_VZ_XAF_T8_F4_KDG5_CH_D_YE_A_TQ,
    THE_2_B_10_C_AFV4_O2_LXB9_OV_OJC_XTSEE_C_N0_EM_SO9_H_P_YW_PJGIC40_QS2_GH_I1_LE
}

final passwordValues = EnumValues({
    "\u00242b\u002410\u00246IyYt3HGeJzaGKC2jEwdLOD/k7QDcQj3vzXafT8f4KDG5ChDYeATq": Password.THE_2_B_106_IY_YT3_H_GE_JZA_GKC2_J_EWD_LOD_K7_Q_DC_QJ3_VZ_XAF_T8_F4_KDG5_CH_D_YE_A_TQ,
    "\u00242b\u002410\u0024cAfv4.O2LXB9.OvOjcXtseeC.N0EmSO9hPYw/PJGIC40qs2ghI1Le": Password.THE_2_B_10_C_AFV4_O2_LXB9_OV_OJC_XTSEE_C_N0_EM_SO9_H_P_YW_PJGIC40_QS2_GH_I1_LE
});

enum Phone {
    THE_573333333,
    THE_5789494949
}

final phoneValues = EnumValues({
    "+57 3333333": Phone.THE_573333333,
    "+57 89494949": Phone.THE_5789494949
});

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
        reverseMap = map.map((k, v) => MapEntry(v, k));
        return reverseMap;
    }
}
