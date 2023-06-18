### 冒泡排序（Bubble Sort）

原地排序、稳定 

```c++
void bubbleSort(int a[], int n) {
    for(int i = n - 1; i > 0; i--)
        for(int j = 0; j < i; j++)
            if(a[j] > a[j+1]) 
                swap(a[j], a[j+1]);
}
```

### 