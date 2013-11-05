---
layout: post
title: "Base de données NoSQL OrientDB"
description: ""
category: ""
tags: [java, orientdb]
---
{% include JB/setup %}

Récemment, dans un de nos projets, nous avons opté pour la base de données NoSQL [OrientDB](http://www.orientdb.org).
L’idée était de remplacer notre [Hibernate](http://hibernate.org) sur [HSQL](http://hsqldb.org) pour une base de donnée orientée document mais qui soit embarquable (en gros pas [MongoDB](http://www.mongodb.org)). OrientDB semble être la seule qui soit "embeddable" en java pour le moment...

[OrientDB](http://www.orientdb.org) supporte les bases de données orientée [graph](https://github.com/orientechnologies/orientdb/wiki/Graph-Database-Tinkerpop), [document](https://github.com/orientechnologies/orientdb/wiki/Document-Database) et [objet](https://github.com/orientechnologies/orientdb/wiki/Object-Database).

## Serveur OrientDB embarqué

Assez simple à configurer en suivant la [documentation](https://github.com/orientechnologies/orientdb/wiki/Embedded-Server)...
Chez moi ca donne ca en gros:

```java
@Component
public class OrientDbServerFactory {

  private static final Logger log = LoggerFactory.getLogger(OrientDbServerFactory.class);

  @Value("${orientdb.url}")
  private String url;

  @Value("${orientdb.username}")
  private String username;

  @Value("${orientdb.password}")
  private String password;

  private OServer server;

  @PostConstruct
  public void start() throws Exception {
    log.info("Start OrientDB server ({})", url);

    System.setProperty("ORIENTDB_HOME", url);
    server = new OServer().startup().activate();

    // create database if does not exist
    ODatabase database = new OObjectDatabaseTx(url);
    if(!database.exists()) database.create();
    database.close();
  }

  @PreDestroy
  public void stop() {
    log.info("Stop OrientDB server ({})", url);
    if(server != null) server.shutdown();
  }

  public OServer getServer() {
    return server;
  }

  public OObjectDatabaseTx getObjectTx() {
    return OObjectDatabasePool.global().acquire(url, username, password);
  }

  public ODatabaseDocumentTx getDocumentTx() {
    return ODatabaseDocumentPool.global().acquire(url, username, password);
  }
}

```

## Base de données orientée Objet

OrientDB utilise ici une base de donnees orientée Document et la reflection pour déterminer les champs du document. OrientDB déduit le schema des objects une seule fois lors de l'enregistrement de la classe à persister.

Dans un premier temps j'ai choisi d'utiliser cette méthode car ca m'évitait de faire un mapping pojo <--> document et ca ressemblait beaucoup à Hibernate... je restais donc en terrain connu. De plus, OrientDB utilise les [annotations JPA](https://github.com/orientechnologies/orientdb/wiki/Object-Database#cascade-deleting) pour configurer la persistence :

* @Id
* @Version
* @OneToOne
* @OneToMany
* @ManyToMany

Un peu de code maintenant :

### Entités

```java
public abstract class AbstractOrientDbEntity {

  @Id
  private String id;

  @Version
  private Integer version;
  [...]

  @Override
  public int hashCode() {
    return Objects.hashCode(id);
  }

  @Override
  public boolean equals(Object obj) {
    if(this == obj) return true;
    if(obj == null || getClass() != obj.getClass()) return false;
    return Objects.equal(id, ((AbstractOrientDbEntity) obj).id);
  }
}
```

### Enregistrer une classe à persister

Cette étape permet à OrientDB de définir le schema de la table correspondante à cette entité.

```java
public void registerEntityClass(Class<? extends AbstractOrientDbEntity>... classes) {
  try(OObjectDatabaseTx db = serverFactory.getObjectTx()) {
    for(Class<?> clazz : classes) {
      db.getEntityManager().registerEntityClass(clazz);
    }
  }
}
```

OrientDB supporte les relations entre entités : pour chaque type d'object OrientDB crée une table correspondante.
Par contre il n'y a pas la notion de [@Embedded](http://docs.jboss.org/hibernate/annotations/3.5/reference/en/html_single/#d0e714).

Théoriquement, OrientDB supporte aussi la [suppression en cascade](https://github.com/orientechnologies/orientdb/wiki/Object-Database#cascade-deleting) mais on a rencontré quelque problèmes avec ça.

### Créer un index

OrientDB permet de créer des [indexes](https://github.com/orientechnologies/orientdb/wiki/Indexes).

```java
public void createIndex(Class<?> clazz, String property, OClass.INDEX_TYPE indexType, OType type) {
  try(OObjectDatabaseTx db = serverFactory.getObjectTx()) {
    String className = clazz.getSimpleName();
    int clusterId = db.getClusterIdByName(className.toLowerCase());
    OIndexManager indexManager = db.getMetadata().getIndexManager();
    indexManager.createIndex(className + "." + property, indexType.name(),
        new OPropertyIndexDefinition(className, property, type), new int[] { clusterId },
        ONullOutputListener.INSTANCE);
  }
}
```

Par exemple, pour ajouter un index unique pour le username d'un `User`:
`createIndex(User.class, "username", OClass.INDEX_TYPE.UNIQUE, OType.STRING);`

### Persister un object

```java
public <TEntity extends AbstractOrientDbEntity> void save(TEntity entity) {
  OObjectDatabaseTx db = serverFactory.getObjectTx();
  try {
    db.begin(OTransaction.TXTYPE.OPTIMISTIC);
    db.save(entity);
    db.commit();
  } catch(OException e) {
    db.rollback();
    throw e;
  } finally {
    db.close();
  }
}
```

### Accéder aux objects

Notez ici que je détache mes objets, c'est à dire que mes objets ne sont plus des proxy mais de vrai Pojo avec tous les champs chargés. On commence à retrouver le monde merveilleux des objets transient/detached de Hibernate...

```java
public <TEntity extends AbstractOrientDbEntity> Iterable<TEntity> list(Class<TEntity> clazz) {
  try(OObjectDatabaseTx db = serverFactory.getObjectTx()) {
    return Iterables.transform(db.browseClass(clazz), new Function<TEntity, TEntity>() {
      @Override
      public TEntity apply(TEntity input) {
        return db.detach(input, true);
      }
    });
  }
}
```

### Requêtes SQL

```java
public <TEntity extends AbstractOrientDbEntity> Iterable<TEntity> list(String sql, Object... params) {
  try(OObjectDatabaseTx db = serverFactory.getObjectTx()) {
    Iterable<TEntity> entities = db.command(new OSQLSynchQuery(sql)).execute(params);
    return Iterables.transform(entities, new Function<TEntity, TEntity>() {
      @Override
      public TEntity apply(TEntity input) {
        return db.detach(input, true);
      }
    });
  }
}
```

### Transaction template

Pour finir voici une méthode à la [TransactionTemplate](http://docs.spring.io/spring/docs/3.0.x/api/org/springframework/transaction/support/TransactionTemplate.html) de Spring qui assure que la connection sera bien fermée en fin de traitement :

```java
public <T> T execute(OrientDbTransactionCallback<T> action) {
  OObjectDatabaseTx db = serverFactory.getObjectTx();
  try {
    db.begin(OTransaction.TXTYPE.OPTIMISTIC);
    T t = action.doInTransaction(db);
    db.commit();
    return t;
  } catch(OException e) {
    db.rollback();
    throw e;
  } finally {
    db.close();
  }
}

public interface OrientDbTransactionCallback<T> {
  T doInTransaction(OObjectDatabaseTx db);
}
```

### Conclusion

En pratique la base de données orientée Objet de OrientDB fonctionne trés bien! Ca ressemble vraiment beaucoup au monde de Hibernate (en plus simple!).

Mais dans mon cas, le problème vient du fait que justement, ça ressemble trop à Hibernate et qu'on se retrouve à nouveau à gérer des problèmes d'objets attachés/détachés, des problèmes de cascade, etc. De plus, je travaille avec des DTO que je dois transformer en entités OrientDB et là c'est un bonheur avec de grandes hiérarchies (style arbre). Surtout que mes DTO ne contiennent pas champs annotés @Id de OrientDB, ils utilisent d'autres champs (la plupart du temps combinés) pour gérer leur identité :-(

Bref, pour toutes ces raisons j'ai basculé vers la base de données orientée Document...


## Base de données orientée Document

Comme expliqué précédemment, je n'avais pas choisi cette configuration de OrientDB pour éviter de faire le mapping à la main entre les entités et les documents.
Mais OrientDB propose de populer les documents depuis du JSON... sauvé! :-)

J'utilise [Gson](http://code.google.com/p/google-gson) pour serialiser/deserialiser les objets en JSON.

### Entités

Ici nous n'avons pas besoin d'enregistrer les classes à persister puisque nous somme en mode Document et donc 'schema-less'.

Dans mon cas, afin d'identifier de façon unique mes objets pour les mettre à jour, mes entités implementent `HasUniqueProperties`.

```java
public interface HasUniqueProperties {
  List<String> getUniqueProperties();
  List<Object> getUniqueValues();
}
```

Par exemple, pour les `User` :

```java
public class User implements HasUniqueProperties {

  @Nonnull
  private String username;
  [...]

  @Override
  public List<String> getUniqueProperties() {
    return Lists.newArrayList("username");
  }

  @Override
  public List<Object> getUniqueValues() {
    return Lists.<Object>newArrayList(username);
  }
}
```

### Créer un index unique

J'utilise cette méthode pour créer un index unique sur tous les champs qui définissent l'unicité de mon entité.
Par exemple pour le `username` d'un `User`, le nom de l'index sera `User.username`.

```java
public void createUniqueIndex(Class<? extends HasUniqueProperties> clazz) {
  try(ODatabaseDocumentTx db = serverFactory.getDocumentTx()) {
    String className = clazz.getSimpleName();

    OClass indexClass;
    OSchema schema = db.getMetadata().getSchema();
    if(schema.existsClass(className)) {
      indexClass = schema.getClass(className);
    } else {
      indexClass = schema.createClass(className);
      schema.save();
    }

    StringBuilder indexName = new StringBuilder(clazz.getSimpleName());
    HasUniqueProperties bean = BeanUtils.instantiate(clazz);
    List<String> uniqueProperties = bean.getUniqueProperties();
    for(String propertyPath : uniqueProperties) {
      indexName.append(".").append(propertyPath);
      OProperty property = indexClass.getProperty(propertyPath);
      if(property == null) {
        PropertyDescriptor propertyDescriptor = BeanUtils.getPropertyDescriptor(clazz, propertyPath);
        indexClass.createProperty(propertyPath, OType.getTypeByClass(propertyDescriptor.getPropertyType()));
        schema.save();
      }
    }

    indexClass.createIndex(indexName.toString(), OClass.INDEX_TYPE.UNIQUE,
        uniqueProperties.toArray(new String[uniqueProperties.size()]));
  }
}
```

### Persister un object

```java

// need to configure Gson date format to follow OrientDB format
private final Gson gson = new GsonBuilder().setDateFormat("yyyy-MM-dd HH:mm:ss").create();

public void save(HasUniqueProperties template, HasUniqueProperties entity) {

  ODatabaseDocumentTx db = serverFactory.getDocumentTx();
  try {

    // use the index to search for document that match our template
    ODocument document = findUniqueDocument(db, template);
    if(document == null) {
      document = new ODocument(entity.getClass().getSimpleName());
      document.fromJSON(gson.toJson(entity));
    } else {
      document.fromJSON(gson.toJson(entity));
    }

    db.begin(OTransaction.TXTYPE.OPTIMISTIC);
    document.save();
    db.commit();

  } catch(OException e) {
    db.rollback();
    throw e;
  } finally {
    db.close();
  }
}

private ODocument findUniqueDocument(ODatabaseDocumentTx db, HasUniqueProperties template) {

  StringBuilder indexName = new StringBuilder(template.getClass().getSimpleName());
  for(String prop : template.getUniqueProperties()) {
    indexName.append(".").append(prop);
  }
  OIndex<?> index = db.getMetadata().getIndexManager().getIndex(indexName.toString());

  Object key = template.getUniqueValues().size() == 1
      ? template.getUniqueValues().get(0)
      : new OCompositeKey(template.getUniqueValues());

  OIdentifiable identifiable = (OIdentifiable) index.get(key);
  return identifiable == null ? null : identifiable.<ODocument>getRecord();
}
```

### Accéder aux objects

```java
public <T> Iterable<T> list(final Class<T> clazz) {
  try(ODatabaseDocumentTx db = serverFactory.getDocumentTx()) {
    ORecordIteratorClass<ODocument> documents = db.browseClass(clazz.getSimpleName());
    return Iterables.transform(documents, new Function<ODocument, T>() {
      @Override
      public T apply(ODocument document) {
        return gson.fromJson(document.toJSON(), clazz);
      }
    });
  }
}
```

### Requêtes SQL

```java
public <T> Iterable<T> list(final Class<T> clazz, String sql, Object... params) {
  try(ODatabaseDocumentTx db = serverFactory.getDocumentTx()) {
    List<ODocument> documents = db.query(new OSQLSynchQuery<ODocument>(sql), params);
    return Iterables.transform(documents, new Function<ODocument, T>() {
      @Override
      public T apply(ODocument document) {
        return gson.fromJson(document.toJSON(), clazz);
      }
    });
  }
}
```

### Transaction template

```java
public <T> T execute(OrientDbTransactionCallback<T> callback) {
  ODatabaseDocumentTx db = serverFactory.getDocumentTx();
  try {
    return callback.doInTransaction(db);
  } catch(OException e) {
    db.rollback();
    throw e;
  } finally {
    db.close();
  }
}

interface OrientDbTransactionCallback<T> {
  T doInTransaction(ODatabaseDocumentTx db);
}
```

### Conclusion