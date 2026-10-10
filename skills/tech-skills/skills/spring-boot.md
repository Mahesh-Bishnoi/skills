# Spring Boot

Read for Spring Boot services (starters, layers, JPA, config). Always read alongside the Java guide.

## When to use

Spring Boot services: starters, auto-configuration, DI, JPA/web layers. Read alongside the Java guide.

## Detection signals

- `spring-boot-starter-*` in `pom.xml` / `build.gradle[.kts]`, `@SpringBootApplication`, `application.yml` / `application.properties`.

## Conventions

- Version baseline: detect Boot generation from the BOM/parent (`spring-boot-starter-parent` version, `springBootVersion`) and Java baseline from the build file. Boot 3 and Boot 4 both require Java 17 minimum; Boot 4 adds first-class Java 25 support, Jakarta EE 11 + Servlet 6.1, no Undertow (Tomcat/Jetty only). Never assume Boot 4 APIs on a Boot 3 project.
- Thin controllers → focused services → simple repositories. Constructor injection; no field injection.
- Controllers return `ResponseEntity` with DTO records; validate with `@Valid @RequestBody`; paginate with `PageRequest` + `Sort`.
- DTOs as records with Bean Validation (`@NotBlank`, `@Size`, `@FutureOrPresent`); separate request/response types with `from(...)` mappers.
- Centralize errors in `@ControllerAdvice` (validation → 400, access denied → 403, generic → 500 with logging); enable `spring.mvc.problemdetails.enabled=true` (Boot 3+, RFC 7807); on Boot 3.6+/4 prefer `ProblemDetail` for new API error formats.
- Services own transactions: `@Transactional` for writes, `@Transactional(readOnly = true)` for queries; keep transactions short.
- JPA: lean `@Entity` with `@Table` indexes, `@Enumerated(EnumType.STRING)`, `@CreatedDate`/`@LastModifiedDate` + `@EnableJpaAuditing`; default lazy, `JOIN FETCH` or projections for reads; never `EAGER` collections.
- Repositories extend `JpaRepository`; derived finders (`findBySlug`) plus `@Query` JPQL with `Pageable`; index filter columns (`status`, `slug`).
- Schema via Flyway/Liquibase migrations — never Hibernate auto-DDL in production; batch writes (`saveAll`, `hibernate.jdbc.batch_size`).
- Caching needs `@EnableCaching` (`@Cacheable`/`@CacheEvict`); async needs `@EnableAsync` (`@Async`); structured logs, Micrometer + Prometheus/OTel for metrics/tracing.
- Profiles for dev/staging/prod; configure HikariCP pool sizes and timeouts for the workload.
- Tests: slice tests (`@WebMvcTest`, `@DataJpaTest` with Testcontainers) over full `@SpringBootTest`; assert SQL efficiency via Hibernate SQL logs. Authn/authz hardening → `hardening` skill (build controls in; `security-audit` is for deep audits of existing code).
- Boot 4 only (apply when Boot 4 detected, never backport to Boot 3): check modular starters first when auto-configuration goes missing (e.g. Flyway/H2/test slices now need explicit starters); null safety via JSpecify `@NullMarked` packages + `@Nullable` exceptions; API versioning via `@GetMapping(version=...)` + `ApiVersionConfigurer`; HTTP clients via `@ImportHttpServices` + `@HttpExchange`; programmatic beans via `BeanRegistrar` (not `BeanDefinitionRegistryPostProcessor`); resilience via `@Retryable`/`@ConcurrencyLimit` without new libraries; Jackson 3 (`tools.jackson`, ISO-8601 dates by default); unified HTTP tests via `RestTestClient`; OTel via `spring-boot-starter-opentelemetry` + `management.otlp.*`/`management.tracing.sampling.probability`; migration path is 3.5 (clean deprecations) → 4.x, never skip.
- Ask before changing `pom.xml`/`build.gradle` versions, Java version, or Boot major version; never mix Spring MVC + WebFlux in one service unless the project already does.

```java
@PostMapping
ResponseEntity<MarketResponse> create(@Valid @RequestBody CreateMarketRequest request) {
  return ResponseEntity.status(HttpStatus.CREATED).body(MarketResponse.from(marketService.create(request)));
}

@Query("select m from MarketEntity m left join fetch m.positions where m.id = :id")
Optional<MarketEntity> findWithPositions(@Param("id") Long id);
```

## Pitfalls

- Fat controllers with business logic; field injection; missing `@Valid` on inputs.
- N+1 from lazy collections without fetch/projection; `select *` instead of projections.
- Long transactions; entities held across transactions; auto-DDL in production.
- Trusting `X-Forwarded-For` for rate limiting without `ForwardedHeaderFilter` + trusted-proxy config — use `getRemoteAddr()`.
- Blocking calls in async paths; non-idempotent scheduled/queue handlers.
- On Boot 4: assuming removed Boot 3 deprecated APIs still exist; using Undertow; importing Jackson 2 (`com.fasterxml`) instead of Jackson 3 (`tools.jackson`); juggling `MockMvc`/`WebTestClient`/`TestRestTemplate` when `RestTestClient` fits.

Source: adapted from affaan-m/ECC `springboot-patterns` + `jpa-patterns` — MIT, Copyright (c) 2026 Affaan Mustafa. Boot 4 deltas informed by soujava/agent-skills `spring-boot-server` — MIT, Copyright (c) 2026 Maximillian Arruda; Spring Boot 4.0 release notes + 4.0 migration guide.
