---
layout: post
title: "NoClassDefFoundError: ReflectionManager"
description: ""
category: ""
tags: [maven, hibernate]
---
{% include JB/setup %}

En mettant à jour Hibernate Annotations à la dernière version (3.3.0.ga) via Maven2 (qui semble enfin avoir les dernières versions de Hibernate), j'avais cette exception :

```
NoClassDefFoundError: org/hibernate/annotations/common/reflection/ReflectionManager
```

C'est que le POM de Hibernate Annotations est incomplet.... Il manque la dépendance à hibernate-commons-annotations.
Donc en attendant que le POM de Hibernate Annotations soit corrigé ([http://jira.codehaus.org/browse/MAVENUPLOAD-1532]()), ajoutez dans le POM de votre projet la dépendance à hibernate-commons-annotations 3.3.0.ga.

```xml
<dependency>
  <groupId>org.hibernate</groupId>
  <artifactId>hibernate-commons-annotations</artifactId>
  <version>3.3.0.ga</version>
</dependency>
```