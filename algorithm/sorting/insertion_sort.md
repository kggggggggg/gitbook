### 插入排序（Insertion Sort）

原地排序、稳定

[c++插入排序算法.html](./c++插入排序算法.html)

```cPP
void InsertSort(int a[], int n) {
    for (int i = 1; i < n; i++) {
        int j = i-1;
        int v = a[i];
        while (j >= 0 && a[j] > v) {
            a[j+1] = a[j];
            j--;
        }
        a[j+1] = v;
    }
}
```

```cPP
void insertionSort(int a[], int n) {
  if (n <= 1) return;
  for (int i = 1; i < n; ++i) {
    int value = a[i];
    int j = i - 1;
    for (; j >= 0; --j) {
      if (a[j] > value) {
        a[j+1] = a[j];
      } else {
        break;
      }
    }
    a[j+1] = value; // 插入数据
  }
}
```

#### 