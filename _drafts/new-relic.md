---
layout: post
title: "Monitorez vos applications avec New relic"
description: ""
category: ""
tags: [java, performance]
---
{% include JB/setup %}

J'ai découvert le service de monitoring [New Relic](http://newrelic.com) en écoutant les [Cast Codeurs sur CloudBees](http://lescastcodeurs.com/2014/02/20/lcc-96-interview-sur-cloudbees-et-le-paas-avec-nicolas-deloof). Nicolas Deloof disait que c’était une des applications les plus populaires sur leur plateforme...

[New Relic](http://newrelic.com) est une service (SaaS) qui surveille les performances des applications web.
Son agent collecte et agrège des métriques de performance de l'application en production.

La mise en oeuvre est ultra simple!

### Créez un compte

Créez un compte chez [New Relic](http://newrelic.com) pour avoir une licence qui permettra d'associer les données de vos applications à votre compte.
New Relic est [gratuit](http://newrelic.com/pricing) si vous ne gardez vos données plus de 24h... ce qui est amplement suffisant dans mon cas!


### Ajoutez l'agent à votre classpath

Avec Maven:

```
<dependency>
  <groupId>com.newrelic.agent.java</groupId>
  <artifactId>newrelic-agent</artifactId>
  <version>3.4.2</version>
  <scope>runtime</scope>
</dependency>
```

### Configurez New Relic

Téléchargez le ficher de configuration `newrelic.yml` depuis votre compte et entrez votre code de licence et le nom de votre application.


### Démarrez votre application

Spécifiez seulement le chemin de l'agent lors de l'execution de votre commande java :

```
-javaagent:<web-app-lib-path>/newrelic-agent-3.4.2.jar
```

New Relic s'attend à trouver le fichier de config `newrelic.yml` dans le même répertoire que le jar de l'agent. Si ça n'est pas le cas :

```
-javaagent:<web-app-lib-path>/newrelic-agent-3.4.2.jar -Dnewrelic.config.file=<config-path>/newrelic.yml 
```

### Analysez les performances


Ouvrez une session sur [New Relic](http://newrelic.com) et accédez au tableau de bord des applications. Maintenant il ne vous reste plus qu'à fouiller dans toutes ces statistiques!

