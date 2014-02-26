---
layout: post
title: "Catch-Exception ou comment tester vos exceptions"
description: ""
category: ""
tags: [java, test]
---
{% include JB/setup %}


Dans la lignée de mon billet precedent, voici un petit outil pour vérifier vos exceptions lors de vos tests unitaires : [catch-exception](https://code.google.com/p/catch-exception).

Si vous utilisez [Fest](https://github.com/alexruiz/fest-assert-2.x) pour vos assertions, voici à quoi ça ressemble :

```java
import static com.googlecode.catchexception.CatchException.*;
import static com.googlecode.catchexception.apis.CatchExceptionBdd.*;

public class CatchExceptionTest {
  @Test
  public void testEmptyList() {
    when(new ArrayList()).get(1);
    assertThat(caughtException())
        .isInstanceOf(IndexOutOfBoundsException.class)
        .hasMessage("Index: 1, Size: 0")
        .hasMessageStartingWith("Index: 1")
        .hasMessageEndingWith("Size: 0")
        .hasMessageContaining("Size")
        .hasNoCause();
  }
}
```