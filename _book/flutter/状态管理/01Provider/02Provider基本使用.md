## Provider优势

我们为什么要用`Provider`而不是直接使用`InheritedWidget`，我们看下官方介绍

> - 简化的资源分配与处置
> - 懒加载
> - 创建新类时减少大量的模板代码
> - 支持 DevTools
> - 更通用的调用 [InheritedWidget](https://api.flutter-io.cn/flutter/widgets/InheritedWidget-class.html) 的方式（参考 [Provider.of](https://pub.flutter-io.cn/documentation/provider/latest/provider/Provider/of.html)/[Consumer](https://pub.flutter-io.cn/documentation/provider/latest/provider/Consumer-class.html)/[Selector](https://pub.flutter-io.cn/documentation/provider/latest/provider/Selector-class.html)）
> - 提升类的可扩展性，整体的监听架构时间复杂度以指数级增长（如 [ChangeNotifier](https://api.flutter-io.cn/flutter/foundation/ChangeNotifier-class.html)， 其复杂度为 O(N)）



## 常见的几种Provider

### Provider

`Provider`是最基本的**Provider**组件

```dart
// This class is what Provider will work with.
// It will _provide_ an instance of the class to any widget
// in the tree that cares about it. 
class Person {
  Person({this.name, this.age});

  final String name;
  final int age;
}

// Here, we are running an app as you'd expect with any Flutter app
// But, we're also wrapping `MyApp` in a widget called 'Provider'
// Importantly, `Provider` is itself a widget, so it can live in the widget tree.
// This class uses a property called `create` to make an instance of `Person`
// whenever it's needed by a widget in the tree.
// The object returned by the function passed to `create` is what the rest of our app
// has access to. 
void main() {
  runApp(
    Provider(
      create: (_) => Person(name: "Yohan", age: 25),
      child: MyApp(),
    ),
  );
}


// Just a plain ol' StatelessWidget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

// Again, just a stateless widget
class MyHomePage extends StatelessWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Class'),
      ),
      body: Center(
        child: Text(
          // this string is where we use Provider to fetch the instance
          // of `Person` created above in the `create` property
          '''
          Hi ${Provider.of<Person>(context).name}!
          You are ${Provider.of<Person>(context).age} years old''',
        ),
      ),
    );
  }
}
```





### ListenableProvider

ChangeNotifierProvider继承自ListenableProvider且对应的ChangeNotifier继承自listenable；算是ListenableProvider的子类；ValueNotifier继承自ChangeNotifier也与ChangeNotifierProvider相似；

使用**ChangeNotifierProvider**和**ValueListenableProvider**绑定实体类时需要注意分别继承对应的**ChangeNotifier**和**ValueNotifier**；

所以ChangeNotifierProvider只是对ListenableProvider的进一步封装。从`ValueNotifier`到`ChangeNotifier`的监听。



### ChangeNotifierProvider

它跟`Provider`组件不同，`ChangeNotifierProvider`会监听模型对象的变化，而且当数据改变时，它也会重建`Consumer`（消费者）

```dart
class Person with ChangeNotifier {
  Person({this.name, this.age});

  final String name;
  int age;

  void increaseAge() {
    this.age++;
    notifyListeners();
  }
}

// here, you can see that the [ChangeNotifierProvider]
// is "wired up" exactly like the vanilla [Provider]
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => Person(name: "Yohan", age: 25),
      child: MyApp(),
    ),
  );
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Class'),
      ),
      body: Center(
        child: Text( 
          // reading this data is exactly like it was in
          // the previous lesson             
          '''
          Hi ${Provider.of<Person>(context).name;}!
          You are ${Provider.of<Person>(context).age} years old''',
        ),
      ),  
      floatingActionButton: FloatingActionButton(
        // this is where there's a difference.
        // when the FAB is tapped, it will call `Person.icreaseAge()` on the
        // person instance that was created by provider.     
        onPressed: () => Provider.of<Person>(context, listen: false).increaseAge(),
      ),
    );
  }
}
```



### ValueListenableProvider



### FutureProvider

用于提供在组件树中准备好使用其值时可能尚未准备好的值，主要是确保空值不会传递给任何子组件，而且`FutureProvider`有一个初始值，子组件可以使用该`Future`值并告诉子组件使用新的值来进行重建。

```dart
class Person {
  Person({this.name, this.age});

  final String name;
  int age;
}

class Home {
  final String city = "Portland";

  Future<String> get fetchAddress {
    final address = Future.delayed(Duration(seconds: 2), () {
      return '1234 North Commercial Ave.';
    });

    return address;
  }
}

void main() {
  runApp(
    Provider<Person>(
      create: (_) => Person(name: 'Yohan', age: 25),
      child: FutureProvider<String>(
        create: (context) => Home().fetchAddress,
        initialData: "fetching address...",
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Future Provider"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Consumer<Person>(
            builder: (context, Person person, child) {
              return Column(
                children: <Widget>[
                  Text("User profile:"),
                  Text("name: ${person.name}"),
                  Text("age: ${person.age}"),
                  Consumer<String>(builder: (context, String address, child) {
                    return Text("address: $address");
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

```







**注意：**

- `FutureProvider`只会重建一次
- 默认显示初始值
- 然后显示`Future`值
- 最后不会再次重建



### StreamProvider

`StreamProvider`提供流值，是围绕`StreamBuilder`，所提供的值会在传入的时候替换掉新值。和`FutureProvider`一样，主要的区别在于值会根据多次触发重新构建UI。

```dart
class Person {
  Person({this.name, this.initialAge});

  final String name;
  final int initialAge;

  Stream<String> get age async* {
    var i = initialAge;
    while (i < 85) {
      await Future.delayed(Duration(seconds: 1), () {
        i++;
      });
      yield i.toString();
    }
  }
}

void main() {
  runApp(
    StreamProvider<String>(
      create: (_) => Person(name: 'Yohan', initialAge: 25).age,
      initialData: 25.toString(),
      catchError: (_, error) => error.toString(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Future Provider"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Consumer<String>(
            builder: (context, String age, child) {
              return Column(
                children: <Widget>[
                  Text("Watch Yohan Age..."),
                  Text("name: Yohan"),
                  Text("age: $age"),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
```







### ProxyProvider

ProxyProviders有几种

- ProxyProvider
- ChangeNotifierProxyProvider
- ListenableProxyProvider



当我们有多个模型的时候，会有模型依赖另一个模型的情况，在这种情况下，我们可以使用`ProxyProvider`从另一个提供者获取值，然后将其注入到另一个提供者中。



```dart
testWidgets('ListenableProxyProvider2', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ProxyProvider2<A, B, Combined>(
              create: (_) => const Combined(),
              update: (context, a, b, previous) =>
                  Combined(context, previous, a, b),
            )
          ],
          child: mockConsumer,
        ),
      );
  
  当a,b有变化时，都会通知到ListenableProxyProvider2<A, B, Combined>。
```



#### ChangeNotifierProxyProvider

和`ProxyProvider`原理一样，唯一的区别在于它构建和同步`ChangeNotifier`的`ChangeNotifierProvider`，当提供者数据变化时，将会重构UI。

```dart
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Person with ChangeNotifier {
  Person({this.name, this.age});

  final String name;
  int age;

  void increaseAge() {
    this.age++;
    notifyListeners();
  }
}

class Job with ChangeNotifier {
  Job(
    this.person, {
    this.career,
  });

  final Person person;
  String career;
  String get title {
    if (person.age >= 28) return 'Dr. ${person.name}, $career PhD';
    return '${person.name}, Student';
  }
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Person>(create: (_) => Person(name: 'Yohan', age: 25)),
        ChangeNotifierProxyProvider<Person, Job>( //当person变化，也会通知到Job。
          create: (BuildContext context) => Job(Provider.of<Person>(context, listen: false)),
          update: (BuildContext context, Person person, Job job) => Job(person, career: 'Vet'),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Class'),
      ),
      body: Align(
        alignment: Alignment.center,
        child: Container(
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Hi, may name is ${context.select((Job j) => j.person.name)}',
                style: Theme.of(context).textTheme.headline6,
              ),
              Text('Age: ${context.select((Job j) => j.person.age)}'),
              Text(context.watch<Job>().title),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Provider.of<Person>(context, listen: false).increaseAge(),
      ),
    );
  }
}

```



#### ListenableProxyProvider

`ListenableProxyProvider`是`ListenableProvider`的一个变体，但是在使用上和`ChangeNotifierProvider`效果惊人的一致



### MultiProvider

继承自`Nested`

```dart
class MultiProvider extends Nested {
  MultiProvider({
    Key? key,
    required List<SingleChildWidget> providers,
    Widget? child,
    TransitionBuilder? builder,
  }) : super(
          key: key,
          children: providers,
          child: builder != null
              ? Builder(
                  builder: (context) => builder(context, child),
                )
              : child,
        );
}

test(){
  MultiProvider(
        providers: [
          PA,
          PB,
          PC
      ),
          child: XXX(),
}
PA的child是PB。PB的child是PC。PC的child是XXX。 
```



### .value constructors

之前使用Provider时候，都是使用create()进行创建一个新值，倘若我们想要观测一个已经存在的实例化对象时候，就不可以这样了。
这时候需要使用Provider.value的方式或者其它类的.value,例如ChangeNotifierProvider.value
该方法也可以将内部的某个值提供给其子类



总结：在 Provider 中，`.value` 方法用于手动提供一个固定的数值作为数据源，而不使用 Provider 类自动创建或管理数据源。



### 总结

`Provider`为我们提供了非常多的提供者。但我们比较常用的是`ChangeNotifierProvider`、`MultiProvider`、`ChangeNotifierProxyProvider`，关于其他的提供者可根据自己的实际应用场景来。



## 四种消费者

### Provider.of

```
Provider.of<CountNotifier1>(context).increment();
```



```dart
static T of<T>(BuildContext context, {bool listen = true}) {
    assert(
      context.owner!.debugBuilding ||   //widget正在构建
          listen == false ||            //widget如果不是构建过程，说明是类似点击按钮取值，不用listen。
          debugIsInInheritedProviderUpdate,
      '''
Tried to listen to a value exposed with provider, from outside of the widget tree.

This is likely caused by an event handler (like a button's onPressed) that called
Provider.of without passing `listen: false`.

To fix, write:
Provider.of<$T>(context, listen: false);

It is unsupported because may pointlessly rebuild the widget associated to the
event handler, when the widget tree doesn't care about the value.

The context used was: $context
''',
    );
    
    ...
      
      

child: ElevatedButton(
  onPressed: (){
    Provider.of<CountNotifier1>(context).increment(); //报错
    Provider.of<CountNotifier1>(context, listen: false).increment();
  },
  child: Text("点击加1"),
),
```



### Consumer

`Consumber`只是在`Widget`中调用了`Prvoider.of`，并将其构造实现委托给了构造器

```dart
class Consumer<T> extends SingleChildStatelessWidget {
  Consumer({
    Key? key,
    required this.builder,
    Widget? child,
  }) : super(key: key, child: child);

  final Widget Function(
    BuildContext context,
    T value,
    Widget? child,
  ) builder;

  //数据更新的时候会调用buildWithChild。 child保存在Consumer属性中。不会更新。
  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return builder(
      context,
      Provider.of<T>(context),
      child,
    );
  }
}
```



### Selector

选择器与消费者相似，但对何时调用小部件`build`方法提供了一些精细的控制。简而言之，`selector`是一个消费者，它允许您从您关心的模型中准确定义哪些属性。

```dart
class Person with ChangeNotifier {
  Person({this.name, this.age});

  final String name;
  int age;

  void increaseAge() {
    this.age++;
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => Person(name: "Yohan", age: 25),
      child: MyApp(),
    ),
  );
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<Person, String>(
      selector: (BuildContext context, Person person) => person.name,
      builder: (context, String name, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text("${name} -- ${Provider.of<Person>(context).age} yrs old"),
          ),
          body: child,
        );
      },
      child: Center(
        child: Text('Hi this represents a huge widget! Like a scrollview with 500 children!'),
      ),
    );
  }
}
```



###  Context Extension

`InheritedContext`是`Provider`内置扩展了`BuildContext`，它不保存了组件在树中自己位置的引用，我们在上面的案例中见到`Provider.of<CountNotifier1>(context，listen: false)`，其实这个`of`方法就是使用`Flutter`查找树并找到`Provider`子类型为`CountNotifier1`而已。



- **BuildContext.read:** `BuildContext.read<CountNotifier1>()`可以替换掉`Provider.of<CountNotifier1>(context，listen: false)`，它会找到`CountNotifier1`并返回它。
- **BuildContext.watch:** `BuildContext.watch<CountNotifier1>()`可以替换掉`Provider.of<CountNotifier1>(context，listen: false)`，看起来和`read`没有什么不同，但是使用`watch`你就不需要在使用`Consumer`。
- **BuildContext.select:** `BuildContext.select<CountNotifier1>()`可以替换掉`Provider.of<CountNotifier1>(context，listen: false)`，看起来和`watch`也没有什么不同，但是使用`select`你就不需要在使用`Selector`。



# layz

lazy为true

create在获取值的时候才会执行



# 防止重复刷新







# 参考

[README](https://github.com/rrousselGit/provider/blob/master/resources/translations/zh-CN/README.md)

[proxy-provider](https://flutterbyexample.com/lesson/what-is-provider)

[flutter_by_example_static](https://github.com/ericwindmill/flutter_by_example_static)

[使用 `Nested` 处理 flutter 嵌套过深](https://www.jianshu.com/p/0687b41dc80c)