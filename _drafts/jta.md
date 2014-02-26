---
layout: post
title: "JTA en dehors du monde J2EE"
description: ""
category: ""
tags: [java, jta]
---
{% include JB/setup %}

L'application sur laquelle je travaille roule sur Jetty et utilise plusieurs base de données (Hibernate et SQL classique sous MySQL et HSQL).
Nous n'avons donc pas le choix d'utiliser JTA (Java Transaction API) pour gérer les transactions.
