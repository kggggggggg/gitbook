part of '../provider.dart';

/// A generic implementation of an [InheritedWidget].
///
/// Any descendant of this widget can obtain `value` using [Provider.of].
///
/// Do not use this class directly unless you are creating a custom "Provider".
/// Instead use [Provider] class, which wraps [InheritedProvider].
///
/// See also:
///
///  - [DeferredInheritedProvider], a variant of this object where the provided
///    object and the created object are two different entity.
class InheritedProvider<T> extends SingleChildStatelessWidget {
  /// Creates a value, then expose it to its descendants.
  ///
  /// The value will be disposed of when [InheritedProvider] is removed from
  /// the widget tree.
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

  /// Expose to its descendants an existing value,
  InheritedProvider.value({
    Key? key,
    required T value,
    UpdateShouldNotify<T>? updateShouldNotify,
    StartListening<T>? startListening,
    bool? lazy,
    this.builder,
    Widget? child,
  })  : _lazy = lazy,
        _delegate = _ValueInheritedProvider(
          value: value,
          updateShouldNotify: updateShouldNotify,
          startListening: startListening,
        ),
        super(key: key, child: child);

  InheritedProvider._constructor({
    Key? key,
    required _Delegate<T> delegate,
    bool? lazy,
    this.builder,
    Widget? child,
  })  : _lazy = lazy,
        _delegate = delegate,
        super(key: key, child: child);

  final _Delegate<T> _delegate;
  final bool? _lazy;

  /// Syntax sugar for obtaining a [BuildContext] that can read the provider
  /// created.
  ///
  /// This code:
  ///
  /// ```dart
  /// Provider<int>(
  ///   create: (context) => 42,
  ///   builder: (context, child) {
  ///     final value = context.watch<int>();
  ///     return Text('$value');
  ///   }
  /// )
  /// ```
  ///
  /// is strictly equivalent to:
  ///
  /// ```dart
  /// Provider<int>(
  ///   create: (context) => 42,
  ///   child: Builder(
  ///     builder: (context) {
  ///       final value = context.watch<int>();
  ///       return Text('$value');
  ///     },
  ///   ),
  /// )
  /// ```
  ///
  /// For an explanation on the `child` parameter that `builder` receives,
  /// see the "Performance optimizations" section of [AnimatedBuilder].
  final TransitionBuilder? builder;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    _delegate.debugFillProperties(properties);
  }

  @override
  _InheritedProviderElement<T> createElement() {
    return _InheritedProviderElement<T>(this);
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(
      builder != null || child != null,
      '$runtimeType used outside of MultiProvider must specify a child',
    );
    return _InheritedProviderScope<T?>(
      owner: this,
      // ignore: no_runtimetype_tostring
      debugType: kDebugMode ? '$runtimeType' : '',
      child: builder != null
          ? Builder(
              builder: (context) => builder!(context, child),
            )
          : child!,
    );
  }
}

class _InheritedProviderElement<T> extends SingleChildStatelessElement {
  _InheritedProviderElement(InheritedProvider<T> widget) : super(widget);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    visitChildren((e) => e.debugFillProperties(properties));
  }
}
