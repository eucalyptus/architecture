
## Overview
We currently use Hibernate 4.2.3 for data persistence with Java / PostgreSQL. The approach we use for Hibernate configuration has been deprecated for a while and is removed in later releases, this block upgrading Hibernate. We use two main approaches for data base access with Hibernate:


* Query by example
* Hibernate criteria API

both of these are deprecated Hibernate specific approaches.


## Analysis

### Hibernate specific functionality
In addition to the APIs used for configuration and querying we use Hibernate specific functionality for:


* Index annotations
* Auxiliary database objects
* Interceptors
* Flushing
* Large object annotations (large text)

    


### JPA metamodel (Typed criteria queries)
The JPA static metamodel allows for type-safe queries via build time code generation. Hibernate provides an APT for generation as a separate JAR for 4.2.3 or included with the regular packages for later releases.

Example query:


```java
CriteriaQuery<Person> criteria = builder.createQuery( Person.class );
Root<Person> personRoot = criteria.from( Person.class );
criteria.select( personRoot );
criteria.where( builder.equal( personRoot.get( Person_.eyeColor ), "brown" ) );

List<Person> people = em.createQuery( criteria ).getResultList();
for ( Person person : people ) {
    ...
}
```
From: [http://docs.jboss.org/hibernate/orm/5.0/userGuide/en-US/html_single/#criteria](http://docs.jboss.org/hibernate/orm/5.0/userGuide/en-US/html_single/#criteria)

We would need to update our build to enable this class generation.


### Groovy vs APT
Annotation processing tools do not work with Groovy so we could not have Groovy entities.


### Querydsl
Querydsl allows type-safe queries with cleaner syntax than the JPA metamodel and advertises better discoverability due to a fluent API:


```java
List<Person> persons = queryFactory.selectFrom(person)
  .where(
    person.firstName.eq("John"),
    person.lastName.eq("Doe"))
  .fetch();
```

### HQL vs JPQL
JPQL is a subset of HQL. The type-safe API appears appropriate for most usage so this API should be avoided.


### NoSQL support
Hibernate OGM has some support (including JPQL?) for Cassandra, Querydsl has some support for MongoDB.

For portability between datastores the best approach is likely to code services against higher level abstractions rather than any particular persistence API.


### Service modularity
If making changes to Hibernate configuration we may want to invest some time ensuring that the approach we use is compatible with modular services.


### Lazy / eager loading
JPA has improved


## Candidate solutions

### Replace Groovy entities
There is not much need to use Groovy for entities, we should replace with Java versions.


### Persistence configuration
Not clear what the best approach is, but no architectural issues anticipated.


### Persistence API
Switch to typed criteria API (JPA) or similar Querydsl approach for new code. Deprecate but continue use of existing APIs (Entities#..., etc) for short term.


## Risks

### Build issues
There may be some complexity in building with both Groovy and APT code generation.


### Hibernate specific features
There is some risk that upgrade or changing the approach to persistence configuration will disable some hibernate specific functionality such as eager/lazy loading, auxiliary database objects, etc. Further investigation is required to determine if this is the case.


## References

* Hibernate [JPA criteria queries (jboss.org)](http://docs.jboss.org/hibernate/orm/5.0/userGuide/en-US/html_single/#criteria)
* HIbernate [legacy criteria queries (jboss.org)](http://docs.jboss.org/hibernate/orm/5.0/userGuide/en-US/html_single/#appendix-legacy-criteria)
* Hibernate [HQL and JPQL (jboss.org)](http://docs.jboss.org/hibernate/orm/5.0/userGuide/en-US/html_single/#hql)
* [Querydsl (querydsl.com)](http://www.querydsl.com/)



*****

[[tag:confluence]]
[[tag:rls-4.3]]
[[tag:persistence]]
