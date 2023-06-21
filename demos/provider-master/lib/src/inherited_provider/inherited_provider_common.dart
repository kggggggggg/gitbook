part of '../provider.dart';

/// A function that returns true when the update from [previous] to [current]
/// should notify listeners, if any.
///
/// See also:
///
///   * [InheritedWidget.updateShouldNotify]
typedef UpdateShouldNotify<T> = bool Function(T previous, T current);

/// A function that creates an object of type [T].
///
/// See also:
///
///  * [Dispose], to free the resources associated to the value created.
typedef Create<T> = T Function(BuildContext context);

/// A function that disposes an object of type [T].
///
/// See also:
///
///  * [Create], to create a value that will later be disposed of.
typedef Dispose<T> = void Function(BuildContext context, T value);

/// A callback used to start the listening of an object and return a function
/// that cancels the subscription.
///
/// It is called the first time the value is obtained (through
/// [InheritedContext.value]). And the returned callback will be called
/// when [InheritedProvider] is unmounted or when the it is rebuilt with a new
/// value.
///
/// See also:
///
/// - [InheritedProvider]
/// - [DeferredStartListening], a variant of this typedef for more advanced
///   listening.
typedef StartListening<T> = VoidCallback Function(
    InheritedContext<T?> element,
    T value,
    );

bool _debugIsSelecting = false;