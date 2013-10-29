---
layout: post
title: "Migration de Blogger vers GitHub"
description: ""
category: ""
tags: [github]
---
{% include JB/setup %}

En ce temps d'Halloween, je réveille les morts-vivants et migre mon blog de [Blogger](http://surunairdejava.blogspot.ca/) vers [GitHub](http://cthiebault.github.io/).
Ça fait un moment que je me dis que je posterais pus facilement si je pouvais écrire mes billets en [Markdown](http://daringfireball.net/projects/markdown/) plutôt qu'en HTML. On verra bien...

Je profite de ce billet pour lister rapidement les outils utilisés pour la migration du blog.

<!-- more -->

## GitHub pages

### Installation en local

[GitHub Pages Ruby Gem](https://github.com/github/pages-gem)
A simple Ruby Gem to bootstrap dependencies for setting up and maintaining a local Jekyll environment in sync with GitHub Pages

### Configuration

#### Thème

[http://jekyllbootstrap.com]()
Jekyll-Bootstrap is a full blog scaffold for Jekyll based blogs

#### Markdown
[Mimicking GitHub Flavored Markdown](http://jekyllrb.com/docs/github-pages)

#### Syntax highlighting

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

Et télécharger le CSS pour colorer les blocs de code :
[https://github.com/mojombo/tpw/blob/master/css/syntax.css]()

**_includes/themes/bootstrap/default.html**

```html
<head>
  <link href="{{ ASSET_PATH }}/css/style.css?body=1" rel="stylesheet" type="text/css" media="all">
  <link href="{{ ASSET_PATH }}/css/syntax.css?body=1" rel="stylesheet" type="text/css" media="all">
</head>
```

## Conclusion

Pour rappel, vous pouvez voir les sources de ce blog sur le repository GitHub
[https://github.com/cthiebault/cthiebault.github.com]()