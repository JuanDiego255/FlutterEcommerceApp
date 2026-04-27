import 'dart:io';
import 'package:ecommerce_flutter/src/domain/models/Category.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/utils/BlocFormItem.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AdminCategoryCreateState extends Equatable {

  final BlocFormItem name;
  final BlocFormItem description;
  final GlobalKey<FormState>? formKey;
  final File? file;
  final Resource? response;

  AdminCategoryCreateState({
    this.name = const BlocFormItem(error: 'Ingresa el nombre'),
    this.description = const BlocFormItem(error: 'Ingresa la descripcion'),
    this.formKey,
    this.response,
    this.file
  });

  toCategory() => Category(
    name: name.value, 
    description: description.value, 
  );

  AdminCategoryCreateState resetForm() {
    return AdminCategoryCreateState(
      name: const BlocFormItem(error: 'Ingresa el nombre'),
      description: const BlocFormItem(error: 'Ingresa la descripcion'),
    );
  }

  AdminCategoryCreateState copyWith({
    BlocFormItem? name,
    BlocFormItem? description,
    GlobalKey<FormState>? formKey,
    File? file,
    Resource? response
  }) {
    return AdminCategoryCreateState(
      name: name ?? this.name,
      description: description ?? this.description,
      file: file ?? this.file,
      formKey: formKey,
      response: response
    );
  }

  @override
  List<Object?> get props => [name, description, file, response];

}