part of '../provider.dart';

typedef _SelectorAspect<T> = bool Function(T value);

/// A [BuildContext] associated to an [InheritedProvider].
///
/// It an extra [markNeedsNotifyDependents] method and the exposed value.
abstract class InheritedContext<T> extends BuildContext {
  /// The current value exposed by [InheritedProvider].
  ///
  /// This property is lazy loaded, and reading it the first time may trigger
  /// some side-effects such as creating a [T] instance or starting
  /// a subscription.
  T get value;

  /// Marks the [InheritedProvider] as needing to update dependents.
  ///
  /// This bypass [InheritedWidget.updateShouldNotify] and will force widgets
  /// that depends on [T] to rebuild.
  void markNeedsNotifyDependents();

  /// Whether `setState` was called at least once or not.
  ///
  /// It can be used by [DeferredStartListening] to differentiate between the
  /// very first listening, and a rebuild after `controller` changed.
  bool get hasValue;
}

class _InheritedProviderScope<T> extends InheritedWidget {
  const _InheritedProviderScope({
    required this.owner,
    required this.debugType,
    required Widget child,
  })  : assert(null is T),
        super(child: child);

  final InheritedProvider<T> owner;
  final String debugType;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }

  @override
  _InheritedProviderScopeElement<T> createElement() {
    return _InheritedProviderScopeElement<T>(this);
  }
}

class _Dependency<T> {
  bool shouldClearSelectors = false;
  bool shouldClearMutationScheduled = false;
  final selectors = <_SelectorAspect<T>>[];
}

