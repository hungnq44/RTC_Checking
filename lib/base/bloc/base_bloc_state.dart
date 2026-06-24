import 'package:equatable/equatable.dart';

import 'index.dart';

abstract class BaseBlocState extends Equatable {
  const BaseBlocState({required this.status, this.message});

  final BaseStateStatus status;
  final String? message;

  @override
  List<Object?> get props => [status, message];
}
