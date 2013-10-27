---
layout: post
title: "Wicket & Maven packaging (fichiers html, css, js...)"
description: ""
category: ""
tags: [wicket, maven]
---
{% include JB/setup %}

Si vous utilisez Maven pour packager votre appplication Wicket, n'oubliez pas de modifier le POM.xml pour inclure les fichiers html, css, js, etc. dans votre war (ou jar).
A moins que vous placiez tous ces fichiers non-java sous `src/main/resources` au lieu de `src/main/java` (ça fait quand même bizarre de voir tous ces fichiers non-java à coté des classes).

```xml
<build>
 <resources>
  <resource>
   <directory>src/main/java</directory>
   <includes>
    <include>**/*</include>
   </includes>
   <excludes>
    <exclude>**/*.java</exclude>
   </excludes>
  </resource>
 </resources>
</build>
```
