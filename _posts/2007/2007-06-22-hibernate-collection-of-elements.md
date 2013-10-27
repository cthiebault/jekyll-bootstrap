---
layout: post
title: "Hibernate Annotations - @CollectionOfElements"
description: ""
category: ""
tags: [hibernate]
---
{% include JB/setup %}

Depuis la version 3.1 de Hibernate Annotations (il me semble), on peut enfin avoir une collection de types primitifs (String par exemple) grâce à `@CollectionOfElements`.

Avant ça, on était un peu bloqué avec des affaires comme un champ texte qui contient la liste séparée par des virgules (ou un autre caractère), ou alors une entité gérée par Hibernate qui ne contient qu'une ID et la primitive à stocker :-(

Attention cependant, l'annotation `@org.hibernate.annotations.CollectionOfElements` est spécifique à Hibernate. Elle ne fait pas partie des spécifications JPA...

```java
@Entity
public class User {
  @CollectionOfElements
  private Set<String> nicknames;
}
```