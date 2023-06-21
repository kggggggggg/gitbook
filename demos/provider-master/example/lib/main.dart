// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// This is a reimplementation of the default Flutter application using provider + [ChangeNotifier].

void main() {
  print("main begin");
  runApp(
    /// Providers are above [MyApp] instead of inside it, so that tests
    /// can use [MyApp] while mocking the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Counter()),
        InheritedProvider<Counter1>(
          create: ((context) {
            print("InheritedProvider create");
            return Counter1();
          }),
          update: (context, value) {
            //每次获取数据的时候，执行一次update。 创建(第一次获取值)和执行build的时候
            //也就是说当前的Provider更新的时候，执行此方法
            print("InheritedProvider update ${value}");
            // context.watch<Counter>().count; 这里watch的话，每次加一都会更新这个Provider。然后执行到这里。
            return value!;
          },
          updateShouldNotify: (context, value) => true,
          startListening: (element, value) {
            //首次执行 get value  获取值的时候执行
            //_removeListener ??= delegate.startListening?.call(element!, _value as T);
            //_removeListener ?? 表示_removeListener不为空，不执行。
            print("InheritedProvider startListening value = ${value}");

            //_removeListener 。disopose时调用
            return () {
              print("InheritedProvider endListening value = ${value}");
            };
          },
          dispose: (context, value) {
            /// The value will be disposed of when [InheritedProvider] is removed from
            /// the widget tree.  Widget将要被移除的时候
            print("InheritedProvider dispose value = ${value}");
          },
          // _InheritedProviderScopeElement 的build方法中，如果是懒加载，则等首次获取值的时候才初始化值。否则在build方法中初始化(通过 get value 的getter方法)
          lazy: false,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// Mix-in [DiagnosticableTreeMixin] to have access to [debugFillProperties] for the devtool
// ignore: prefer_mixin
class Counter with ChangeNotifier, DiagnosticableTreeMixin {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }

  /// Makes `Counter` readable inside the devtools by listing all of its properties
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('count', count));
  }
}

class Counter1 with ChangeNotifier, DiagnosticableTreeMixin {
  int _count = 99;

  int get count => _count;

  void reduce() {
    _count--;
    notifyListeners();
  }

  /// Makes `Counter` readable inside the devtools by listing all of its properties
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('count', count));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Text('You have pushed the button this many times:'),

            /// Extracted as a separate widget for performance optimization.
            /// As a separate widget, it will rebuild independently from [MyHomePage].
            ///
            /// This is totally optional (and rarely needed).
            /// Similarly, we could also use [Consumer] or [Selector].
            Count(),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 56,
          height: 124,
        child: Column(
          children: [
            FloatingActionButton(
              key: const Key('increment_floatingActionButton'),

              /// Calls `context.read` instead of `context.watch` so that it does not rebuild
              /// when [Counter] changes.
              onPressed: () => context.read<Counter>().increment(),
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
            Container(
              height: 12,
            ),
            FloatingActionButton(
              key: const Key('reduce_floatingActionButton'),
              onPressed: () {
                context.read<Counter1>().reduce();
              },
              tooltip: 'reduce',
              child: const Icon(Icons.remove),
            ),
          ],
        ),
      ),
    );
  }
}

class Count extends StatelessWidget {
  const Count({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("Count build");
    return Column(
      children: [
        Builder(builder: (context) {
          print("Builder counter");
          return Text(
            '${context.watch<Counter>().count}',
            key: const Key('counterState'),
            style: Theme.of(context).textTheme.headlineMedium,
          );
        }),
        Builder(builder: (context) {
          print("Builder counter1");
          return Text(
            '${context.watch<Counter1>().count}',
            key: const Key('counter1State'),
            style: Theme.of(context).textTheme.headlineMedium,
          );
        }),
      ],
    );
  }
}
