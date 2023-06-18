### 选择排序（Selection Sort）

原地排序、不稳定

```
void selectionSort(int a[], int n) {
    for (int i = 0; i < n; i++) {
        for (int j = i; j < n; j++) {
            if (a[i] > a[j]) {
                swap(a[i], a[j]);
            }
        }
    }
}
```

[通俗易懂讲解 选择排序.html](./通俗易懂讲解 选择排序.html)

```
void selectSort(int a[], int n) {
    for (int i = 0; i < n; i++) {
        int min = i;
        for (int j = i; j < n; j++) {
            if (a[j] < a[min]) {
                min = j;
            }
        }
        swap(a[i], a[min]);
    }
}
```

### 