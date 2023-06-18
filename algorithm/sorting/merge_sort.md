### 归并排序（Merge Sort）

不是原地排序算法、稳定(主要看merge函数)

```cpp
void merge(int a[],int l,int r,int mid) {
    int tmp[r-l+1];

    int i = l, j = mid+1, k = 0;
    while (i <= mid && j <= r) {
        if (a[i] < a[j]) {
            tmp[k++] = a[i++];
        }else {
            tmp[k++] = a[j++];
        }
    }
    while (i <= mid) {
        tmp[k++] = a[i++];
    }
    while (j <= r) {
        tmp[k++] = a[j++];
    }
    k = 0;
    i = l;
    for (; i <= r; i++,k++) {
        a[i] = tmp[k];
    }
}

void merge_sort(int a[],int l,int r) {
    if(l>=r) return;
    int mid=(l+r)/2;
    merge_sort(a,l,mid);
    merge_sort(a,mid+1,r);
    merge(a,l,r,mid);
}


void mergesort(int a[],int l,int r) {
    merge_sort(a,l,r-1);
}
```

#### merge算法使用哨兵优化

```cpp
void merge(int a[],int l,int r,int mid) {
    int left[mid-l+2]; //左侧长度是midl-l+1 再加一个哨兵
    int right[r-mid+1];//右侧长度是r-(mid+1)+1 再加一个哨兵
    left[mid-l+1] = INT_MAX;
    right[r-mid] = INT_MAX;
    for (int i = l,k = 0; i <= mid; i++,k++) {
        left[k] = a[i];
    }
    for (int i = mid+1, k = 0; i <= r; i++,k++) {
        right[k] = a[i];
    }

    int i = 0, j = 0;
    for (int k = l; k <= r; k++) {
        if (left[i] < right[j]) {
            a[k] = left[i++];
        }else {
            a[k] = right[j++];
        }
    }
}
```

### 