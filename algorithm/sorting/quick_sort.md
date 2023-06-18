## 快速排序算法（Quicksort）

> 原地排序、不稳定

### 方式一

> 因为固定pivot是取得左边的值，所以while时，要先从右边找；

```cpp
void quickSort(int a[], int head, int tail) {
    int low = head;
    int high = tail;
    int pivot = a[low];
    while (low<high) {
        //先从右边找
        while (low < high && pivot <= a[high]) high--;
        a[low] = a[high];
        while (low < high && pivot >= a[low]) low++;
        a[high]=a[low];
    }
    a[low] = pivot;
    if(low>head+1) quickSort(a,head,low-1);
    if(high<tail-1) quickSort(a,high+1,tail);
}
```

### 方式二

> 1、因为先从右边找。
>
> 2、而最终因为low == high。
>
> 3、所以现在low和high的值小于a[head]。
>
> 4、判断条件 a[head] >= a[low] 导致a[head]位置不会变
>
>         也就是分割点位置不变，始终在head位置
>
> 5、所以最后需要再进行一次交换  swap(a[low], a[head]);

```cpp
void quickSort(vector<int>& a, int head, int tail) {
    if (head >= tail) {
        return;
    }
    int low = head;
    int high = tail;
    while (low<high) {
        //先从右边找
        while (low < high && a[head] <= a[high]) high--;
        while (low < high && a[head] >= a[low]) low++;
        swap(a[low], a[high]);
    }
    swap(a[low], a[head]);
    quickSort(a,head,low-1);
    quickSort(a,high+1,tail);
}
```

### 方法三

```cpp
int Paritition1(int A[], int low, int high) {
    int pivot = A[low];
    while (low < high) {
        while (low < high && A[high] >= pivot) {
            --high;
        }
        A[low] = A[high];
        while (low < high && A[low] <= pivot) {
            ++low;
        }
        A[high] = A[low];
    }
    A[low] = pivot;
    return low;
}
//快排母函数
void quickSort(int A[], int low, int high)  {
    if (low < high) {
        int pivot = Paritition1(A, low, high);
        quickSort(A, low, pivot - 1);
        quickSort(A, pivot + 1, high);
    }
}
```

