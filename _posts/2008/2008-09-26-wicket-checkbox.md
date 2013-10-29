---
layout: post
title: "Wicket: Checkbox, AbstractCheckBoxModel et enum"
description: ""
category: ""
tags: [wicket]
---
{% include JB/setup %}

Voici maintenant 3 semaines que je travaille avec [Wicket](http://wicket.apache.org/) et je dois dire que je suis vraiment impressionné par la vitesse de développement avec ce framework.
Ça prend un petit peu de temps pour se familiariser avec l'approche "component oriented" mais une fois que l'on a compris... ça dépote :-)

Seul petit défaut à mon avis : la documentation! Quand on vient du monde merveilleusement documenté de Spring, Wicket est un peu dur...

Dans le billet d'aujourd'hui, je présenterais comment afficher une liste de checkbox pour toutes les valeurs d'un enum.
Je n'utilise pas de radio car je veux pouvoir désélectionner tous les checkbox (ie la valeur nulle est permise).
En fait c'est exactement le fonctionnement d'une liste de radio (un seul choix possible) mais je peux tout désélectionner, ce qui n'est pas possible avec les radios.

<!-- more -->

```html
<input type="checkbox" id="ie" /><label for="ie">Internet Explorer</label>
```

<input type="checkbox" id="ie" style="display: inline;" /><label for="ie" style="display: inline;">Internet Explorer</label>
<input type="checkbox" id="firefox" style="display: inline;" /><label for="firefox" style="display: inline;">Firefox</label>
<input type="checkbox" id="opera" style="display: inline;" /><label for="opera" style="display: inline;">Opera</label>
<input type="checkbox" id="chrome" style="display: inline;" /><label for="chrome" style="display: inline;">Chrome</label>

Évidemment dans l'exemple ci-dessus, le choix n'est pas unique mais c'est juste pour montrer à quoi ça va ressembler à la fin... ;-)

Pour commencer, mes enum implémentent l'interface suivante qui permet de connaître le label correspondant à chaque enum.

```java
public interface LabeledEnum {
  String getLabel();
}

public enum Browser implements LabeledEnum {

  IE, FIREFOX, OPERA, CHROME;

  public String getLabel() {
    return "browser." + name();
  }
}
```

```
browser.IE=Internet Explorer
browser.FIREFOX=Firefox
browser.OPERA=Opera
browser.CHROME=Chrome
```

Le composant Checkbox ne travaille qu'avec un Model de type boolean. Donc je ne peux pas lui passer directement mon enum.
Il faut utiliser par la classe AbstractCheckBoxModel pour transformer mon enum en boolean.

```java
public class EnumCheckBoxModel extends AbstractCheckBoxModel {

  private final IModel model;
  private final LabeledEnum enumValue;

  public EnumCheckBoxModel(IModel model, LabeledEnum enumValue) {
    this.model = model;
    this.enumValue = enumValue;
  }

  @Override
  public boolean isSelected() {
    return model.getObject() == enumValue;
  }

  @Override
  public void select() {
    model.setObject(enumValue);
  }

  @Override
  public void unselect() {
    model.setObject(null);
  }

}
```

Et voici enfin le code de mon composant :

```java
public class EnumCheckBoxes<TEnum extends Enum<?> & LabeledEnum> extends Panel {

  TEnum[] enumList;
  IModel checkBoxModel;

  public EnumCheckBoxes(String id, IModel checkBoxModel, Class<TEnum> enumClass) {
    this(id, checkBoxModel, enumClass.getEnumConstants());
  }

  public EnumCheckBoxes(String id, IModel checkBoxModel, TEnum... enumList) {
    super(id);
    this.checkBoxModel = checkBoxModel;
    this.enumList = enumList;
    createComponent();
  }

  private void createComponent() {

    // div that will be refreshed via ajax when user select a checkbox
    final WebMarkupContainer listViewContainer = new WebMarkupContainer("listContainer");
    listViewContainer.setOutputMarkupId(true);

    final ListView listView = new ListView("list", new Model((Serializable) Arrays.asList(enumList))) {

      @Override
      protected void populateItem(ListItem item) {
        TEnum labeledEnum = (TEnum) item.getModelObject();

        CheckBox checkBox = new CheckBox("input", new EnumCheckBoxModel(checkBoxModel, labeledEnum));
        checkBox.setLabel(new ResourceModel(labeledEnum.getLabel()));

        // don't use OnChangeAjaxBehavior because of IE event propagation for checkbox onchange
        checkBox.add(new AjaxFormComponentUpdatingBehavior("onclick") {

          @Override
          protected void onUpdate(AjaxRequestTarget target) {
            target.addComponent(listViewContainer);
          }
        });
        item.add(checkBox);
        item.add(new SimpleFormComponentLabel("label", checkBox));
      }

    };
    listViewContainer.add(listView);
    add(listViewContainer);
  }
}
```

```html
<html xmlns:wicket>
<wicket:panel>

  <div wicket:id="listContainer">
    <div wicket:id="list">
      <div class="checkboxWithLabel">
        <input type="checkbox" wicket:id="input" />
        <label wicket:id="label"> </label>
      </div>
    </div>
  </div>

</wicket:panel>
</html>
```
