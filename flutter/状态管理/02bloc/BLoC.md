# 单词

emit
vt.
发出;射出;散发(光、热、声音、气等)





https://bloclibrary.dev/#/zh-cn/coreconcepts

[【源码篇】Flutter Bloc背后的思想，一篇纠结的文章](https://juejin.cn/post/6973900070358319135#heading-7)

[flutter_bloc使用解析---骚年，你还在手搭bloc吗！](https://juejin.cn/post/6856268776510504968#heading-12)







BLoC是Business Logic Component的英文缩写，中文译为业务逻辑组件，是一种使用响应式编程来构建应用的方式。BLoC最早由谷歌的Paolo Soares和Cong Hui设计并开发，设计的初衷是为了实现页面视图与业务逻辑的分离。

BLoC依赖Stream和StreamController，组件通过Sink发送状态事件，然后再通过Stream通知其他组件进行状态刷新，事件的处理和通知更新都由BLoC负责





# 核心

## Cubit

在 Flutter 的 BLoC 架构中，Cubit 是一种特定类型的 BLoC，用于处理状态管理和业务逻辑。Cubit 类名可以翻译成“状态块”或“状态单元”。

Cubit 是 "Combination of the words Controller and BLoC Unit" 的缩写，表示它是一个负责控制状态和处理业务逻辑的单元。在 BLoC 架构中，Cubit 扮演了一个简化版的 BLoC，专注于管理和处理单一的状态。

