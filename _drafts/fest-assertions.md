---
layout: post
title: "Fest Assertions, enfin des tests lisibles"
description: ""
category: ""
tags: [java, test]
---
{% include JB/setup %}

Rien de révolutionnaire ici mais je viens de découvrir (avec beaucoup de retard) la libraire d'assertion [Fest](https://github.com/alexruiz/fest-assert-2.x) qui nous apporte beaucoup en confort de travail lors de nos test unitaires.

<!-- more -->

## JUnit

[Junit](http://junit.org) nous offre déjà des méthodes d'assertions.

```java
import static org.junit.Assert.*;

public class JunitTest {
  @Test
  public void test() {
    MyObject myObj = ...
    MyObject expectedObj = ...
    assertEquals(expectedObj, myObj);
    assertNotNull(myObj.getName());
    assertEquals(10, myObj.getChildren().size());
    assertTrue(myObj.isActive());
  }
}
```

## Hamcrest

[Hamcrest](http://hamcrest.org) nous apporte une syntaxe plus riche... mais il faut connaître les [matchers](https://code.google.com/p/hamcrest/wiki/Tutorial#A_tour_of_common_matchers) disponibles.

```java
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.CoreMatchers.*;

public class HamcrestTest {
  @Test
  public void test() {
    MyObject myObj = ...
    MyObject expectedObj = ...
    assertThat(myObj, is(expectedObj));
    assertThat(myObj.getName(), nullValue());
    assertThat((Collection) myObj.getChildren(), is(not(empty())));
    assertThat(myObj.getChildren(), hasSize(10));
    assertThat(myObj.isActive(), is(true));
  }
}
```

Pas super lisible tout ça...

## Fest Assert

[Fest](https://github.com/alexruiz/fest-assert-2.x) apporte une syntaxe "fluent" plus riche, plus lisible et surtout on peut profiter pleinement du "auto-complete" de notre IDE préféré :-)

```java
import static org.fest.assertions.api.Assertions.assertThat;

public class FestTest {
  @Test
  public void test() {
    MyObject myObj = ...
    MyObject expectedObj = ...
    assertThat(myObj).isEqualTo(expectedObj);
    assertThat(myObj.getName()).isNotNull();
    assertThat(myObj.getChildren())
      .isNotNull()
      .isNotEmpty()
      .hasSize(10);
    assertThat(myObj.isActive()).isTrue();
  }
}
```

On y voit quand même plus clair maintenant ;-)

De plus, Fest est facilement extensible. Il y a d'ailleurs quelques extension intéressantes pour [Joda Time](https://github.com/joel-costigliola/fest-joda-time-assert) et [Guava](https://github.com/joel-costigliola/fest-guava-assert).