class _InheritedProviderScopeElement<T> extends InheritedElement
    implements InheritedContext<T> {
  _InheritedProviderScopeElement(_InheritedProviderScope<T> widget)
      : super(widget);

  static int _nextProviderId = 0;

  bool _shouldNotifyDependents = false;
  bool _debugInheritLocked = false;
  bool _isNotifyDependentsEnabled = true;
  bool _updatedShouldNotify = false;
  bool _isBuildFromExternalSources = false;
  late final _DelegateState<T, _Delegate<T>> _delegateState =
      widget.owner._delegate.createState()..element = this;
  late String _debugId;

  @override
  InheritedElement? getElementForInheritedWidgetOfExactType<
      InheritedWidgetType extends InheritedWidget>() {
    InheritedElement? inheritedElement;

    // An InheritedProvider<T>'s update tries to obtain a parent provider of
    // the same type.
    visitAncestorElements((parent) {
      inheritedElement =
          parent.getElementForInheritedWidgetOfExactType<InheritedWidgetType>();
      return false;
    });
    return inheritedElement;
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    if (kDebugMode) {
      _debugId = '${_nextProviderId++}';
      ProviderBinding.debugInstance.providerDetails = {
        ...ProviderBinding.debugInstance.providerDetails,
        _debugId: ProviderNode(
          id: _debugId,
          childrenNodeIds: const [],
          // ignore: no_runtimetype_tostring
          type: widget.debugType,
          element: this,
        )
      };
    }

    super.mount(parent, newSlot);
  }

  @override
  _InheritedProviderScope<T> get widget =>
      super.widget as _InheritedProviderScope<T>;

  @override
  void reassemble() {
    super.reassemble();

    final value = _delegateState.hasValue ? _delegateState.value : null;
    if (value is ReassembleHandler) {
      value.reassemble();
    }
  }

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    final dependencies = getDependencies(dependent);
    // once subscribed to everything once, it always stays subscribed to everything
    if (dependencies != null && dependencies is! _Dependency<T>) {
      return;
    }
    //使用elector类型消费者的时候，执行到这里。
    if (aspect is _SelectorAspect<T>) {
      final selectorDependency =
          (dependencies ?? _Dependency<T>()) as _Dependency<T>;

      if (selectorDependency.shouldClearSelectors) {
        selectorDependency.shouldClearSelectors = false;
        selectorDependency.selectors.clear();
      }
      if (selectorDependency.shouldClearMutationScheduled == false) {
        selectorDependency.shouldClearMutationScheduled = true;
        Future.microtask(() {
          selectorDependency
            ..shouldClearMutationScheduled = false
            ..shouldClearSelectors = true;
        });
      }
      selectorDependency.selectors.add(aspect);
      setDependencies(dependent, selectorDependency);
    } else {
      // subscribes to everything
      setDependencies(dependent, const Object());
    }
  }

  @override
  void notifyDependent(InheritedWidget oldWidget, Element dependent) {
    final dependencies = getDependencies(dependent);

    if (kDebugMode) {
      ProviderBinding.debugInstance.providerDidChange(_debugId);
    }

    var shouldNotify = false;
    if (dependencies != null) {
      //elector类型消费者，执行对应的select方法。
      if (dependencies is _Dependency<T>) {
        // select can never be used inside `didChangeDependencies`, so if the
        // dependent is already marked as needed build, there is no point
        // in executing the selectors.
        if (dependent.dirty) {
          return;
        }

        for (final updateShouldNotify in dependencies.selectors) {
          try {
            assert(() {
              _debugIsSelecting = true;
              return true;
            }());
            shouldNotify = updateShouldNotify(value);
          } finally {
            assert(() {
              _debugIsSelecting = false;
              return true;
            }());
          }
          if (shouldNotify) {
            break;
          }
        }
      } else {
        shouldNotify = true;
      }
    }

    if (shouldNotify) {
      dependent.didChangeDependencies();
    }
  }

  @override
  void update(_InheritedProviderScope<T> newWidget) {
    assert(() {
      if (widget.owner._delegate.runtimeType !=
          newWidget.owner._delegate.runtimeType) {
        throw StateError('''
Rebuilt $widget using a different constructor.
      
This is likely a mistake and is unsupported.
If you're in this situation, consider passing a `key` unique to each individual constructor.
''');
      }
      return true;
    }());

    _isBuildFromExternalSources = true;

    _updatedShouldNotify =
        _delegateState.willUpdateDelegate(newWidget.owner._delegate);
    super.update(newWidget);
    _updatedShouldNotify = false;
  }

  @override
  void updated(InheritedWidget oldWidget) {
    super.updated(oldWidget);
    if (_updatedShouldNotify) {
      notifyClients(oldWidget);
    }
  }

  @override
  void didChangeDependencies() {
    _isBuildFromExternalSources = true;
    super.didChangeDependencies();
  }

  @override
  Widget build() {
    if (widget.owner._lazy == false) {
      value; // this will force the value to be computed.
    }
    _delegateState.build(
      isBuildFromExternalSources: _isBuildFromExternalSources,
    );
    _isBuildFromExternalSources = false;
    if (_shouldNotifyDependents) {
      _shouldNotifyDependents = false;
      notifyClients(widget);
    }
    return super.build();
  }

  @override
  void unmount() {
    _delegateState.dispose();
    if (kDebugMode) {
      ProviderBinding.debugInstance.providerDetails = {
        ...ProviderBinding.debugInstance.providerDetails,
      }..remove(_debugId);
    }
    super.unmount();
  }

  @override
  bool get hasValue => _delegateState.hasValue;

  @override
  void markNeedsNotifyDependents() {
    if (!_isNotifyDependentsEnabled) {
      return;
    }

    markNeedsBuild();
    _shouldNotifyDependents = true;
  }

  bool _debugSetInheritedLock(bool value) {
    assert(() {
      _debugInheritLocked = value;
      return true;
    }());
    return true;
  }

  @override
  T get value => _delegateState.value;

  @override
  InheritedWidget dependOnInheritedElement(
    InheritedElement ancestor, {
    Object? aspect,
  }) {
    assert(() {
      if (_debugInheritLocked) {
        throw FlutterError.fromParts(
          <DiagnosticsNode>[
            ErrorSummary(
              'Tried to listen to an InheritedWidget '
              'in a life-cycle that will never be called again.',
            ),
            ErrorDescription('''
This error typically happens when calling Provider.of with `listen` to `true`,
in a situation where listening to the provider doesn't make sense, such as:
- initState of a StatefulWidget
- the "create" callback of a provider

This is undesired because these life-cycles are called only once in the
lifetime of a widget. As such, while `listen` is `true`, the widget has
no mean to handle the update scenario.

To fix, consider:
- passing `listen: false` to `Provider.of`
- use a life-cycle that handles updates (like didChangeDependencies)
- use a provider that handles updates (like ProxyProvider).
'''),
          ],
        );
      }
      return true;
    }());
    return super.dependOnInheritedElement(ancestor, aspect: aspect);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    _delegateState.debugFillProperties(properties);
  }
}
