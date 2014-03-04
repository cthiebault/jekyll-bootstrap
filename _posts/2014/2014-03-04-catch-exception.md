---
layout: post
title: "Catch-Exception ou comment tester vos exceptions"
description: ""
category: ""
tags: [java, test]
---
{% include JB/setup %}


Dans la lignée de mon billet precedent, voici un petit outil pour vérifier vos exceptions lors de vos tests unitaires :
[catch-exception](https://code.google.com/p/catch-exception).

Plusieurs solutions s'offrent à nous pour tester les exceptions :


## @Test(expected = ...)

La plus simple mais aussi la plus pauvre car on ne peut pas tester les propriétés de l'exception.

```java
public class JunitTest {
  @Test(expected = IndexOutOfBoundsException.class)
  public void testEmptyList() {
    new ArrayList().get(1);
  }
}
```

## try/catch

Le bon vieux try/catch et on vérifie les propriétés de l'exception (ici avec [Fest Assert](https://github.com/alexruiz/fest-assert-2.x)).
Attention de ne pas oublier le `Assert.fail()` pour échouer le test dans le cas ou l'exception n'est pas lancée!

```java
public class JunitTest {
  @Test
  public void testEmptyList() {
    try {
      new ArrayList().get(1);
      Assert.fail("Should throw IndexOutOfBoundsException");
    } catch(IndexOutOfBoundsException e) {
      assertThat(e)
          .isInstanceOf(IndexOutOfBoundsException.class)
          .hasMessage("Index: 1, Size: 0")
          .hasMessageStartingWith("Index: 1")
          .hasMessageEndingWith("Size: 0")
          .hasMessageContaining("Size")
          .hasNoCause();
    }
  }
}
```

## catch-exception

Voici enfin à quoi ça ressemble avec [catch-exception](https://code.google.com/p/catch-exception) dans le plus pur style BDD (Behavior Driven Development) :

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