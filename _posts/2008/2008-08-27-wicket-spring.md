---
layout: post
title: "Wicket & Spring"
description: ""
category: ""
tags: [wicket, spring]
---
{% include JB/setup %}

Depuis le temps que j'entends parler de Wicket, je me lance enfin dans l'aventure :-)
J'essayerais ici de décrire les différentes étapes de la migration d'une application [Spring MVC 2.5](http://springframework.org) / [Weblow 2.0](http://springframework.org/webflow) / [Hibernate](http://www.hibernate.org) vers [Wicket 1.3.4](http://wicket.apache.org).

<!-- more -->

Pour démarrer, je suis parti des articles du [blog Xebia France](http://blog.xebia.fr) qui sont vraiment bien fait... Merci à eux!

* [Hands on Wicket 1 : Quickstart & config](http://blog.xebia.fr/2008/02/14/hands-on-wicket-partie-1)
* [Hands on Wicket 2 : Page, model & navigation](http://blog.xebia.fr/2008/02/22/hands-on-wicket-partie-2)
* [Hands on Wicket 3 : Session, formulaire & Spring](http://blog.xebia.fr/2008/03/07/hands-on-wicket-partie-3)
* [Hands on Wicket 4 : Templating & internationalisation](http://blog.xebia.fr/2008/04/23/hands-on-wicket-partie-4)

## Premier problème : Spring!

Après avoir ajouté mes dépendances dans le POM.xml, Spring en peut loader les contextes :

```
ERROR org.springframework.web.context.ContextLoader.initWebApplicationContext:205 - Context initialization failed
org.springframework.beans.factory.BeanDefinitionStoreException: Unexpected exception parsing XML document from class path resource [applicationContext-service.xml]; nested exception is java.lang.NoSuchMethodError: org.springframework.util.ClassUtils.isPresent(Ljava/lang/String;Ljava/lang/ClassLoader;)Z
Caused by:
java.lang.NoSuchMethodError: org.springframework.util.ClassUtils.isPresent(Ljava/lang/String;Ljava/lang/ClassLoader;)Z
 at org.springframework.context.annotation.AnnotationConfigUtils.<clinit>(AnnotationConfigUtils.java:75)
 at org.springframework.context.annotation.AnnotationConfigBeanDefinitionParser.parse(AnnotationConfigBeanDefinitionParser.java:45)
```

La librairie wicket-spring dépend de spring 2.0 et non de la dernière version 2.5.x. Il faut donc juste exclure le Spring de Wicket comme suit dans le pom.xml du projet :

```xml
<dependency>
 <groupId>org.apache.wicket</groupId>
 <artifactId>wicket-spring</artifactId>
 <version>${wicket.version}</version>
 <exclusions>
  <exclusion>
   <groupId>org.springframework</groupId>
   <artifactId>spring</artifactId>
  </exclusion>
 </exclusions>
</dependency>
```

## Internationalisation

Tous mes traductions sont dans un seul fichier properties et je ne veux pas les séparer par page ou déplacer et renommer ce fichier à la racine de l'application Wicket.

En cherchant un peu, je suis tombé sur ce blog :
[http://www.jroller.com/eyallupu/entry/spring_as_a_message_provider]()

Il propose ici d'utiliser le MessageSource de Spring directement dans Wicket. Ça marche parfaitement bien :-)