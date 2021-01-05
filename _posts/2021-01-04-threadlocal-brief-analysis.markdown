---
layout: post
title:  "Java-ThreadLocal简析"
subtitle: "ThreadLocal代码分析"
date:   2021-01-04
background: '/img/imac_bg.png'
---

翻看JDK8的新特性，看到这样的一条。说ThreadLocal在JDK8有新的更改，这里主要都是和lambda表达相关的一些更改。那就来对比看下修改了什么。  
JDK7的`ThreadLocal`地址点[这里](https://github.com/openjdk-mirror/jdk7u-jdk/blob/master/src/share/classes/java/lang/ThreadLocal.java)；  
JDK8的`ThreadLocal`地址点[这里](https://github.com/frohoff/jdk8u-jdk/blob/master/src/share/classes/java/lang/ThreadLocal.java)。

[![sPQC1U.png](https://s3.ax1x.com/2021/01/04/sPQC1U.png)](https://imgchr.com/i/sPQC1U)


```java
    /**
     * Creates a thread local variable. The initial value of the variable is
     * determined by invoking the {@code get} method on the {@code Supplier}.
     *
     * @param <S> the type of the thread local's value
     * @param supplier the supplier to be used to determine the initial value
     * @return a new thread local variable
     * @throws NullPointerException if the specified supplier is null
     * @since 1.8
     */
    public static <S> ThreadLocal<S> withInitial(Supplier<? extends S> supplier) {
        return new SuppliedThreadLocal<>(supplier);
    }
    
    /**
     * An extension of ThreadLocal that obtains its initial value from
     * the specified {@code Supplier}.
     */
    static final class SuppliedThreadLocal<T> extends ThreadLocal<T> {

        private final Supplier<? extends T> supplier;

        SuppliedThreadLocal(Supplier<? extends T> supplier) {
            this.supplier = Objects.requireNonNull(supplier);
        }

        @Override
        protected T initialValue() {
            return supplier.get();
        }
    }
    
```

可以看到新增的这个方法，主要是对于`Supplier`的支持。  
这里说个小工具，叫[SourceGraph](https://chrome.google.com/webstore/detail/sourcegraph/dgjhfomjieaadpoljlnidmbgkdffpack)，可以GitHub上比较方便地看源码。  
对比发现变动很小，除了一些地方增加了泛型以及上述的部分，其余逻辑没有变化。所以下面的分析对于JDK7、8是通用的。

---

# ThreadLocal的使用

直接使用官方实例：

```java
    public class ThreadId {
        // Atomic integer containing the next thread ID to be assigned
        private static final AtomicInteger nextId = new AtomicInteger(0);

        // Thread local variable containing each thread's ID
        private static final ThreadLocal<Integer> threadId =
                ThreadLocal.withInitial(() -> nextId.getAndIncrement());

        // Returns the current thread's unique ID, assigning it if necessary
        public static int get() {
            return threadId.get();
        }
    }
```

本例在类加载时初始化`ThreadLocal`，使用时调用`get`方法获取`threadId`。

查看`ThreadLocal`，只有以下几个方法供使用：
[![sSG5md.png](https://s3.ax1x.com/2021/01/02/sSG5md.png)](https://imgchr.com/i/sSG5md)

# 源码部分



`ThreadLocal`的使用比较简单，主要就是`get()`和`set()`这两个方法。  

先看`get`方法：

```java
    /**
     * 返回当前线程的这个线程本地变量的副本中的值，如果该变量对当
     * 前线程没有值，则首先将其初始化为调用initialValue方法返回的
     * 值。如果该变量对当前线程没有值，则首先将其初始化为调用
     * initialValue方法返回的值。
     *
     * @return 线程本地变量中当前线程的值
     */
    public T get() {
        Thread t = Thread.currentThread();
        ThreadLocalMap map = getMap(t);
        if (map != null) {
            ThreadLocalMap.Entry e = map.getEntry(this);
            if (e != null) {
                @SuppressWarnings("unchecked")
                T result = (T)e.value;
                return result;
            }
        }
        return setInitialValue();
    }
```

```java
     /**
     * 获取与ThreadLocal关联的map。在InheritableThreadLocal中被重写。
     *
     * @param  t 当前线程
     * @return 指定map
     */
    ThreadLocalMap getMap(Thread t) {
        return t.threadLocals;
    }
```

`#getMap`这个方法是从当前线程中取出`ThreadLocalMap`，所以线程`Thread`对象里面肯定是有`ThreadLocalMap`属性。
[![sPMoff.png](https://s3.ax1x.com/2021/01/04/sPMoff.png)](https://imgchr.com/i/sPMoff) 


第一次获取`ThreadLocalMap`时线程里并不存在`ThreadLocalMap`，则使用`#setInitialValue`方法初始化该值。  

在本例中，初始化的`ThreadLocal`类型为扩展类`SuppliedThreadLocal`，故`#initialValue`方法为`SuppliedThreadLocal`中的方法。该类在上面有提到过，这是JDK新增加的。所以这里`T value`的值为`nextId.getAndIncrement()`执行的结果，即`1`。

```java
    /**
     * set()的变体，用于建立初始值。当用户覆盖了set()方法时，代替set()使用。
     *
     * @return 初始值
     */
    private T setInitialValue() {
        T value = initialValue();
        Thread t = Thread.currentThread();
        ThreadLocalMap map = getMap(t);
        if (map != null)
            map.set(this, value);
        else
            createMap(t, value);
        return value;
    }
```

`#setInitialValue`的JavaDoc说到，该方法是`#set`的变体，这里稍微看下`set`方法：

```java
    /**
     * 将当前线程的这个线程局部变量的副本设置为指定值。 
     * 大多数子类将不需要重写这个方法，仅仅依靠{@link #initialValue}方法来
     * 设置thread-locals的值。
     *
     * @param value 要存储在当前线程的线程本地副本中的值。
     */
    public void set(T value) {
        Thread t = Thread.currentThread();
        // 从当前线程中取出ThreadLocalMap
        ThreadLocalMap map = getMap(t);
        if (map != null)
            map.set(this, value);
        else
            createMap(t, value);
    }
    
```

初始化这里的重点就是`#createMap`方法，可以看到，`ThreadLocalMap`是以`ThreadLocal`作为key，`Object`作为 value。稍微有点绕，这里稍作总结：每个线程对象`Thread`里保存了一份`ThreadLocalMap`对象，`ThreadLocalMap`以`ThreadLocal`作为key，value为保存的数据。`ThreadLocal`封装了对该map的initial、get、set、remove等操作。

首次创建线程的`ThreadLocalMap`的方法：
```java
    void createMap(Thread t, T firstValue) {
        t.threadLocals = new ThreadLocalMap(this, firstValue);
    }
    
    static class ThreadLocalMap {
        //...
        /**
         * 构造一个新的map，初始包含（firstKey，firstValue）。
         * ThreadLocalMaps是懒惰构造的，所以我们只有在至少有一个
         * 条目要放进去的时候才会创建一个。
         */
        ThreadLocalMap(ThreadLocal<?> firstKey, Object firstValue) {
            table = new Entry[INITIAL_CAPACITY];
            int i = firstKey.threadLocalHashCode & (INITIAL_CAPACITY - 1);
            table[i] = new Entry(firstKey, firstValue);
            size = 1;
            setThreshold(INITIAL_CAPACITY);
        }
        //...
    }
    
```

既然以`ThreadLocal`作为map的key，可以看到构造方法里面hash桶位置的计算是通过`firstKey.threadLocalHashCode & (INITIAL_CAPACITY - 1)`，hash值与`(2^n)-1`进行与运算是老办法了，不过多解释，`ThreadLocal`的hash值就是介个`firstKey.threadLocalHashCode`，该值有`final`修饰，在对象创建时初始化，初始化方法如下：

```java
    /**
     * ThreadLocals依赖于附加到每个线程（Thread.threadLocals和InheritableThreadLocals）
     * 的每线程线性探针哈希映射。ThreadLocal对象充当key，通过threadLocalHashCode搜索。
     * 这是一个自定义的哈希码（仅在ThreadLocalMaps内有用），它可以消除连续构造的
     * ThreadLocals被同一线程使用的常见情况下的碰撞，而在不太常见的情况下仍然表现良好。。
     */
    private final int threadLocalHashCode = nextHashCode();
```

而哈希表是用`Entry`类型的数组保存，`Entry`是`ThreadLocalMap`的内部类：

```java
        static class Entry extends WeakReference<ThreadLocal<?>> {
            /** 与该ThreadLocal相关联的值。*/
            Object value;

            Entry(ThreadLocal<?> k, Object v) {
                super(k);
                value = v;
            }
        }
```
而`Entry`继承了`WeakReference`，并用该`ThreadLocal`作为key，`ThreadLocal`为`WeakReference`的`referent`。使用`WeakReference#get()`方法，获取到的是`ThreadLocal`。如果不了解`WeakReference`可以看下我这篇文章:[八宝粥的博客：谈引用](https://wangzzleo.xyz/2021/01/04/references-note.html)

`Thread`、`ThreadLocal`、`ThreadLocalMap`、`Entry`的UML类关系图如下（供参考）：

[![sSrIBV.png](https://s3.ax1x.com/2021/01/02/sSrIBV.png)](https://imgchr.com/i/sSrIBV)

那是不是说，使用`ThreadLocal`，若发生gc，放到`ThreadLocalMap`中的对象将被回收？不是的，我们要搞明白两点：
1. `ThreadLocalMap`的`Entry`继承了`WeakReference`，但只有`ThreadLocal`的引用传递给`WeakReference`的构造方法，只有当`ThreadLocal`弱可达时，发生gc时key才将被回收掉。而value依然是Entry的强引用，Entry又作为`ThreadLocalMap`的`table`数组存在（`private Entry[] table;`）,`ThreadLocalMap`又是`thread`的属性。也就是只要线程活着，如果不做处理，`value`就一直存活。而这个特殊处理就是调用`ThreadLocal#remove()`方法。

```java
     public void remove() {
         ThreadLocalMap m = getMap(Thread.currentThread());
         if (m != null)
             m.remove(this);
     }
    static class ThreadLocalMap {
        // 省略部分代码
        private void remove(ThreadLocal<?> key) {
            Entry[] tab = table;
            int len = tab.length;
            int i = key.threadLocalHashCode & (len-1);
            for (Entry e = tab[i];
                 e != null;
                 e = tab[i = nextIndex(i, len)]) {
                if (e.get() == key) {
                    e.clear();
                    expungeStaleEntry(i);
                    return;
                }
            }
        }
        
        
        private int expungeStaleEntry(int staleSlot) {
            Entry[] tab = table;
            int len = tab.length;

            // expunge entry at staleSlot
            tab[staleSlot].value = null;
            tab[staleSlot] = null;
            // 省略后续代码
        }
        
    } 
```
2. 咱们一般使用`ThreadLocal`时候都是这样的姿势：```public static ThreadLocal<Long> waitNanosLocal = new ThreadLocal<Long>();```，也就是说`ThreadLocal`是强可达，此时不用考虑`ThreadLocal`在内存不足时被当作垃圾回收的情况。

而如果我们某种使用的场景下（`ThreadLocal`我使用的比较少，不知道是哪个场景，我看有的框架代码里有别的使用情况，但是不是很了解，就不在这里当作例子），`ThreadLocal`不再强可达，那此时要注意，发生gc后，`ThreadLocal`被回收，即`ThreadLocalMap`的`Entry`的key变成null，但是value依旧强可达，若是使用完后没有调用`ThreadLocal#remove`方法，而线程又一直存活，就有可能内存溢出。不过也不是绝对的，使用`set`、`get`后，都会清除key为null的Entry。


另外说一点和`ThreadLocalMap`相关的。`ThreadLocalMap`的初始容量是16，负载因子是`2/3`。
另外，hash冲突了怎么办？

>常见解决hash冲突的几种办法：
>1. 开放地址法
>    - 线性探测再散列：冲突发生时，顺序查看表中下一单元，直到找出一个空单元或查遍全表。
>    - 冲突发生时，在表的左右进行跳跃式探测，比较灵活
>    - 伪随机探测再散列：
>2. 再哈希法
>    - 同时构造多个不同的哈希函数，当哈希地址Hi=RH1（key）发生冲突时，再计算Hi=RH2（key）……，直到冲突不再产>>生。这种方法不易产生聚集，但增加了计算时间。
>3. 链地址法
>    - 这种方法的基本思想是将所有哈希地址为i的元素构成一个称为同义词链的单链表，并将单链表的头指针存在哈希表>的第i个单元中，因而查找、插入和删除主要在同义词链中进行。链地址法适用于经常进行插入和删除的情况。
>4. 建立公共溢出区
>    - 将哈希表分为基本表和溢出表两部分，凡是和基本表发生冲突的元素，一律填入溢出表。

这里其实就是用的开放地址法的线性探测再散列。代码如下：








---
这里我简单翻译（DeepL翻译）了`ThreadLocalMap`的JavaDoc，可以对比着看。

```java
    /**
     * ThreadLocalMap是一个定制化的hash map，只适用于维护线程本地值。
     * 在ThreadLocal类之外不能进行操作。该类是包私有的，以允许在Thread类中声明字段。
     * 为了帮助处理非常大的和长时间的使用，哈希表条目使用WeakReferences作为键。
     * 但是，由于未使用引用队列，因此仅在表空间不足时，才保证删除过时的条目。
     */
    static class ThreadLocalMap {
        /**
         * 这个hash map中的entry继承自WeakReference，使用它的主ref字段作为键（
         * 它总是一个ThreadLocal对象）。 请注意，空键（即 entry.get() == null）
         * 意味着该键不再被引用，所以该条目可以从表中删除。 在下面的代码中，这
         * 种条目被称为 "陈旧条目" (stale entries)。
         */
        static class Entry extends WeakReference<ThreadLocal<?>> {
            /** 与该ThreadLocal相关联的值。 */
            Object value;

            Entry(ThreadLocal<?> k, Object v) {
                super(k);
                value = v;
            }
        }
        /**
         * 初始容量 -- 必须是2的幂
         */
        private static final int INITIAL_CAPACITY = 16;
        /**
         * table根据需要调整大小。
         * table.length必须始终是2的幂。
         */
        private Entry[] table;
        /**
         * 表中的条目数。
         */
        private int size = 0;
        /**
         * 下一次resize时候size的值
         */
        private int threshold; // 默认 0
        /**
         * 设置调整大小的阈值，以维持最差的2/3负载系数。
         */
        private void setThreshold(int len) {
            threshold = len * 2 / 3;
        }
        /**
         * Increment i modulo len.
         */
        private static int nextIndex(int i, int len) {
            return ((i + 1 < len) ? i + 1 : 0);
        }
        /**
         * Decrement i modulo len.
         */
        private static int prevIndex(int i, int len) {
            return ((i - 1 >= 0) ? i - 1 : len - 1);
        }
        /**
         * 构造一个新的map，初始包含（firstKey，firstValue）。
         * ThreadLocalMaps是懒惰构造的，所以我们只有在至少有一个
         * 条目要放进去的时候才会创建一个。
         */
        ThreadLocalMap(ThreadLocal<?> firstKey, Object firstValue) {
            table = new Entry[INITIAL_CAPACITY];
            int i = firstKey.threadLocalHashCode & (INITIAL_CAPACITY - 1);
            table[i] = new Entry(firstKey, firstValue);
            size = 1;
            setThreshold(INITIAL_CAPACITY);
        }
        /**
         * 从给定的父map中构建一个新的map，包括所有可继承的ThreadLocal。
         * 仅由createInheritedMap调用。
         *
         * @param parentMap 与父线程相关联的map。
         */
        private ThreadLocalMap(ThreadLocalMap parentMap) {
            Entry[] parentTable = parentMap.table;
            int len = parentTable.length;
            setThreshold(len);
            table = new Entry[len];

            for (int j = 0; j < len; j++) {
                Entry e = parentTable[j];
                if (e != null) {
                    @SuppressWarnings("unchecked")
                    ThreadLocal<Object> key = (ThreadLocal<Object>) e.get();
                    if (key != null) {
                        Object value = key.childValue(e.value);
                        Entry c = new Entry(key, value);
                        int h = key.threadLocalHashCode & (len - 1);
                        while (table[h] != null)
                            h = nextIndex(h, len);
                        table[h] = c;
                        size++;
                    }
                }
            }
        }
        
        /**
         * 获取与key相关联的条目。这个方法本身只处理快速路径：直接命中现有的key。
         * 否则就会转发到getEntryAfterMiss。这样做的目的是为了最大限度地提高直接
         * 命中的性能，部分原因是使这个方法易于内联。
         *
         * @param  key thread local 对象
         * @return 和key关联的Enter, 如果没有这个条目，则为空。
         */
        private Entry getEntry(ThreadLocal<?> key) {
            int i = key.threadLocalHashCode & (table.length - 1);
            Entry e = table[i];
            if (e != null && e.get() == key)
                return e;
            else
                return getEntryAfterMiss(key, i, e);
        }
        
        /**
         * 当键没有直接在哈希槽中找到时使用的getEntry方法的版本。
         *
         * @param  key thread local 对象
         * @param  i 哈希码表索引
         * @param  e table[i]中的Entry
         * @return 和key关联的Enter, 如果没有这个条目，则为空。
         */
        private Entry getEntryAfterMiss(ThreadLocal<?> key, int i, Entry e) {
            Entry[] tab = table;
            int len = tab.length;

            while (e != null) {
                ThreadLocal<?> k = e.get();
                if (k == key)
                    return e;
                if (k == null)
                    expungeStaleEntry(i);
                else
                    i = nextIndex(i, len);
                e = tab[i];
            }
            return null;
        }
        
        /**
         * 设置与键相关的值。
         *
         * @param key thread local 对象
         * @param value 要设置的值
         */
        private void set(ThreadLocal<?> key, Object value) {

            // 我们没有像使用get()那样使用快速路径，因为使用set()创建新条目
            // 和替换现有条目至少一样常见，在这种情况下，快速路径会经常失败。
            // ps：其实这儿我没看懂

            Entry[] tab = table;
            int len = tab.length;
            int i = key.threadLocalHashCode & (len-1);

            for (Entry e = tab[i];
                 e != null;
                 e = tab[i = nextIndex(i, len)]) {
                ThreadLocal<?> k = e.get();

                if (k == key) {
                    e.value = value;
                    return;
                }

                if (k == null) {
                    replaceStaleEntry(key, value, i);
                    return;
                }
            }

            tab[i] = new Entry(key, value);
            int sz = ++size;
            if (!cleanSomeSlots(i, sz) && sz >= threshold)
                rehash();
        }
        
        /**
         * 删除key的Entry
         */
        private void remove(ThreadLocal<?> key) {
            Entry[] tab = table;
            int len = tab.length;
            int i = key.threadLocalHashCode & (len-1);
            for (Entry e = tab[i];
                 e != null;
                 e = tab[i = nextIndex(i, len)]) {
                if (e.get() == key) {
                    e.clear();
                    expungeStaleEntry(i);
                    return;
                }
            }
        }
        
        /**
         * 用指定的键的条目替换在set操作中遇到的陈旧条目。 
         * 无论指定的键是否已经存在条目，value参数中传递的值都会存储在条目中。
         *
         * 作为副作用，此方法会删除“run”中包含该陈旧条目的所有陈旧条目。
         * (run是两个空槽之间的entry序列。)
         *
         * @param  key 键
         * @param  value 与键关联的值
         * @param  staleSlot 在搜索键时遇到的第一个陈旧条目的索引。
         */
        private void replaceStaleEntry(ThreadLocal<?> key, Object value,
                                       int staleSlot) {
            Entry[] tab = table;
            int len = tab.length;
            Entry e;

            // 备份以检查当前运行中是否有过时的条目。
            // 我们一次清理整个运行，以避免由于垃圾收集器释放成堆的引用
            //（即每当收集器运行时）而导致的连续增量重新哈希。
            int slotToExpunge = staleSlot;
            for (int i = prevIndex(staleSlot, len);
                 (e = tab[i]) != null;
                 i = prevIndex(i, len))
                if (e.get() == null)
                    slotToExpunge = i;

            // 找到运行的key或尾部的空槽，以先出现的为准。
            for (int i = nextIndex(staleSlot, len);
                 (e = tab[i]) != null;
                 i = nextIndex(i, len)) {
                ThreadLocal<?> k = e.get();

                // 如果我们找到了key，那么我们需要将其与陈旧的条目交换，
                // 以维持哈希表的顺序。然后可以将新的陈旧槽，或者在它上
                // 面遇到的其他陈旧槽发送到expungeStaleEntry中，以删除
                // 或重新处理运行中的所有其他条目。
                if (k == key) {
                    e.value = value;

                    tab[i] = tab[staleSlot];
                    tab[staleSlot] = e;

                    // 如果存在，则从前一个陈旧条目开始删除。
                    if (slotToExpunge == staleSlot)
                        slotToExpunge = i;
                    cleanSomeSlots(expungeStaleEntry(slotToExpunge), len);
                    return;
                }

                // 如果我们在逆向扫描中没有找到过时的条目，那么在扫描key时
                // 看到的第一个过时条目就是运行中仍然存在的第一个条目。
                if (k == null && slotToExpunge == staleSlot)
                    slotToExpunge = i;
            }

            // 如果没有找到key，则在陈旧的槽中放入新的条目。
            tab[staleSlot].value = null;
            tab[staleSlot] = new Entry(key, value);

            // 运行中有其他的陈旧条目，则删除
            if (slotToExpunge != staleSlot)
                cleanSomeSlots(expungeStaleEntry(slotToExpunge), len);
        }

        /**
         * 通过重新hash位于staleSlot和下一个空槽之间任何可能发生碰撞的条目来删除陈旧条目。
         * 这也会删除在尾部空槽之前遇到的任何其他陈旧条目。参见Knuth，第6.4节
         *
         * @param staleSlot 已知有空键的槽的索引
         * @return staleSlot之后的下一个空槽的索引。
         * (所有介于staleSlot和这个槽之间的槽都将会被检查以清除).
         */
        private int expungeStaleEntry(int staleSlot) {
            Entry[] tab = table;
            int len = tab.length;

            // expunge entry at staleSlot
            tab[staleSlot].value = null;
            tab[staleSlot] = null;
            size--;

            // 遇到null之前重hash
            Entry e;
            int i;
            for (i = nextIndex(staleSlot, len);
                 (e = tab[i]) != null;
                 i = nextIndex(i, len)) {
                ThreadLocal<?> k = e.get();
                if (k == null) {
                    e.value = null;
                    tab[i] = null;
                    size--;
                } else {
                    int h = k.threadLocalHashCode & (len - 1);
                    if (h != i) {
                        tab[i] = null;

                        // 与Knuth 6.4算法R不同的是，我们必须扫描到空，因为多个条目可能已经陈旧。
                        while (tab[h] != null)
                            h = nextIndex(h, len);
                        tab[h] = e;
                    }
                }
            }
            return i;
        }
        
        /**
         * 启发式扫描某些单元以查找陈旧条目。
         * 当一个新元素被添加或另一个陈旧的元素被删除时，就会调用这个方法。
         * 它执行对数扫描，作为不扫描（速度快，但会保留垃圾）和与元素数量
         * 成正比的扫描次数之间的平衡，这样可以找到所有的垃圾，但会导致一
         * 些插入需要O(n)时间。
         *
         * @param i 已知不持有陈旧条目的位置。扫描从i之后的元素开始。
         *
         * @param n 扫描控制：扫描log2(n)个单元格，除非发现一个过时的条目，
         * 在这种情况下，将扫描log2(table.length)-1个额外的单元格。
         * 当从insertions调用时，这个参数是元素的数量，但当从
         * replaceStaleEntry调用时，它是表的长度。(注意：所有这一切都可以通
         * 过加权n而不是直接使用log n来改变，使其更多或更少的攻击性。
         * 但这个版本简单、快速，而且似乎很好用。)
         *
         * @return 如何有任意过时条目被移除时返回true
         */
        private boolean cleanSomeSlots(int i, int n) {
            boolean removed = false;
            Entry[] tab = table;
            int len = tab.length;
            do {
                i = nextIndex(i, len);
                Entry e = tab[i];
                if (e != null && e.get() == null) {
                    n = len;
                    removed = true;
                    i = expungeStaleEntry(i);
                }
            } while ( (n >>>= 1) != 0);
            return removed;
        }
        
        /**
         * 重新包装和/或重新确定table的大小。首先扫描整个表，删除过时的条目。
         * 如果这样做还不足以缩小表的大小，则将表的大小增加一倍。
         */
        private void rehash() {
            expungeStaleEntries();

            // Use lower threshold for doubling to avoid hysteresis
            if (size >= threshold - threshold / 4)
                resize();
        }
        
        /**
         * 将table容量增加一倍
         */
        private void resize() {
            Entry[] oldTab = table;
            int oldLen = oldTab.length;
            int newLen = oldLen * 2;
            Entry[] newTab = new Entry[newLen];
            int count = 0;

            for (int j = 0; j < oldLen; ++j) {
                Entry e = oldTab[j];
                if (e != null) {
                    ThreadLocal<?> k = e.get();
                    if (k == null) {
                        e.value = null; // Help the GC
                    } else {
                        int h = k.threadLocalHashCode & (newLen - 1);
                        while (newTab[h] != null)
                            h = nextIndex(h, newLen);
                        newTab[h] = e;
                        count++;
                    }
                }
            }

            setThreshold(newLen);
            size = count;
            table = newTab;
        }
        
         /**
         * 删除表中所有陈旧的条目。
         */
        private void expungeStaleEntries() {
            Entry[] tab = table;
            int len = tab.length;
            for (int j = 0; j < len; j++) {
                Entry e = tab[j];
                if (e != null && e.get() == null)
                    expungeStaleEntry(j);
            }
        }
    }
```


