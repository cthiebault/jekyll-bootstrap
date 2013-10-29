---
layout: post
title: "Convention over configuration - Spring MVC"
description: ""
category: ""
tags: [spring]
---
{% include JB/setup %}

Convention plutôt que configuration en bon français : il est inutile de préciser des détails lorsqu'ils respectent des conventions établies (Wikipedia). On en entend de plus en plus parler avec la popularité grandissante de Ruby On Rails.

Le but de ce post est de réduire un peu la taille des fichiers de configuration de Spring qui peuvent vite devenir trés gros...

<!-- more -->

## Autowire des controlleurs

Pour commencer on peut utiliser le autowiring lors de la définition de nos beans. Spring va effectuer les résolutions automatiquement soit par type, soit par nom.
Dans l'exemple suivant, je définis le autowire par defaut pour tout le contexte :

**default-servlet.xml**

```xml
<beans xmlns="http://www.springframework.org/schema/beans" default-autowire="byName">
  <bean id="userController" class="x.y.z.userController" autowire="default" />
</beans>
```

L'utilisation du autowire n'est pas recommandée par les développeurs de Spring pour les projets de grande taille mais je pense vraiment qu'au niveau du MVC ca ne pose pas de problèmes.

## Mapping des controlleurs

La plupart du temps les URLs ressemblent aux noms des controlleurs... En utilisant le `ControllerClassNameHandlerMapping` Spring va chercher dans la liste des controlleurs enregistrés ceux dont le nom (moins le suffixe Controller) match l'url.
Par exemple :

* `WelcomeController <--> '/welcome*'`
* `DisplayShoppingCartController <--> '/displayshoppingcart*'`

Dans le cas de MultiActionController , le mapping se fera comme suit :

* `UserController <--> '/user/*'`
* `UserController.edit(...) <--> '/user/edit.htm'`

## Mapping des vues (jsp ou autres)

Pour les parties plus statique des sites, il est idiot de créer un controlleur par page...
La classe `UrlFilenameViewController` transforme une URL en chemin sur le disque pointant vers la vue correspondante :

`/users/list.htm --> /users/list`

## Conclusion

Si on met tout ca ensemble dans la configuration du servlet de Spring, on obtient :

**default-servlet.xml**

```xml
<beans xmlns="http://www.springframework.org/schema/beans" default-autowire="byName">

  <bean id="userController" class="x.y.z.userController" autowire="default" />

  <!-- jsp view resolver that points to /jsp folder -->
  <bean id="viewResolver" class="org.springframework.web.servlet.view.InternalResourceViewResolver">
    <property name="viewClass" value="org.springframework.web.servlet.view.JstlView" />
    <property name="prefix" value="/jsp/" />
    <property name="suffix" value=".jsp" />
  </bean>

  <bean id="fileNameViewController" class="org.springframework.web.servlet.mvc.UrlFilenameViewController" />

  <!-- maps request URLs to Controller names -->
  <bean id="urlMappingWithControllers" class="org.springframework.web.servlet.mvc.support.ControllerClassNameHandlerMapping" />

  <bean id="urlMappingNoControllers" class="org.springframework.web.servlet.handler.SimpleUrlHandlerMapping">
    <property name="mappings">
      <props>
        <prop key="*">fileNameViewController</prop>
      </props>
    </property>
  </bean>

</beans>
```