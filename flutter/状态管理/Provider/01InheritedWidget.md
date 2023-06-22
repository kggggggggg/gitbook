# 1. InheritedWidget的使用



首先创建一个`ShareDataWidget`继承自`InheritedWidget`

```dart
class ShareDataWidget extends InheritedWidget {
  const ShareDataWidget({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  final int data; //需要在子树中共享的数据，保存点击次数

  //定义一个便捷方法，方便子树中的widget获取共享数据
  static ShareDataWidget? of(BuildContext context) {
    //return context.dependOnInheritedWidgetOfExactType<ShareDataWidget>();
    return context
        .getElementForInheritedWidgetOfExactType<ShareDataWidget>()
        ?.widget as ShareDataWidget;
  }

  //该回调决定当data发生变化时，是否通知子树中依赖data的Widget
  @override
  bool updateShouldNotify(ShareDataWidget old) {
    return old.data != data;
  }
}
```



实现一个子组件`_TestWidget`，在其`build`方法中引用`ShareDataWidget`中的数据。同时，在其`didChangeDependencies()` 回调中打印日志

```dart

class _TestWidget extends StatefulWidget {
  @override
  __TestWidgetState createState() => __TestWidgetState();
}

class __TestWidgetState extends State<_TestWidget> {
  @override
  Widget build(BuildContext context) {
    //使用InheritedWidget中的共享数据
    //stylebegin {background-color: #FFFF0050;}
    return Text(ShareDataWidget.of(context)!.data.toString());
    //styleend
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //父或祖先widget中的InheritedWidget改变(updateShouldNotify返回true)时会被调用。
    //如果build中没有依赖InheritedWidget，则此回调不会被调用。
    print("Dependencies change");
  }
}
```



`InheritedWidgetTestRoute`创建一个按钮，每点击一次，就将`ShareDataWidget`的值自增

```dart
class InheritedWidgetTestRoute extends StatefulWidget {
  ...
}

class _InheritedWidgetTestRouteState extends State<InheritedWidgetTestRoute> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
//stylebegin {background-color: #FFFF0050;}
      child: ShareDataWidget( //使用ShareDataWidget
//styleend
        data: count,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: _TestWidget(), //子widget中依赖ShareDataWidget
            ),
            ElevatedButton(
              child: const Text("Increment"),
              //每点击一次，将count自增，然后重新build,ShareDataWidget的data将被更新
              onPressed: () => setState(() => ++count),
            )
          ],
        ),
      ),
    );
  }
}
```



# 2. InheritedWidget的原理

## 2.1 _inheritedWidgets 

```dart
abstract class Element extends DiagnosticableTree implements BuildContext
  
  Element? _parent;
  PersistentHashMap<Type, InheritedElement>? _inheritedWidgets;
  Set<InheritedElement>? _dependencies;
  bool _hadUnsatisfiedDependencies = false;

	/// Add this element to the tree in the given slot of the given parent.
	@mustCallSuper
  void mount(Element? parent, Object? newSlot) {
    ...
    _updateInheritance();
    ...
  }

	/// Transition from the "inactive" to the "active" lifecycle state.
	@mustCallSuper
  void activate() {
    ...
    _updateInheritance();
		...
  }

  void _updateInheritance() {
		...
    _inheritedWidgets = _parent?._inheritedWidgets;
  }
}

class InheritedElement extends ProxyElement{
  
  final Map<Element, Object?> _dependents = HashMap<Element, Object?>();
  
  @override
  void _updateInheritance() {
    final PersistentHashMap<Type, InheritedElement> incomingWidgets =
        _parent?._inheritedWidgets ?? const PersistentHashMap<Type, InheritedElement>.empty();
    _inheritedWidgets = incomingWidgets.put(widget.runtimeType, this);
  }
}
```

### _inheritedWidgets

`void _updateInheritance()`主要负责 `_inheritedWidgets`赋值

1. 调用时机: `mount`和`activate`方法。
2. 对于普通的`Element`，`_inheritedWidgets`只是从`_parent`读取。
3. `InheritedElement`中，`_inheritedWidgets`从`_parent`读取为空的话，会创建一个。并存储。key为`widget.runtimeType`,value为当前的`InheritedElement`。

> _inheritedWidgets 方便观察者快速获取到对应的InheritedElement，从而获取数据。



### _dependents

`InheritedElement`中的`_dependents`，存储了观察者

> 需要更新时，遍历观察者，通知观察者更新



### _dependencies

`  Set<InheritedElement>? _dependencies;`观察者存储了他所依赖的 `InheritedElement`。

