part of '../provider.dart';

@immutable
abstract class _Delegate<T> {
  _DelegateState<T, _Delegate<T>> createState();

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}
}

abstract class _DelegateState<T, D extends _Delegate<T>> {
  _InheritedProviderScopeElement<T?>? element;

  //用来获取provider持有的值
  T get value;

  //其实就是 _Delegate<T>
  D get delegate => element!.widget.owner._delegate as D;

  //是否有值，对于_CreateInheritedProvider来说是执行了create方法，对于_ValueInheritedProvider始终是true。
  bool get hasValue;

  bool debugSetInheritedLock(bool value) {
    return element!._debugSetInheritedLock(value);
  }

  bool willUpdateDelegate(D newDelegate) => false;

  //_InheritedProviderScopeElement 执行 unmount方法。
  void dispose() {}

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}

  //_InheritedProviderScopeElement 执行 build方法
  void build({required bool isBuildFromExternalSources}) {}
}
