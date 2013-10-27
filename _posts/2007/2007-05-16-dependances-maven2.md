---
layout: post
title: "Version des dépendances avec Maven2"
description: ""
category: ""
tags: [maven]
---
{% include JB/setup %}

Voici quelques petits trucs pratique pour alléger les POM de Maven2 dans les projets multi-modules...

Classiquement chaque POM défini ses dépendances comme suit :

**pom.xml**

```xml
<project>
  <dependencies>
    <dependency>
      <groupId>org.springframework</groupId>
      <artifactId>spring-webmvc</artifactId>
      <version>2.0.5</version>
      <exclusions>
        <exclusion>
          <groupId>struts</groupId>
          <artifactId>struts</artifactId>
        </exclusion>
      </exclusions>
    </dependency>
  </dependencies>
</project>
```

Si plusieurs modules utilisent Spring MVC, on ne veut pas dupliquer ce code dans chaque POM...
On définit la configuration de la dépendance dans le POM parent et on inclus seulement la dépendance dans les modules sans spécifier la version ni les exclusions.

**pom.xml parent**

```xml
<project>
  <groupId>demo</groupId>
  <artifactId>parent</artifactId>
  <version>1.0-SNAPSHOT</version>
  <modules>
    <module>child</module>
  </modules>
  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-webmvc</artifactId>
        <version>2.0.5</version>
        <exclusions>
          <exclusion>
            <groupId>struts</groupId>
            <artifactId>struts</artifactId>
          </exclusion>
        </exclusions>
      </dependency>
    </dependencies>
  </dependencyManagement>
</project>
```

**pom.xml child**

```xml
<project>
  <artifactId>child</artifactId>
  <parent>
    <groupId>demo</groupId>
    <artifactId>child</artifactId>
    <version>1.0-SNAPSHOT</version>
  </parent>
  <dependencies>
    <dependency>
      <groupId>org.springframework</groupId>
      <artifactId>spring-webmvc</artifactId>
    </dependency>
  </dependencies>
</project>
```

Dernier petit truc pour simplifer la gestion des version des dépendances : au lieu de hardcoder la version de la dépendance dans sa définition, on peut utiliser des 'properties'. Par exemple pour Spring où l'on dépend de plusieurs jars, on peut facilement upgrader en modifiant seulement la propriété 'spring.version'.

**pom.xml**

```xml
<project>
  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-core</artifactId>
        <version>${spring.version}</version>
      </dependency>
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-dao</artifactId>
        <version>${spring.version}</version>
      </dependency>
      <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-hibernate3</artifactId>
        <version>${spring.version}</version>
      </dependency>
    </dependencies>
  </dependencyManagement>
  <properties>
    <spring.version>2.0.4</spring.version>
  </properties>
</project>
```

Au passage, le site [mvnrepository.com](http://mvnrepository.com) est un bon outils pour trouver les jars publiés dans Maven2 et surtout pour trouver lesquels ont été déplacé...