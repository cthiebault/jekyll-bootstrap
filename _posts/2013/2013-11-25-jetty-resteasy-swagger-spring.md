---
layout: post
title: "RestEasy + Swagger + Jetty  + Spring"
description: ""
category: ""
tags: [java, rest, spring, jetty, swagger, resteasy]
---
{% include JB/setup %}

Petit billet en forme d'aide-mémoire pour configurer et documenter des service REST dans un serveur embarqué avec

* [RestEasy 3](http://www.jboss.org/resteasy) - Implémentation de JAX-RS par JBoss. J'étais plutôt tenté par [Jersey](https://jersey.java.net/) mais un [bug](https://java.net/jira/browse/JERSEY-2175) sur l'intégration avec Spring m'a empêché d'aller plus loin :(
* [Swagger](https://github.com/wordnik/swagger-core/wiki) - Permet de documenter ses services REST depuis le code. La documentation est ainsi toujours à jour avec le code.
* [Jetty 7](http://www.eclipse.org/jetty) - Serveur HTTP et conteneur de Servlets léger et facilement embarquable.
* [Spring 3](http://projects.spring.io/spring-framework)

<!-- more -->

## Dépendances

**build.gradle**

```groovy
apply plugin: 'java'

sourceCompatibility = JavaVersion.VERSION_1_6
targetCompatibility = JavaVersion.VERSION_1_6

task wrapper(type: Wrapper) {
  gradleVersion = '1.9'
}

configurations {
  compile
  runtime
  all*.exclude group: 'commons-logging'
}

ext {
  slf4jVersion = '1.7.5'
  resteasyVersion = '3.0.5.Final'
  springVersion = '3.2.4.RELEASE'
}

dependencies {
  compile('org.eclipse.jetty:jetty-servlet:7.6.8.v20121106')

  compile("org.jboss.resteasy:resteasy-jaxrs:${resteasyVersion}")
  compile("org.jboss.resteasy:resteasy-spring:${resteasyVersion}")

  compile("org.springframework:spring-beans:${springVersion}")
  compile("org.springframework:spring-context:${springVersion}")
  compile("org.springframework:spring-web:${springVersion}")

  compile("org.slf4j:jul-to-slf4j:${slf4jVersion}")

  compile('com.wordnik:swagger-jaxrs_2.10:1.3.1')

  runtime('ch.qos.logback:logback-classic:1.0.13')
  runtime("org.slf4j:slf4j-api:${slf4jVersion}")
  runtime("org.slf4j:jcl-over-slf4j:${slf4jVersion}")

  testCompile('junit:junit:4.11')
}

test {
  testLogging.showStandardStreams = true
}

repositories {
  mavenLocal()
  mavenCentral()
}

tasks.withType(Compile) {
  options.encoding = 'UTF-8'
}
```

## Serveur Jetty + Servlet RestEasy

```java
import org.eclipse.jetty.server.Connector;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.handler.HandlerList;
import org.eclipse.jetty.server.nio.SelectChannelConnector;
import org.eclipse.jetty.servlet.ServletContextHandler;
import org.eclipse.jetty.servlet.ServletHolder;
import org.jboss.resteasy.plugins.server.servlet.HttpServletDispatcher;
import org.jboss.resteasy.plugins.server.servlet.ResteasyBootstrap;
import org.jboss.resteasy.plugins.spring.SpringContextLoaderListener;
import org.springframework.web.context.ContextLoader;
import org.springframework.web.context.request.RequestContextListener;

public class JettyServer {

  private final Server jettyServer;

  private final ServletContextHandler servletContextHandler;

  public JettyServer() throws Exception {

    jettyServer = new Server();
    jettyServer.setSendServerVersion(false);
    jettyServer.setStopAtShutdown(false);

    servletContextHandler = new ServletContextHandler(ServletContextHandler.NO_SECURITY);
    servletContextHandler.setContextPath("/");
    // listeners order is important!
    servletContextHandler.addEventListener(new ResteasyBootstrap());
    servletContextHandler.addEventListener(new SpringContextLoaderListener());
    servletContextHandler.addEventListener(new RequestContextListener());
    servletContextHandler.setInitParameter(ContextLoader.CONFIG_LOCATION_PARAM, "classpath:application-context.xml");

    createHttpConnector();

    createRestEasyServlet();

    HandlerList handlers = new HandlerList();
    handlers.addHandler(servletContextHandler);
    jettyServer.setHandler(handlers);

    jettyServer.start();
  }

  private void createHttpConnector() {
    Connector httpConnector = new SelectChannelConnector();
    httpConnector.setPort(8080);
    httpConnector.setMaxIdleTime(30000);
    httpConnector.setRequestHeaderSize(8192);
    jettyServer.addConnector(httpConnector);
  }

  private void createRestEasyServlet() {
    ServletHolder servletHolder = new ServletHolder(new HttpServletDispatcher());
    servletHolder.setInitParameter("resteasy.servlet.mapping.prefix", "/ws");
    servletHolder.setInitOrder(1);
    servletContextHandler.addServlet(servletHolder, "/ws/*");
  }
}

```

## Swagger

**application-context.xml**

```xml
<beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:context="http://www.springframework.org/schema/context"
    xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
  http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd">

  <context:annotation-config/>
  <context:component-scan base-package="com.surunairdejava"/>

  <!-- swagger config -->
  <bean class="com.wordnik.swagger.jaxrs.listing.ApiListingResourceJSON"/>
  <bean class="com.wordnik.swagger.jaxrs.listing.ApiDeclarationProvider"/>
  <bean class="com.wordnik.swagger.jaxrs.listing.ResourceListingProvider"/>
  <bean id="swaggerConfig" class="com.wordnik.swagger.jaxrs.config.BeanConfig">
    <property name="resourcePackage" value="com.surunairdejava.web"/>
    <property name="version" value="1.0.0"/>
    <property name="basePath" value="http://localhost:8080/ws"/>
    <property name="title" value="Jetty / RestEasy / Swagger test"/>
    <property name="description" value="This is a app."/>
    <property name="contact" value="cedric.thiebault@gmail.com"/>
    <property name="scan" value="true"/>
  </bean>

</beans>

```

## Ressources et sous-ressources REST

Voici un exemple avec des sous-ressources gérées par Spring (en tant que singleton et prototype).

```java
@Path("/spring")
@Api(value = "/spring", description = "Test resource as Spring bean")
@Component
@Transactional
public class SpringResource {

  private static final Logger log = LoggerFactory.getLogger(SpringResource.class);

  @Autowired
  private ApplicationContext applicationContext;

  @Autowired
  private SpringSingletonSubResource springSubResource;

  @GET
  @ApiOperation("get method")
  @ApiResponses({ @ApiResponse(code = 200, message = "OK") })
  public Response get() {
    log.info("get method");
    return Response.ok().build();
  }

  @Path("/singleton")
  @ApiOperation(value = "/singleton", notes = "Test singleton sub-resources")
  public SpringSingletonSubResource singleton() {
    log.info("SpringSingletonSubResource: {}", springSubResource);
    return springSubResource;
  }

  @Path("/prototype")
  @ApiOperation(value = "/prototype", notes = "Test prototype sub-resources")
  public SpringPrototypeSubResource prototype() {
    SpringPrototypeSubResource resource = applicationContext.getBean(SpringPrototypeSubResource.class);
    log.info("sub resource: {}", resource);
    return resource;
  }
}

===================

public interface SpringPrototypeSubResource {
  @GET
  @ApiOperation(value = "SpringPrototypeSubResource", notes = "More notes about this method")
  @ApiResponses(value = { @ApiResponse(code = 200, message = "OK") })
  Response get();
}

===================

@Component
@Scope(ConfigurableBeanFactory.SCOPE_PROTOTYPE)
@Transactional
public class SpringPrototypeSubResourceImpl implements SpringPrototypeSubResource {

  private static final Logger log = LoggerFactory.getLogger(SpringPrototypeSubResourceImpl.class);

  @Override
  public Response get() {
    log.debug("Spring prototype sub-resource");
    return Response.ok().build();
  }
}

===================

public interface SpringSingletonSubResource {
  @GET
  @ApiOperation(value = "SpringSingletonSubResource", notes = "More notes about this method")
  @ApiResponses(value = { @ApiResponse(code = 200, message = "OK") })
  Response get();
}

===================

@Component
@Transactional
public class SpringSingletonSubResourceImpl implements SpringSingletonSubResource {

  private static final Logger log = LoggerFactory.getLogger(SpringSingletonSubResourceImpl.class);

  @Override
  public Response get() {
    log.debug("Spring singleton sub-resource");
    return Response.ok().build();
  }
}
```

## Et on teste tout ça...

On démarre d'abord le serveur web:

```java
public class Run {
  public static void main(String... args) throws Exception {
    new JettyServer();
  }
}
```

Puis on teste les ressources REST depuis Chrome avec l'extension [REST Console](https://chrome.google.com/webstore/detail/rest-console/cokgbflfommojglbmbpenpphppikmonn?hl=en)
* GET `http://localhost:8080/ws/spring`
* GET `http://localhost:8080/ws/spring/singleton`
* GET `http://localhost:8080/ws/spring/prototype`

La documentation est accessible via:
GET `http://localhost:8080/ws/api-docs`

```json
{
  "apiVersion": "1.0.0",
  "swaggerVersion": "1.2",
  "apis": [{
	  "path": "/spring",
	  "description": "Test resources as Spring bean"
  }],
  "info": {
    "title": "JTA / RestEasy / Swagger test",
    "description": "This is a app.",
    "contact": "cedric.thiebault@gmail.com"
	}
}
```

GET `http://localhost:8080/ws/api-docs/spring`

```json
{
  "apiVersion": "1.0.0",
  "swaggerVersion": "1.2",
  "basePath": "http://localhost:8080/ws",
  "resourcePath": "/spring",
  "apis": [{
    "path": "/spring",
    "operations": [{
      "method": "GET",
      "summary": "get method",
      "notes": "",
      "type": "void",
      "nickname": "get",
      "parameters": [],
      "responseMessages": [{
        "code": 200,
        "message": "OK"
      }]
    }]
  }, {
    "path": "/spring/singleton",
    "operations": [{
      "method": null,
      "summary": "/singleton",
      "notes": "Test singleton sub-resources",
      "type": "void",
      "nickname": "singleton",
      "parameters": []
    }]
  }, {
    "path": "/spring/prototype",
    "operations": [{
      "method": null,
      "summary": "/prototype",
      "notes": "Test prototype sub-resources",
      "type": "void",
      "nickname": "prototype",
      "parameters": []
    }]
  }]
}
```

Il resterait maintenant à configurer [SwaggerUI](https://github.com/wordnik/swagger-ui) pour afficher une belle documentation...
