---
layout: post
title: "Jersey + Shiro + Spring"
description: ""
category: ""
tags: [java, rest, shiro, jersey, spring]
---
{% include JB/setup %}


Dans ce billet je vais présenter comment supporter dans [Jersey 2.7](https://jersey.java.net) les annotations
`RequiresAuthentication`, `RequiresRoles`, `RequiresPermissions`, etc. de [Shiro 1.2](http://shiro.apache.org).

Exemple d'utilisation des annotations dans des ressources et des sous-ressources :

```java
@Path("/users")
public class UsersResource {

  @Inject
  private UserRepository userRepository;

  @GET
  public List<User> list() {
    return userRepository.findAll();
  }

  @POST
  @RequiresPermissions("can-create-user")
  public Response create(User user, @Context UriInfo uriInfo) {
    userRepository.save(user);
    return Response.created(uriInfo.getBaseUriBuilder().path(UserResource.class).build(user.getName())).build();
  }

  @Path("/{name}")
  public UserResource user(@PathParam("name") String name) {
    UserResource userResource = applicationContext.getBean(UserResource.class);
    userResource.setName(name);
    return userResource;
  }
}


@Component
@Scope("request")
public class UserResource {

  @Inject
  private UserRepository userRepository;

  private String name;

  public void setName(String name) {
    this.name = name;
  }

  @GET
  public User get() {
    return userRepository.findOne(name);
  }

  @DELETE
  @RequiresPermissions("can-delete-user")
  public Response delete() {
    userRepository.delete(name);
    return Response.noContent().build();
  }

}

```

Dans mon cas, Jersey est configuré par [Spring Boot](http://projects.spring.io/spring-boot) comme suit :

```java
@Configuration
public class JerseyConfiguration extends ResourceConfig {

  @Bean
  public ServletRegistrationBean jerseyServlet() {
    ServletRegistrationBean registration = new ServletRegistrationBean(new ServletContainer(), "/ws/*");
    registration.addInitParameter(ServletProperties.JAXRS_APPLICATION_CLASS, JerseyServletConfig.class.getName());
    return registration;
  }

  public static class JerseyServletConfig extends ResourceConfig {
    public JerseyServletConfig() {
      register(RequestContextFilter.class);
      packages("com.surunairdejava");
      register(LoggingFilter.class);
    }
  }
}
```

La [configuration des annotations Shiro et Spring](https://shiro.apache.org/spring.html#Spring-EnablingShiroAnnotations)
ne suffit pas pour Jersey car ce dernier charge ses resources en dehors de Spring.