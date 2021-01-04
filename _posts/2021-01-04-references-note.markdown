---
layout: post
title:  "谈引用"
subtitle: "引用类型研究的笔记"
date:   2021-01-04
background: '/img/imac_bg.png'
---
一直以来，引用好像是个很模糊的概念，从学Java第一天，我们就可以熟练重复这句话：“Java包括基本类型和引用类型”。但是到底什么是引用呢？

>花2秒钟，思考下`Integer.TYPE`和`Integer.class`这两个的区别。

## 介绍

在Java里，什么是引用呢？在Java术语表里这么解释：

>reference  
>A data element whose value is an address.

而不知你有没有注意到，`java.lang.ref`包包括里一系列和引用有关的类，这些类有什么作用呢？

[![sP1eSK.png](https://s3.ax1x.com/2021/01/04/sP1eSK.png)](https://imgchr.com/i/sP1eSK)

来，咱们直接看下JavaDoc：

>**Package java.lang.ref Description**  
>**java.lang.ref 包描述**
>
>Provides reference-object classes, which support a limited degree of interaction with the garbage collector. A program may use a reference object to maintain a reference to some other object in such a way that the latter object may still be reclaimed by the collector. A program may also arrange to be notified some time after the collector has determined that the reachability of a given object has changed.  
>
>提供引用对象类，支持与垃圾收集器进行有限程度的交互。一个程序可以使用一个引用对象来保持对其他一些对象的引用，这样后一个对象仍然可以被收集器回收。一个程序也可以安排在收集器确定一个给定对象的可到达性改变后的一段时间内被通知。
>
>***Package Specification***  
>***包规范***
>
>A reference object encapsulates a reference to some other object so that the reference itself may be examined and manipulated like any other object. Three types of reference objects are provided, each weaker than the last: soft, weak, and phantom. Each type corresponds to a different level of reachability, as defined below. Soft references are for implementing memory-sensitive caches, weak references are for implementing canonicalizing mappings that do not prevent their keys (or values) from being reclaimed, and phantom references are for scheduling pre-mortem cleanup actions in a more flexible way than is possible with the Java finalization mechanism.  
>引用对象封装了对其他对象的引用，因此引用本身可以像其他对象一样被检查和操作。我们提供了三种类型的引用对象，每一种都比上一种弱：软、弱和幻象。每种类型对应于不同的可到达性水平，定义如下。软引用用于实现内存敏感的缓存，弱引用用于实现不妨碍其键（或值）被回收的规范化映射，幻影引用用于以比Java最终化机制更灵活的方式调度死前清理动作。
>
>Each reference-object type is implemented by a subclass of the abstract base Reference class. An instance of one of these subclasses encapsulates a single reference to a particular object, called the referent. Every reference object provides methods for getting and clearing the reference. Aside from the clearing operation reference objects are otherwise immutable, so no set operation is provided. A program may further subclass these subclasses, adding whatever fields and methods are required for its purposes, or it may use these subclasses without change.  
>每一种引用对象类型都是由抽象基Reference类的一个子类来实现的。这些子类中的一个实例封装了一个对特定对象的单一引用，称为引用对象。每个引用对象都提供了获取和清除引用的方法。除了清除操作外，引用对象在其他方面是不可改变的，所以没有提供设置操作。程序可以进一步对这些子类进行子类化，添加它所需要的任何字段和方法，或者它可以不加改变地使用这些子类。
>
>
>***Notification***  
>***通知***
>
> A program may request to be notified of changes in an object's reachability by registering an appropriate reference object with a reference queue at the time the reference object is created. Some time after the garbage collector determines that the reachability of the referent has changed to the value corresponding to the type of the reference, it will add the reference to the associated queue. At this point, the reference is considered to be enqueued. The program may remove references from a queue either by polling or by blocking until a reference becomes available. Reference queues are implemented by the ReferenceQueue class.  
>程序可以在创建引用对象时，通过在引用队列中注册一个合适的引用对象来请求通知对象的可达性变化。在垃圾收集器确定引用对象的可到达性改变为与引用类型对应的值后的一段时间，它将把引用添加到相关队列中。此时，引用被认为是已入队。程序可以通过轮询或阻塞的方式从队列中删除引用，直到有引用可用为止。引用队列由ReferenceQueue类实现。
>
>The relationship between a registered reference object and its queue is one-sided. That is, a queue does not keep track of the references that are registered with it. If a registered reference becomes unreachable itself, then it will never be enqueued. It is the responsibility of the program using reference objects to ensure that the objects remain reachable for as long as the program is interested in their referents.  
>注册的引用对象与其队列之间的关系是单方面的。也就是说，队列并不跟踪在它那里注册的引用。如果一个已注册的引用本身变得无法到达，那么它将永远不会被排队。使用引用对象的程序有责任确保只要程序对其引用感兴趣，这些对象就能保持可到达。
>
>While some programs will choose to dedicate a thread to removing reference objects from one or more queues and processing them, this is by no means necessary. A tactic that often works well is to examine a reference queue in the course of performing some other fairly-frequent action. For example, a hashtable that uses weak references to implement weak keys could poll its reference queue each time the table is accessed. This is how the WeakHashMap class works. Because the ReferenceQueue.poll method simply checks an internal data structure, this check will add little overhead to the hashtable access methods.  
>虽然有些程序会选择专门用一个线程从一个或多个队列中删除引用对象并处理它们，但这绝不是必须的。一个经常行之有效的策略是在执行其他一些相当频繁的操作的过程中检查一个引用队列。例如，一个使用弱引用来实现弱键的哈希特表可以在每次访问该表时轮询其引用队列。这就是WeakHashMap类的工作原理。因为ReferenceQueue.poll方法只是简单地检查一个内部数据结构，所以这种检查会给哈希特表的访问方法增加很少的开销。
>
>***Automatically-cleared references***  
>***自动清除的引用***
>
>Soft and weak references are automatically cleared by the collector before being added to the queues with which they are registered, if any. Therefore soft and weak references need not be registered with a queue in order to be useful, while phantom references do. An object that is reachable via phantom references will remain so until all such references are cleared or themselves become unreachable.  
>软引用和弱引用在被添加到它们所注册的队列（如果有的话）之前，会被收集器自动清除。因此，软引用和弱引用不需要在队列中注册才有用，而幻象引用则有用。通过幻影引用可以到达的对象将保持这样的状态，直到所有这些引用被清除或者它们本身变得不可到达。
>
>***Reachability***  
>***可到达性***
>
>Going from strongest to weakest, the different levels of reachability reflect the life cycle of an object. They are operationally defined as follows:  
>从最强到最弱，不同级别的可到达性反映了一个物体的生命周期。它们在操作上定义如下：
>
>- An object is strongly reachable if it can be reached by some thread without traversing any reference objects. A newly-created object is strongly reachable by the thread that created it.
>- 如果一个对象可以被某个线程到达而不需要遍历任何参考对象，那么这个对象就是强可到达的。一个新创建的对象是由创建它的线程强到达的。
>- An object is softly reachable if it is not strongly reachable but can be reached by traversing a soft reference.
>- 如果一个对象不是强可达的，但可以通过遍历一个软引用来达到，那么这个对象就是软可达的。
>- An object is weakly reachable if it is neither strongly nor softly reachable but can be reached by traversing a weak reference. When the weak references to a weakly-reachable object are cleared, the object becomes eligible for finalization.
>- 如果一个对象既不是强可到达也不是软可到达，但可以通过遍历一个弱引用来到达，那么这个对象就是弱可到达的。当弱可达对象的弱引用被清除时，对象就有资格被最终化。
>- An object is phantom reachable if it is neither strongly, softly, nor weakly reachable, it has been finalized, and some phantom reference refers to it.
>- 如果一个对象既不是强、软、弱可到达，它已经被最终化，并且有一些幻象引用指向它，那么这个对象就是幻象可到达的。
>- Finally, an object is unreachable, and therefore eligible for reclamation, when it is not reachable in any of the above ways.
>- 最后，当一个对象在上述任何一种方式下都无法到达时，该对象就是不可到达的，因此可以被回收。

好吧，这个翻译又臭又长。

*我总结一下：*  
强引用引用的对象在垃圾回收时候不会回收。软引用在发生OOM之前会回收，弱引用发生gc时候就会回收，虚引用无法拿到对象。

*引用类型有几种？*  
强引用、软应用、弱引用、虚引用。

看完还有些含糊，再看一篇文章吧。  
[https://web.archive.org/web/20061130103858/http://weblogs.java.net/blog/enicholas/archive/2006/05/understanding_w.html](https://web.archive.org/web/20061130103858/http://weblogs.java.net/blog/enicholas/archive/2006/05/understanding_w.html)

我这里构造几个案例，测试一下每种引用类型：

## 强引用

这个不需要什么案例，平时使用的普通引用就是强引用。

```java
Object o = new Object();
```

## 软引用

```java
public class SoftRefDemo {

    public static void main(String[] args) {
        SoftRefObject softRef = testSoftRef();
        System.out.println(softRef.get());
        byte[] array = new byte[15*1024*1024];
        System.out.println(softRef.get());
    }

    static SoftRefObject testSoftRef() {
        return new SoftRefObject(new BigObject());
    }
    
    static class BigObject {
        byte[] array = new byte[20*1024*1024];

        @Override
        public String toString() {
            return "BigObject{" +
                    "array size=" + array.length +
                    '}';
        }
    }

    static class SoftRefObject extends SoftReference<BigObject> {

        public SoftRefObject(BigObject o) {
            super(o);
        }
    }
}
```

这里其实就是在`WeakReference`里放一个比较大的对象的引用，在别的地方请求分配一块比较大的内存而内存不足时，看gc是不是会回收`ThreadLocalMap`中的引用对象。

首先，设置`-Xmx100M`，执行结果如下：

```
BigObject{array size=20971520}
BigObject{array size=20971520}
```

重新设置`-Xmx40M`，执行结果为：

```
BigObject{array size=20971520}
null
```

可以看到，在分配一个大对象而空间不足时候，软引用执行的对象被回收而无法获取。

## 弱引用

```java

/**
 * 
 */
public class WeakRefDemo {

    public static void main(String[] args) {
        WeakRefObject weakRef = testWeakRef();
        System.out.println(weakRef.get());
        System.out.println(weakRef.get());
        System.gc();
        System.out.println(weakRef.get());
    }

    static WeakRefObject testWeakRef() {
        return new WeakRefObject(new Object());
    }
    
    static class WeakRefObject extends WeakReference<Object> {

        public WeakRefObject(Object o) {
            super(o);
        }
    }
    
}
```

执行结果如下：

```
java.lang.Object@6f496d9f
java.lang.Object@6f496d9f
null
```

可以看到，发生垃圾回收之后，弱引用就无法再获取到对象了。

## 虚引用

至于虚引用，直接看下代码你就懂了，依靠``。

```java
public class PhantomReference<T> extends Reference<T> {

    /**
     * Returns this reference object's referent.  Because the referent of a
     * phantom reference is always inaccessible, this method always returns
     * <code>null</code>.
     *
     * @return  <code>null</code>
     */
    public T get() {
        return null;
    }

    /**
     * Creates a new phantom reference that refers to the given object and
     * is registered with the given queue.
     *
     * <p> It is possible to create a phantom reference with a <tt>null</tt>
     * queue, but such a reference is completely useless: Its <tt>get</tt>
     * method will always return null and, since it does not have a queue, it
     * will never be enqueued.
     *
     * @param referent the object the new phantom reference will refer to
     * @param q the queue with which the reference is to be registered,
     *          or <tt>null</tt> if registration is not required
     */
    public PhantomReference(T referent, ReferenceQueue<? super T> q) {
        super(referent, q);
    }

}
```
