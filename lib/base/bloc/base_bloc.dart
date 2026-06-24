import 'package:flutter_bloc/flutter_bloc.dart';

import 'index.dart';

abstract class BaseBloc<E, S extends BaseBlocState> extends Bloc<E, S> {
  BaseBloc(super.initialState);
}
