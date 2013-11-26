---
layout: post
title: "Migration de Blogger vers GitHub"
description: ""
category: ""
tags: [github]
---
{% include JB/setup %}

En ce temps d'Halloween, je réveille les morts-vivants et migre mon blog de [Blogger](http://surunairdejava.blogspot.ca) vers [GitHub Pages](http://pages.github.com).
Ça fait un moment que je me dis que je posterais pus facilement si je pouvais écrire mes billets en [Markdown](http://daringfireball.net/projects/markdown) plutôt qu'en HTML. On verra bien...

Je profite de ce billet pour lister rapidement les outils utilisés pour la migration du blog.

<!-- more -->

## GitHub pages

### Installation en local

[GitHub Pages Ruby Gem](https://github.com/github/pages-gem)
Pratique pour rouler vos pages en local avec la même config que GitHub.

### Configuration

#### Thème

Je me suis basé sur [jekyllbootstrap](http://jekyllbootstrap.com) pour avoir un site simple basé sur [Bootstrap](http://getbootstrap.com). Par contre j'ai du mettre à jour Bootstrap qui était encore en version 2.

#### Markdown

L'idée est de pouvoir écrire les billets en Markdown (à la saveur GitHub) :
[Mimicking GitHub Flavored Markdown](http://jekyllrb.com/docs/github-pages)

```
sudo apt-get install ruby1.9.1 ruby1.9.1-dev rubygems1.9.1
sudo gem install github-pages

```

#### Syntax highlighting

Voici ma config pour la coloration des blocs de code :

**_config.yml**

```
pygments: true
safe: true
lsi: false
markdown: redcarpet
redcarpet:
  extensions:
    - hard_wrap
    - no_intra_emphasis
    - autolink
    - strikethrough
    - fenced_code_blocks
```

Et télécharger le CSS qui va bien :
[https://github.com/mojombo/tpw/blob/master/css/syntax.css](https://github.com/mojombo/tpw/blob/master/css/syntax.css)

**_includes/themes/bootstrap/default.html**

```html
<head>
  <link href="{{ ASSET_PATH }}/css/style.css?body=1" rel="stylesheet" type="text/css" media="all">
  <link href="{{ ASSET_PATH }}/css/syntax.css?body=1" rel="stylesheet" type="text/css" media="all">
</head>
```

### Commentaires

L'importation des commentaires de Blogger vers [Disqus](http://disqus.com) s'est faite en douceur... Mais il n'y en avait vraiment pas beaucoup ;-)

## Conclusion

Globalement la migration s'est plutôt bien faite. Le look est très basique mais toujours mieux que le template par défaut de Blogger...
Le markdown simplifie pas mal l’écriture des billets, on verra si je serais plus présent ;-)

Pour rappel, vous pouvez voir les sources de ce blog sur le repository GitHub
[https://github.com/cthiebault/cthiebault.github.com](https://github.com/cthiebault/cthiebault.github.com)