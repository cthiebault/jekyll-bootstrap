---
layout: post
title: "Maven2 et MyEclipse"
description: ""
category: ""
tags: [maven, eclipse]
---
{% include JB/setup %}

MyEclipse ne supporte pas officiellement Maven2 mais en utilisant le plugin m2eclipse on peut s'en sortir assez facilement....

Selon le standard définit par Maven les classes devraient être compilées dans le répertoire target, mais si l'on veut utiliser MyEclipse pour déployer l'application (Hot deployment) il faut que nous compilions les classes vers `src/main/webapp/WEB-INF/classes`. L'idéal serait que MyEclipse supporte le déploiement des classes compilées dans différents répertoires vers le serveur comme ça nous pourrions suivre le standard Maven et compiler vers target mais ce n'est pas encore le cas...

<!-- more -->

Attention : lorsque l'on déploit avec MyEclipse, on perd la fonctionnalité des filtres de Maven :-(

Dans les propriétés du projet web, définir le webrootdir à `src/main/webapp` et configurer le fichier `.classpath` comme suit :

```xml
<classpath>
  <classpathentry kind="src" path="src/main/java" output="src/main/webapp/WEB-INF/classes" />
  <classpathentry kind="src" path="src/main/resources" output="src/main/webapp/WEB-INF/classes" />
  <classpathentry kind="src" path="src/test/java" output="target/test-classes" />
  <classpathentry kind="src" path="src/test/resources" output="target/test-classes" />
  <classpathentry kind="output" path="src/main/webapp/WEB-INF/classes" />
  <classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER" />
  <classpathentry kind="con" path="org.maven.ide.eclipse.MAVEN2_CLASSPATH_CONTAINER" />
</classpath>
```

Le plus gros problème dans tout ça, c'est que MyEclipse déploit tous les jars définis dans le POM... même ceux qui ne servent qu'à la compilation (scope=provided). Par exemple les fichiers servlet-api.jar et jsp-api.jar seront copiés dans `WEB-INF/lib` et cela peut créer des problèmes au démarrage du serveur web.
En attendant le support officiel de Maven2 par MyEclipse, il nous reste à effacer ces fichiers manuellement ou à ne pas les inclure dans le POM :(

La communauté des utilisateurs de MyEclipse pousse de plus en plus fort pour le support officiel de Maven2 et certains proposent déjà des solutions qui ne semblent pas demander une tonne de code pour exploiter le plugin m2eclipse (légèrement adapté) et déployer seulement les jar définis pour le runtime.... Patience donc!