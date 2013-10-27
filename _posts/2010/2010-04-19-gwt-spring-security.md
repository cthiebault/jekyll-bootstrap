---
layout: post
title: "GWT et Spring Security (ex ACEGI)"
description: ""
category: ""
tags: [acegi, gwt, spring, spring security]
---
{% include JB/setup %}

Ce billet présentera comment rapidement sécuriser une application GWT (SmartGWT en fait) en utilisant un formulaire d'authentification géré par GWT et non une page web avec un formulaire HTML classique.

L'application est developpée avec les outils suivants :

* [GWT 2.0](http://code.google.com/webtoolkit)
* [SmartGWT 2.0](http://code.google.com/p/smartgwt)
* [Spring](http://www.springsource.org/about) et [Spring Security 3.0](http://static.springsource.org/spring-security/site)
* [Gilead 1.3](http://noon.gilead.free.fr/gilead/)
* [GWT-SL 1.0](http://gwt-widget.sourceforge.net/)


Le projet [GWT-ent](http://code.google.com/p/gwt-ent) propose une intégration avec Spring Security mais seulement avec la version 2.5 et la qualité du code laisse à désirer...
De plus, avec les dernières versions de Spring Security la configuration a été grandement simplifiée!

## Configuration du projet avec Maven

**POM.xml**

```xml
<dependency>
  <groupId>org.springframework.security</groupId>
  <artifactId>spring-security-config</artifactId>
  <version>3.0.2.RELEASE</version>
</dependency>
<dependency>
  <groupId>org.springframework.security</groupId>
  <artifactId>spring-security-core</artifactId>
  <version>3.0.2.RELEASE</version>
</dependency>
<dependency>
  <groupId>org.springframework.security</groupId>
  <artifactId>spring-security-web</artifactId>
  <version>3.0.2.RELEASE</version>
</dependency>
```

## Configuration de l'application web

**web.xml**

```xml
<web-app id="gwtSecurity">

  <context-param>
    <param-name>contextConfigLocation</param-name>
    <param-value>
      classpath:applicationContext.xml
      classpath:applicationContext-security.xml
    </param-value>
  </context-param>

  <filter>
    <filter-name>springSecurityFilterChain</filter-name>
    <filter-class>org.springframework.web.filter.DelegatingFilterProxy</filter-class>
  </filter>

  <filter-mapping>
    <filter-name>springSecurityFilterChain</filter-name>
    <url-pattern>/*</url-pattern>
  </filter-mapping>

  <listener>
    <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
  </listener>

  <listener>
    <listener-class>org.springframework.security.web.session.HttpSessionEventPublisher</listener-class>
  </listener>

  <servlet>
    <servlet-name>rpc-dispatcher</servlet-name>
    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
  </servlet>

  <servlet-mapping>
    <servlet-name>rpc-dispatcher</servlet-name>
    <url-pattern>*.rpc</url-pattern>
  </servlet-mapping>

</web-app>
```

## Configuration de Spring Security

Ici, nous indiquons à Spring d'utiliser notre `UserService` pour accéder aux utilisateurs ainsi que le SHA pour crypter les mots de passe.
Nous ne protégeons aucune URL puisque notre application est hébergée sur une unique page.
Nous avons été obligé de redéfinir le `RememberMeServices` pour forcer le alwaysRemember à vrai. par défaut Spring s'attend à recevoir un paramètre dans l'URL qui lui demanderait de se souvenir de cet utilisateur lors du prochain accès. Comme nous utilisons des appels RPC, nous ne pouvons pas passer ce paramètre dans le request.

**applicationContext-security.xml**

```xml
<beans xmlns="http://www.springframework.org/schema/beans" xmlns:security="http://www.springframework.org/schema/security" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.0.xsd http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security-3.0.xsd">

  <security:authentication-manager alias="authenticationManager">
    <security:authentication-provider user-service-ref="userService">
      <security:password-encoder hash="sha" />
    </security:authentication-provider>
  </security:authentication-manager>

  <security:http auto-config="true">
    <security:intercept-url pattern="/*" access="IS_AUTHENTICATED_ANONYMOUSLY" />
    <security:intercept-url pattern="/css/**" filters="none" />
    <security:intercept-url pattern="/images/**" filters="none" />
    <security:logout logout-url="/logout" logout-success-url="/gwt.html" />
    <security:remember-me key="gwtSecurity" />
  </security:http>

  <bean id="rememberMeServices" class="org.springframework.security.web.authentication.rememberme.TokenBasedRememberMeServices">
    <property name="alwaysRemember" value="true" />
    <property name="userDetailsService" ref="userService" />
    <property name="key" value="gwtSecurity" />
  </bean>

</beans>
```

## Configuration de la servlet pour les appels RPC

On utilise ici Gilead et GWT-SL.

**rpc-dispatcher-servlet.xml**

```xml
<beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.0.xsd">

  <bean id="urlMapping" class="org.springframework.web.servlet.handler.SimpleUrlHandlerMapping">
    <property name="mappings">
      <map>
        <entry key="/user.rpc" value-ref="userRemoteService" />
        <entry key="/security.rpc" value-ref="securityRemoteService" />
      </map>
    </property>
  </bean>

  <bean id="abstractGileadRPCServiceExporter" class="org.gwtwidgets.server.spring.gilead.GileadRPCServiceExporter" abstract="true">
    <property name="beanManager" ref="persistentBeanManager" />
  </bean>

  <bean id="userRemoteService" parent="abstractGileadRPCServiceExporter">
    <property name="service" ref="userService" />
    <property name="serviceInterfaces" value="service.user.UserRemoteService" />
  </bean>

  <bean id="securityRemoteService" parent="abstractGileadRPCServiceExporter">
    <property name="service" ref="securityService" />
    <property name="serviceInterfaces" value="service.security.SecurityRemoteService" />
  </bean>

</beans>
```

## Implementation du service d'authentification

Le Authentication Manager de Spring doit pouvoir récupérer un utilisateur par son nom d'usager.
Ici c'est la class `UserService` qui implémentera l'interface `org.springframework.security.core.userdetails.UserDetailsService` pour pouvoir être utilisé par le Authentication Manager de Spring.

```java
@Service("userService")
@Transactional(readOnly = true)
public class UserServiceImpl implements UserService, UserDetailsService {

  @Override
  public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException, DataAccessException {
    if (StringUtils.isBlank(username)) throw new UsernameNotFoundException(username);

    User user = findByLogin(username);
    if (user == null) throw new UsernameNotFoundException(username);

    List<GrantedAuthority> authorities = new ArrayList<GrantedAuthority>(user.getPermissions().size());
    for (String perm : user.getPermissions()) {
      authorities.add(new GrantedAuthorityImpl(perm));
    }

    boolean enabled = user.isActive();
    boolean accountNonExpired = true;
    boolean accountNonLocked = true;
    boolean credentialsNonExpired = true;
    return new org.springframework.security.core.userdetails.User(username, user.getPassword(), enabled, accountNonExpired, credentialsNonExpired, accountNonLocked, authorities);
  }

}
```

Dans notre cas, on ne vas pas d'authentifier par un formulaire HTML qui posterait vers une adresse géré par Spring Security car tout est géré en Javascript et on ne veut pas quitter la page courante. Il va donc falloir définir un service que l'on pourra appeler via RPC pour ouvrir une session. Ce service s'occupera de gérer aussi le "Remember Me".

```java
@Service("securityService")
public class SecurityServiceImpl implements SecurityService {

  @Resource
  private AuthenticationManager authenticationManager;

  @Resource
  private RememberMeServices rememberMeServices;

  @Override
  public boolean login(String username, String password, boolean rememberMe) {
    try {
      Authentication authentication = authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(username, password));
      SecurityContextHolder.getContext().setAuthentication(authentication);
      if (rememberMe) {
        rememberMeServices.loginSuccess(ServletUtils.getRequest(), ServletUtils.getResponse(), authentication);
      }
      return authentication.isAuthenticated();
    } catch (AuthenticationException e) {
      if (rememberMe) {
        rememberMeServices.loginFail(ServletUtils.getRequest(), ServletUtils.getResponse());
      }
      return false;
    }
  }

}
```

Finalement, il en reste plus qu'à notre interface (ici avec SmartGWT) à appeler notre service d'authentification :

```java
public class LoginForm extends DynamicForm {

  private SecurityRemoteServiceAsync securityService = GWT.create(SecurityRemoteService.class);

  TextItem login;
  PasswordItem password;
  CheckboxItem rememberMe;

  void login() {
    securityService.login(username, password, remeberMe,
        new AsyncCallback<Boolean>() {
          public void onFailure(Throwable caught) {
            loginFailed();
          }

          public void onSuccess(Boolean success) {
            if (success) {
              // user successfully logged in
            } else {
              loginFailed();
            }
          }
        });
  }

}
```