# Java

Read for any JVM Java implementation task (language idioms, build, layout). Companion: `spring-boot.md` when Spring Boot starters are present.

## When to use

Any JVM Java implementation task (language-level idioms, build, layout, tests).

## Detection signals

- `pom.xml`, `build.gradle`, `build.gradle.kts`, `mvnw`, `gradlew`, `*.java` sources.

## Conventions

- Version baseline: detect from `pom.xml` (`maven.compiler.release`, `maven.compiler.source/target`, `java.version`), Gradle toolchain/`languageVersion`, `module-info.java`, README. Default to 17 when unknown. Java 17 features always safe; 21+ and 25+ features only when the detected target allows them.
- Java 17+: prefer records and `final` fields (immutable by default); `PascalCase` types, `camelCase` methods/fields, `UPPER_SNAKE_CASE` constants.
- Modern syntax (apply when target allows): `var` where the type is obvious from the RHS; text blocks for multi-line strings; switch expressions over switch statements; `List.of`/`Set.of`/`Map.of` for immutables; `java.time`, `java.nio.file`, `HttpClient` over legacy APIs.
- Java 21+ only: Virtual Threads (`Thread.ofVirtual()`, `Executors.newVirtualThreadPerTaskExecutor()`) for blocking I/O fan-out; Sequenced Collections (`reversed()`, `getFirst()`/`getLast()`); record patterns + pattern matching for `switch` for exhaustive sealed-type dispatch.
- Java 25+ only (finalized): `ScopedValue` instead of `ThreadLocal` when using virtual threads; flexible constructor bodies (validate before `super()`); module imports (`import module java.base`) only when the build targets 25+. Compact source files / instance `main()` (`void main()`) are for scripts and demos only — never for production services.
- Preview ban: Structured Concurrency, primitive patterns, Stable Values, Vector API remain preview/incubator through 25 — do not use, and do not add `--enable-preview`, unless the user explicitly requests it.
- Inject via constructors (Spring `@Service` + `final` fields). No `@Autowired` field injection.
- Return `Optional` from finders; chain `map`/`orElseThrow`, never call bare `.get()` without presence check.
- Keep stream pipelines short (`map`/`filter`/`toList`); use loops for complex nesting.
- Fail fast with domain unchecked exceptions (e.g. `MarketNotFoundException`); handle centrally via `@RestControllerAdvice`, not scattered try/catch.
- Validate inputs with Bean Validation (`@NotNull`, `@NotBlank`); declare generics explicitly, no raw types.
- Log via SLF4J with placeholder params (`log.info("fetch_market slug={}", slug)`); include the exception arg on error paths.
- Layout: `src/main/java/.../{config,controller,service,repository,domain,dto,util}`, `src/main/resources/application.yml`, tests mirroring main.
- Tests: JUnit 5 + AssertJ + Mockito; `@WebMvcTest` for controller slices, `@DataJpaTest` for repository slices, `@SpringBootTest` only for full integration.

```java
public record MarketDto(Long id, String name, MarketStatus status) {}

public Market findBySlug(String slug) {
  return marketRepository.findBySlug(slug)
      .map(Market::from)
      .orElseThrow(() -> new MarketNotFoundException(slug));
}
```

## Pitfalls

- Mutable shared static state; long parameter lists (use DTOs/builders); magic numbers (name them).
- Broad `catch (Exception ex)` without central handling; silent catch blocks.
- `Optional.get()` without check; complex nested streams; raw types.
- One public top-level type per file; keep methods short with early returns.
- Do not backport 21+/25+ idioms (virtual threads, record patterns, `ScopedValue`, module imports, instance `main()`) into a project targeting 17; respect the detected baseline.
- Do not enable preview/incubator features to force modern syntax; if code is already clean and modern, leave it.
- Quarkus-only conventions (CDI scopes, Panache active record, reactive `Uni`/`Multi`, `@ConfigMapping`) do NOT apply here — this guide covers shared + Spring conventions only.

Source: adapted from affaan-m/ECC `java-coding-standards` (shared + Spring sections; Quarkus sections excluded) — MIT, Copyright (c) 2026 Affaan Mustafa. Version-gating and modern-idiom rules informed by soujava/agent-skills `java-conventions` + `java-distiller` — MIT, Copyright (c) 2026 Maximillian Arruda; OpenJDK JDK 25 JEP index (512/511/513/506 final; 505/507/502/508 preview/incubator).
