# Provider

从最基础的`InheritedProvider`开始分析。了解了这一部分，其他的只是再起基础上进行了内容丰富。



# 1. InheritedProvider

## 1.1 class InheritedProvider&lt;T&gt;

精简代码之后如下。重点注释可以查看代码。

```dart
class InheritedProvider<T> extends SingleChildStatelessWidget {
  
  //<hl> 1. 构造方法
  InheritedProvider({
    Key? key,
    Create<T>? create,   //<hl> 用来创建Provider持有的对象
    T Function(BuildContext context, T? value)? update, //<hl> 当前Provider更新时触发。
    //<hl> Provider更新时,数据不一定变化，判断是否需要通知观察者更新。
    UpdateShouldNotify<T>? updateShouldNotify, 
    //<hl> 第一次获取数据的时候被调用。返回一个取消订阅的监听
    StartListening<T>? startListening, 
    Dispose<T>? dispose, //从widget tree中移除的时候调用
    this.builder, //构造语法糖
    bool? lazy, // create方法是否懒加载
    Widget? child,
  })  : _lazy = lazy,
  			//将上面的初始化参数传递给代理。这样可以通过实现不同的代理对象实现不同的功能。
        _delegate = _CreateInheritedProvider(
          create: create,
          update: update,
          updateShouldNotify: updateShouldNotify,
          startListening: startListening,
          dispose: dispose,
        ),
        super(key: key, child: child);

  final _Delegate<T> _delegate;
  final bool? _lazy;
  final TransitionBuilder? builder;

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    //根布局是 _InheritedProviderScope。
    return _InheritedProviderScope<T?>(
      owner: this,
      child: builder != null
          ? Builder(
              builder: (context) => builder!(context, child),
            )
          : child!,
    );
  }
}
```



## 1.2 class _InheritedProviderScope&lt;T&gt;

其中部分操作会让delegate来实现。功能更加灵活。

```dart
class _InheritedProviderScope<T> extends InheritedWidget {
  const _InheritedProviderScope({
    required this.owner,
    required this.debugType,
    required Widget child,
  })  : assert(null is T),
        super(child: child);

  final InheritedProvider<T> owner; //对应的InheritedProvider。其实是父widget
	
  //重写此方法，是否通知更新使用InheritedProvider传入的updateShouldNotify
  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
	
  //创建element
  @override
  _InheritedProviderScopeElement<T> createElement() {
    return _InheritedProviderScopeElement<T>(this);
  }
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

  @override
  InheritedElement? getElementForInheritedWidgetOfExactType<
      InheritedWidgetType extends InheritedWidget>() {
    InheritedElement? inheritedElement;
    // 尝试在父布局中获取相同类型的Provider。
    visitAncestorElements((parent) {
      inheritedElement =
          parent.getElementForInheritedWidgetOfExactType<InheritedWidgetType>();
      return false;
    });
    return inheritedElement;
  }
	
  //添加观察者
  @override
  void updateDependencies(Element dependent, Object? aspect) {
    final dependencies = getDependencies(dependent);
    
    //可以查看 SelectContext
    //typedef _SelectorAspect<T> = bool Function(T value); 
    //aspect是一个方法。则注册成为一个Selector类型的观察者。
    //通过SelectContext中的context.select 方式
    if (aspect is _SelectorAspect<T>) {
      //selectorDependency相当于是一个方法的容器。
      final selectorDependency =
          (dependencies ?? _Dependency<T>()) as _Dependency<T>;
      selectorDependency.selectors.add(aspect);
      //存储观察者对应的值是selectorDependency
      setDependencies(dependent, selectorDependency);
    } else {
      //存储观察者对应的值是Object。
      setDependencies(dependent, const Object());
    }
  }

  //通知依赖的观察者执行更新
  @override
  void notifyDependent(InheritedWidget oldWidget, Element dependent) {
    final dependencies = getDependencies(dependent);

    var shouldNotify = false;
    if (dependencies != null) {
      //可以查看 SelectContext
      //_Dependency类型，执行存储的select方法。
      if (dependencies is _Dependency<T>) {...}

    if (shouldNotify) {
      //观察者更新。
      dependent.didChangeDependencies();
    }
  }

  @override
  void update(_InheritedProviderScope<T> newWidget) {
    _isBuildFromExternalSources = true;
		//通知delegate执行 willUpdateDelegate
    _updatedShouldNotify =
        _delegateState.willUpdateDelegate(newWidget.owner._delegate);
    super.update(newWidget);
    _updatedShouldNotify = false;
  }
	
  //因为重写了 bool updateShouldNotify(InheritedWidget oldWidget)  逻辑。
  //所以这里重写updated。使用_updatedShouldNotify判断是否通知更新
  @override
  void updated(InheritedWidget oldWidget) {
    super.updated(oldWidget);
    if (_updatedShouldNotify) {
      notifyClients(oldWidget);
    }
  }

  @override
  Widget build() {
    if (widget.owner._lazy == false) {
      //非懒加载，执行一次getter方法。
      value; 
    }
    //通知代理执行 build 方法。
    _delegateState.build(
      isBuildFromExternalSources: _isBuildFromExternalSources,
    );
    _isBuildFromExternalSources = false;
    //代理的build方法可以对_shouldNotifyDependents进行赋值，决定是否要调用notifyClients
    if (_shouldNotifyDependents) {
      _shouldNotifyDependents = false;
      notifyClients(widget);
    }
    return super.build();
  }

  @override
  void unmount() {
    //调用代理的dispose
    _delegateState.dispose();
    super.unmount();
  }

  //获取value的方法，交给代理执行。
  @override
  T get value => _delegateState.value;
}

```



