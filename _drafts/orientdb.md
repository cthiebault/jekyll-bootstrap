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

  private String url;

  private String username;

  private String password;

  private OServer server;

  @Value("${orientdb.url}")
  public void setUrl(@Nonnull String url) {
    this.url = url;
  }

  @Value("${orientdb.username}")
  public void setUsername(String username) {
    this.username = username;
  }

  @Value("${orientdb.password}")
  public void setPassword(String password) {
    this.password = password;
  }

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

  @Nonnull
  public OServer getServer() {
    return server;
  }

  @Nonnull
  public OObjectDatabaseTx getObjectTx() {
    return OObjectDatabasePool.global().acquire(url, username, password);
  }

  @Nonnull
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

### Entity

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

```java
public void registerEntityClass(Class<? extends AbstractOrientDbEntity>... classes) {
  OObjectDatabaseTx db = serverFactory.getObjectTx();
  try {
    for(Class<?> clazz : classes) {
      db.getEntityManager().registerEntityClass(clazz);
    }
  } finally {
    db.close();
  }
}
```

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

Notez ici que je détache mes objets, c'est à dire que mes objets ne sont pas des proxy mais de vrai Pojo avec tous les champs chargés... on commence à retrouver le monde merveilleux des objets transient/detached de Hibernate...

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

Pour finir voici une methode à la [TransactionTemplate](http://docs.spring.io/spring/docs/3.0.x/api/org/springframework/transaction/support/TransactionTemplate.html) de Spring qui assure que la connection sera bien fermée en fin de traitement :

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

## Base de données orientée Document