> `class _UbiquitousInheritedElement extends InheritedElement`中有用到。
>
> 去掉了，_dependents。这样保证创建过程更快速。但是更新会变慢。
>
> [可以看这里](#_UbiquitousInheritedElement)



## 2.2 注册依赖关系

`T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({ Object? aspect });`

```dart
abstract class Element extends DiagnosticableTree implements BuildContext
	@override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({Object? aspect}) {
    assert(_debugCheckStateIsActiveForAncestorLookup());
  	//<hl> 1. 查找InheritedElement类型的祖先节点
    final InheritedElement? ancestor = _inheritedWidgets == null ? null : _inheritedWidgets![T];
    if (ancestor != null) {
      return dependOnInheritedElement(ancestor, aspect: aspect) as T;
    }
    _hadUnsatisfiedDependencies = true;
    return null;
  }

	  @override
  InheritedWidget dependOnInheritedElement(InheritedElement ancestor, { Object? aspect }) {
    //<hl> 2. 创建_dependencies用来存储当前element依赖了哪些InheritedElement
    _dependencies ??= HashSet<InheritedElement>();
    _dependencies!.add(ancestor); //
    ancestor.updateDependencies(this, aspect); //添加到InheritedElement中。
    //<hl> 4. 返回 ancestor（InheritedWidget类型的祖先节点）
    return ancestor.widget as InheritedWidget;
  }
}

class InheritedElement extends ProxyElement{
  
  final Map<Element, Object?> _dependents = HashMap<Element, Object?>();
  
 	   @protected
  void updateDependencies(Element dependent, Object? aspect) {
    setDependencies(dependent, null);
  }
  
    @protected
  void setDependencies(Element dependent, Object? value) {
    //<hl> 3. InheritedElement中的_dependents，用来存储对应的观察者。
    _dependents[dependent] = value;  //添加到对应的map种。 这里value为空。
  }
}
```



依赖关系：

`Element`（观察者）中的`_dependencies`存储了使用到的`InheritedElement`

`InheritedElement`的`_dependents`存储了注册的观察者`Element`



## 2.3 更新监听

```dart
class InheritedElement extends ProxyElement{
  //重写了updated方法
  @override
  void updated(InheritedWidget oldWidget) {
    if ((widget as InheritedWidget).updateShouldNotify(oldWidget)) {
      super.updated(oldWidget); --super调用了notifyClients
    }
  }
	
  //遍历每一个监听者
  @override
  void notifyClients(InheritedWidget oldWidget) {
    for (final Element dependent in _dependents.keys) {
      notifyDependent(oldWidget, dependent); 
    }
  }
  
  //调用坚挺着didChangeDependencies方法
  @protected
  void notifyDependent(covariant InheritedWidget oldWidget, Element dependent) {
    dependent.didChangeDependencies();
  }
}

abstract class Element extends DiagnosticableTree implements BuildContext {
	
  //标记为_dirty
  @mustCallSuper
  void didChangeDependencies() {
    markNeedsBuild();
  }
  
  void markNeedsBuild() {
    if (dirty) {
      return;
    }
    _dirty = true;
    owner!.scheduleBuildFor(this);
  }
}
 
class BuildOwner {
void scheduleBuildFor(Element element) {
    _dirtyElements.add(element); //添加到dirtyElements列表中。
    element._inDirtyList = true; 
  }
}
```



# 3.总结

> _inheritedWidgets存储InheritedElement，方便观察者快速找到对应的InheritedElement
>
> _dependents 存储观察者，InheritedElement通过遍历通知观察者更新



- 本身所有的Element都维护一个map。（可以认为是一个全局的，因为会先从_parent获取）
  - PersistentHashMap<Type, InheritedElement>? _inheritedWidgets;
  - element类型为key。
- 每一个InheritedElement实例对象都会维护一个map。
  - final Map<Element, Object?> _dependents = HashMap<Element, Object?>();
  - 以调用者的element为key，value可以为空。
- 当创建一个InheritedElement，调用mount时就会加入到_inheritedWidgets中。
  - 查找的时候通过类型直接在map中找出。
- 调用dependOnInheritedWidgetOfExactType获取值的时候
  - _inheritedWidgets中找到对应的InheritedElement
  - 将当前对象存储到InheritedElement对应的_dependents字典中
  - 返回对应的InheritedElement
- 需要更新，调用InheritedWidget的update的时候
  - _dependents.keys获取存储的element，并调用其`didChangeDependencies`方法。
  - didChangeDependencies --> markNeedsBuild --> _dirty = true;



# 4. 应该在didChangeDependencies()中做什么？

一般来说，子 widget 很少会重写此方法，因为在依赖改变后 Flutter 框架也都会调用`build()`方法重新构建组件树。但是，如果你需要在依赖改变后执行一些昂贵的操作，比如网络请求，这时最好的方式就是在此方法中执行，这样可以避免每次`build()`都执行这些昂贵操作。



# 5. 其他

## _UbiquitousInheritedElement

```dart
/// An [InheritedElement] that has hundreds of dependencies but will
/// infrequently change. This provides a performance tradeoff where building
/// the [Widget]s is faster but performing updates is slower.
///
/// |                     | _UbiquitousInheritedElement | InheritedElement |
/// |---------------------|------------------------------|------------------|
/// | insert (best case)  | O(1)                         | O(1)             |
/// | insert (worst case) | O(1)                         | O(n)             |
/// | search (best case)  | O(n)                         | O(1)             |
/// | search (worst case) | O(n)                         | O(n)             |
///
/// Insert happens when building the [Widget] tree, search happens when updating
/// [Widget]s.
class _UbiquitousInheritedElement extends InheritedElement {
  /// Creates an element that uses the given widget as its configuration.
  _UbiquitousInheritedElement(super.widget);

  @override
  void setDependencies(Element dependent, Object? value) {
    // This is where the cost of [InheritedElement] is incurred during build
    // time of the widget tree. Omitting this bookkeeping is where the
    // performance savings come from.
    assert(value == null);
  }

  @override
  Object? getDependencies(Element dependent) {
    return null;
  }

  @override
  void notifyClients(InheritedWidget oldWidget) {
    _recurseChildren(this, (Element element) {
      if (element.doesDependOnInheritedElement(this)) {
        notifyDependent(oldWidget, element);
      }
    });
  }

  static void _recurseChildren(Element element, ElementVisitor visitor) {
    element.visitChildren((Element child) {
      _recurseChildren(child, visitor);
    });
    visitor(element);
  }
}
```





## 参考

>  [【老孟Flutter】源码分析系列之InheritedWidget](https://zhuanlan.zhihu.com/p/345546970)
>
> [一文搞懂InheritedWidget局部刷新机制](https://blog.csdn.net/jdsjlzx/article/details/123320566)
>
> [flutter防止widget rebuild终极解决办法](https://juejin.cn/post/6844903934138515469)

