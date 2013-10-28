---
layout: page
title: Sur un air de Java
tagline:
---
{% include JB/setup %}

<p class="lead">Petit blog sans prétention pour partager mes expériences en Java...<br/>Bonne lecture!</p>

<section class="content">
<ul class="listing">
{% for post in site.posts %}
<li><span>{{ post.date | date: "%B %e, %Y" }}</span> <a href="{{ post.url }}">{{ post.title }}</a></li>
{% endfor %}
</ul>
</section>
