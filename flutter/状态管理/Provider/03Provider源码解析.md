# InheritedProvider

从最基础的`InheritedProvider`开始分析。了解了这一部分，其他的只是再起基础上进行了内容丰富。



# class InheritedProvider<T>

精简代码之后如下。重点注释可以查看代码。

```dart
class InheritedProvider<T> extends SingleChildStatelessWidget {
  
  InheritedProvider({
    Key? key,
    Create<T>? create,  
    T Function(BuildContext context, T? value)? update,
    UpdateShouldNotify<T>? updateShouldNotify,
    void Function(T value)? debugCheckInvalidValueType,
    StartListening<T>? startListening,
    Dispose<T>? dispose,
    this.builder,
    bool? lazy,
    Widget? child,
  })  : _lazy = lazy,
        _delegate = _CreateInheritedProvider(
          create: create,
          update: update,
          updateShouldNotify: updateShouldNotify,
          debugCheckInvalidValueType: debugCheckInvalidValueType,
          startListening: startListening,
          dispose: dispose,
        ),
        super(key: key, child: child);

  final _Delegate<T> _delegate;
  final bool? _lazy;

  final TransitionBuilder? builder;

  @override
  _InheritedProviderElement<T> createElement() {
    return _InheritedProviderElement<T>(this);
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return _InheritedProviderScope<T?>(
      owner: this,
      debugType: kDebugMode ? '$runtimeType' : '',
      child: builder != null
          ? Builder(
              builder: (context) => builder!(context, child),
            )
          : child!,
    );
  }
}
```

