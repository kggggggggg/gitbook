part of '../provider.dart';

/// Adds a `select` method on [BuildContext].
extension SelectContext on BuildContext {
  /// Watch a value of type [T] exposed from a provider, and mark this widget for rebuild
  /// on changes of that value.
  ///
  /// If [T] is nullable and no matching providers are found, [watch] will
  /// return `null`. Otherwise if [T] is non-nullable, will throw [ProviderNotFoundException].
  /// If [T] is non-nullable and the provider obtained returned `null`, will
  /// throw [ProviderNullException].
  ///
  /// This allows widgets to optionally depend on a provider:
  ///
  /// ```dart
  /// runApp(
  ///   Builder(builder: (context) {
  ///     final title = context.select<Movie?, String>((movie) => movie?.title);
  ///
  ///     if (title == null) Text('no Movie found');
  ///     return Text(title);
  ///   }),
  /// );
  /// ```
  ///
  /// [select] must be used only inside the `build` method of a widget.
  /// It will not work inside other life-cycles, including [State.didChangeDependencies].
  ///
  /// By using [select], instead of watching the entire object, the listener will
  /// rebuild only if the value returned by `selector` changes.
  ///
  /// When a provider emits an update, it will call synchronously all `selector`.
  ///
  /// Then, if they return a value different from the previously returned value,
  /// the dependent will be marked as needing to rebuild.
  ///
  /// For example, consider the following object:
  ///
  /// ```dart
  /// class Person with ChangeNotifier {
  ///   String name;
  ///   int age;
  ///
  ///   // Add some logic that may update `name` and `age`
  /// }
  /// ```
  ///
  /// Then a widget may want to listen to a person's `name` without listening
  /// to its `age`.
  ///
  /// This cannot be done using `context.watch`/[Provider.of]. Instead, we
  /// can use [select], by writing the following:
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   final name = context.select((Person p) => p.name);
  ///
  ///   return Text(name);
  /// }
  /// ```
  ///
  /// It is fine to call `select` multiple times.
  R select<T, R>(R Function(T value) selector) {
    assert(widget is! SliverWithKeepAliveWidget, '''
    Tried to use context.select inside a SliverList/SliderGridView.

    This is likely a mistake, as instead of rebuilding only the item that cares
    about the selected value, this would rebuild the entire list/grid.

    To fix, add a `Builder` or extract the content of `itemBuilder` in a separate widget:

    ```dart
    ListView.builder(
      itemBuilder: (context, index) {
        return Builder(builder: (context) {
          final todo = context.select((TodoList list) => list[index]);
          return Text(todo.name);
        });
      },
    );
    ```
    ''');
    assert(widget is LayoutBuilder || debugDoingBuild, '''
Tried to use `context.select` outside of the `build` method of a widget.

Any usage other than inside the `build` method of a widget are not supported.
''');

    final inheritedElement = Provider._inheritedElementOf<T>(this);
    try {
      final value = inheritedElement?.value;
      if (value is! T) {
        throw ProviderNullException(T, widget.runtimeType);
      }

      assert(() {
        _debugIsSelecting = true;
        return true;
      }());
      final selected = selector(value);

      if (inheritedElement != null) {
        dependOnInheritedElement(
          inheritedElement,
          aspect: (T? newValue) {
            if (newValue is! T) {
              throw ProviderNullException(T, widget.runtimeType);
            }

            return !const DeepCollectionEquality()
                .equals(selector(newValue), selected);
          },
        );
      } else {
        // tell Flutter to rebuild the widget when relocated using GlobalKey
        // if no provider were found before.
        dependOnInheritedWidgetOfExactType<_InheritedProviderScope<T?>>();
      }
      return selected;
    } finally {
      assert(() {
        _debugIsSelecting = false;
        return true;
      }());
    }
  }
}
