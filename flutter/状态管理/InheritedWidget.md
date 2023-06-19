[【老孟Flutter】源码分析系列之InheritedWidget](https://zhuanlan.zhihu.com/p/345546970)

[一文搞懂InheritedWidget局部刷新机制](https://blog.csdn.net/jdsjlzx/article/details/123320566)

[flutter防止widget rebuild终极解决办法](https://juejin.cn/post/6844903934138515469)



重写了updated方法，调用InheritedWidget的setStatus时，不会对所有子widget调用build。而是对注册的监听调用。

```dart
class InheritedElement extends ProxyElement{
  @override
  //stylebegin {background-color: #FFFF0050;}
  void updated(InheritedWidget oldWidget) {
    if ((widget as InheritedWidget).updateShouldNotify(oldWidget)) {
      super.updated(oldWidget); --会调用notifyClients
    }
  }
  //styleend
  @override
  void notifyClients(InheritedWidget oldWidget) {
    assert(_debugCheckOwnerBuildTargetExists('notifyClients'));
    for (final Element dependent in _dependents.keys) {
      assert(() {
        // check that it really is our descendant
        Element? ancestor = dependent._parent;
        while (ancestor != this && ancestor != null) {
          ancestor = ancestor._parent;
        }
        return ancestor == this; 
      }());
      // check that it really depends on us
      assert(dependent._dependencies!.contains(this));
      notifyDependent(oldWidget, dependent); //遍历每一个监听者，调用其notifyDependent
    }
  }
}

abstract class Element extends DiagnosticableTree implements BuildContext {
	@protected
  void notifyDependent(covariant InheritedWidget oldWidget, Element dependent) {
    dependent.didChangeDependencies();
  }
  
    @mustCallSuper
  void didChangeDependencies() {
    assert(_lifecycleState == _ElementLifecycle.active); // otherwise markNeedsBuild is a no-op
    assert(_debugCheckOwnerBuildTargetExists('didChangeDependencies'));
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



每一个InheritedElement都会被存储到_inheritedWidgets字典中。

```dart
abstract class BuildContext {
	InheritedElement? getElementForInheritedWidgetOfExactType<T extends InheritedWidget>(); //抽象类声明

}


abstract class Element extends DiagnosticableTree implements BuildContext {

	PersistentHashMap<Type, InheritedElement>? _inheritedWidgets; //每个Element都有这个
	
	@mustCallSuper
  void mount(Element? parent, Object? newSlot) { //mount和activate方法会调用_updateInheritance
    _updateInheritance();
  }
  
	@mustCallSuper
  void activate() {
    ...
    _updateInheritance();
  }
  
  void _updateInheritance() {
    _inheritedWidgets = _parent?._inheritedWidgets;
  }
	
	@override
  InheritedElement? getElementForInheritedWidgetOfExactType<T extends InheritedWidget>() {
    final InheritedElement? ancestor = _inheritedWidgets == null ? null : _inheritedWidgets![T];
    return ancestor;
  }
}

class InheritedElement extends ProxyElement{
  @override
  void _updateInheritance() {
    final PersistentHashMap<Type, InheritedElement> incomingWidgets =
        _parent?._inheritedWidgets ?? const PersistentHashMap<Type, InheritedElement>.empty();
    _inheritedWidgets = incomingWidgets.put(widget.runtimeType, this); //从父widget获取，并将自己保存起来。Widget的类型为key。element为value。
  }
}

```



```dart
abstract class Element extends DiagnosticableTree implements BuildContext
	@override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({Object? aspect}) {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    final InheritedElement? ancestor = _inheritedWidgets == null ? null : _inheritedWidgets![T];
    if (ancestor != null) {
      return dependOnInheritedElement(ancestor, aspect: aspect) as T;
    }
    _hadUnsatisfiedDependencies = true;
    return null;
  }

	  @override
  InheritedWidget dependOnInheritedElement(InheritedElement ancestor, { Object? aspect }) {
    //ancestor是 InheritedElement
    _dependencies ??= HashSet<InheritedElement>();
    _dependencies!.add(ancestor); //存储当前element依赖了哪些InheritedElement
    ancestor.updateDependencies(this, aspect); //添加到InheritedElement中。
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
    _dependents[dependent] = value;  //添加到对应的map种。 这里value为空。
  }
}
```



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



> 也就是说，InheritedElement重新创建，执行build的时候，只是将注册在自己_dependents字典的element进行了更新。





## 应该在didChangeDependencies()中做什么？

一般来说，子 widget 很少会重写此方法，因为在依赖改变后 Flutter 框架也都会调用`build()`方法重新构建组件树。但是，如果你需要在依赖改变后执行一些昂贵的操作，比如网络请求，这时最好的方式就是在此方法中执行，这样可以避免每次`build()`都执行这些昂贵操作。

