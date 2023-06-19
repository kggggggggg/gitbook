```


//stylebegin {background-color: #FFFF0050;}
  void updated(InheritedWidget oldWidget) {
    if ((widget as InheritedWidget).updateShouldNotify(oldWidget)) {
      super.updated(oldWidget); --会调用notifyClients
    }
  }
//styleend


```