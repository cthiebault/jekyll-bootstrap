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

  @Inject
  private ApplicationContext applicationContext;

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
ne suffit pas pour Jersey car ce dernier charge ses ressources en dehors de Spring.

Il faut donc utiliser [DynamicFeature](https://jax-rs-spec.java.net/nonav/2.0/apidocs/javax/ws/rs/container/DynamicFeature.html) 
qui sera executer au deploiement pour chaque methode des ressources.

Il faut aussi supporter le cas des sous-ressources gérées par Spring. A cause du proxy CGLIB, on perd l’accès aux annotations : il faut donc retrouver la classe originale sous le proxy via `getSuperclass()`.

Voici à quoi ça ressemble pour l'annotation `@RequiresPermissions` : 


```java
@Provider
public class ShiroRequiresPermissionsFeature implements DynamicFeature {

  private static final Logger log = LoggerFactory.getLogger(ShiroRequiresPermissionsFeature.class);

  @Override
  public void configure(ResourceInfo resourceInfo, FeatureContext context) {
    Collection<String> requiredPermissions = new ArrayList<>();
    Class<?> resourceClass = resourceInfo.getResourceClass();
    Method method = resourceInfo.getResourceMethod();

    if(resourceClass.isAnnotationPresent(RequiresPermissions.class)) {
      requiredPermissions.addAll(asList(resourceClass.getAnnotation(RequiresPermissions.class).value()));
    }
    if(method.isAnnotationPresent(RequiresPermissions.class)) {
      requiredPermissions.addAll(asList(method.getAnnotation(RequiresPermissions.class).value()));
    }

    // in case of Spring bean proxied by CGLIB (where we cannot access annotations anymore)
    Class<?> superClass = resourceClass.getSuperclass();
    if(superClass.isAnnotationPresent(RequiresPermissions.class)) {
      requiredPermissions.addAll(asList(superClass.getAnnotation(RequiresPermissions.class).value()));
    }
    if(isSuperMethodAnnotated(superClass, method, RequiresPermissions.class)) {
      requiredPermissions .addAll(asList(getSuperMethodAnnotation(superClass, method, RequiresPermissions.class).value()));
    }

    if(!requiredPermissions.isEmpty()) {
      log.debug("Register RequiresPermissionsRequestFilter for {} with {}", resourceInfo, requiredPermissions);
      context.register(
          new RequiresPermissionsRequestFilter(requiredPermissions.toArray(new String[requiredPermissions.size()])));
    }
  }

  @Priority(Priorities.AUTHORIZATION) // authorization filter - should go after any authentication filters
  private static class RequiresPermissionsRequestFilter implements ContainerRequestFilter {

    private final String[] requiredPermissions;

    private RequiresPermissionsRequestFilter(String... requiredPermissions) {
      this.requiredPermissions = requiredPermissions;
    }

    @Override
    public void filter(ContainerRequestContext requestContext) throws IOException {
      if(!SecurityUtils.getSubject().isPermittedAll(requiredPermissions)) {
        throw new ForbiddenException();
      }
    }
  }

  boolean isSuperMethodAnnotated(Class<?> superClass, Method method, Class<? extends Annotation> annotationClass) {
    try {
      return superClass.getMethod(method.getName(), method.getParameterTypes()).isAnnotationPresent(annotationClass);
    } catch(NoSuchMethodException ignored) {
      return false;
    }
  }

  <T extends Annotation> T getSuperMethodAnnotation(Class<?> superClass, Method method, Class<T> annotationClass) {
    try {
      return superClass.getMethod(method.getName(), method.getParameterTypes()).getAnnotation(annotationClass);
    } catch(NoSuchMethodException ignored) {
      return null;
    }
  }

}
```