## 1.3. _Delegate _DelegateState

### 1.3.1 协议

```dart
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

```



### 1.3.2 _CreateInheritedProvider

```dart
class _CreateInheritedProvider<T> extends _Delegate<T> {
  
  @override
  _CreateInheritedProviderState<T> createState() =>
      _CreateInheritedProviderState();
  
}

class _CreateInheritedProviderState<T>
    extends _DelegateState<T, _CreateInheritedProvider<T>> {
  
  ////_InheritedProviderScopeElement的 取值操作 调用这里。
  @override
  T get value {
    
    bool? _debugPreviousIsInInheritedProviderCreate;
    bool? _debugPreviousIsInInheritedProviderUpdate;

    //_didInitValue 表示是否初始化完成Value。其实就是执行一次 get value
    if (!_didInitValue) {
      _didInitValue = true;
      if (delegate.create != null) {
        //执行create方法，创建值
        _value = delegate.create!(element!);
      }
      if (delegate.update != null) {
        //执行update方法，更新值
        _value = delegate.update!(element!, _value);
      }
    }
		//返回值
    return _value as T;
  }

  //_InheritedProviderScopeElement的dispose方法调用这里。
  @override
  void dispose() {
    super.dispose();
    _removeListener?.call();
    if (_didInitValue) {
      //执行dispose方法
      delegate.dispose?.call(element!, _value as T);
    }
  }
  
  //_InheritedProviderScopeElement的build方法调用这里。
  @override
  void build({required bool isBuildFromExternalSources}) {
    var shouldNotify = false;
    if (isBuildFromExternalSources &&
        _didInitValue &&
        delegate.update != null) {
      final previousValue = _value;
			
      //通过delegate._updateShouldNotify或者前后值是否相等
      _value = delegate.update!(element!, _value as T); //update实现的前提下
      if (delegate._updateShouldNotify != null) {
        shouldNotify = delegate._updateShouldNotify!(
          previousValue as T,
          _value as T,
        );
      } else {
        shouldNotify = _value != previousValue;
      }
    }
		
    
    if (shouldNotify) {
      //这里等于true。_InheritedProviderScopeElement的build种会执行 notifyClients(widget);
      element!._shouldNotifyDependents = true;
    }
  }

}

```



## 1.4 总结

其他类型的Provider都是在这个基础上实现的。了解了`InheritedProvider`其他的就很简单了。



# 2. Provider

`Provider`为`InheritedProvider`提供了.of方法。便于快速取值

```dart

class Provider<T> extends InheritedProvider<T> {
  //提供 .of 快速获取value。
  static T of<T>(BuildContext context, {bool listen = true}) {
    final inheritedElement = _inheritedElementOf<T>(context);
    if (listen) {
      context.dependOnInheritedWidgetOfExactType<_InheritedProviderScope<T?>>();
    }
    final value = inheritedElement?.value;
    return value as T;
  }

  static _InheritedProviderScopeElement<T?>? _inheritedElementOf<T>(
    BuildContext context,
  ) {
    final inheritedElement = context.getElementForInheritedWidgetOfExactType<
        _InheritedProviderScope<T?>>() as _InheritedProviderScopeElement<T?>?;
    return inheritedElement;
  }
}

```



# 3. ListenableProvider

`ChangeNotifierProvider`继承自`ListenableProvider`。先看`ListenableProvider`

```dart
class ListenableProvider<T extends Listenable?> extends InheritedProvider<T> {
  
  ListenableProvider({
    Key? key,
    required Create<T> create,
    Dispose<T>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          startListening: _startListening,
          create: create,
          dispose: dispose,
          lazy: lazy,
          builder: builder,
          child: child,
        );

  //实现了startListening。
  static VoidCallback _startListening(
    InheritedContext<Listenable?> e,
    Listenable? value,
  ) {
    //因为泛型约束 <T extends Listenable?>
    //所以value添加监听。方法是 markNeedsNotifyDependents。实现如下
    value?.addListener(e.markNeedsNotifyDependents);
    //dispose的时候，移除监听
    return () => value?.removeListener(e.markNeedsNotifyDependents);
  }
}

class _InheritedProviderScopeElement<T> extends InheritedElement
    implements InheritedContext<T> {
    @override
  //markNeedsNotifyDependents实现。其实就是调用 markNeedsBuild 执行刷新
  void markNeedsNotifyDependents() {
    if (!_isNotifyDependentsEnabled) {
      return;
    }

    markNeedsBuild();
    _shouldNotifyDependents = true;
  }
}
```



# 4. ChangeNotifierProvider

`ChangeNotifierProvider`只是修改了ListenableProvider的_dispose方法。

```dart
class ChangeNotifierProvider<T extends ChangeNotifier?>
    extends ListenableProvider<T> { 

  ChangeNotifierProvider({
    Key? key,
    required Create<T> create,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          create: create,
          dispose: _dispose,
          lazy: lazy,
          builder: builder,
          child: child,
        );
	
  //执行ChangeNotifier 的 dispose
  static void _dispose(BuildContext context, ChangeNotifier? notifier) {
    notifier?.dispose();
  }
}
```



