# CI Demos – GitHub Actions + Java/Maven

This README walks you step by step from a **minimal “Hello CI” workflow** to **matrix builds (OS × Java)**.
Each step includes **explanations** and **copy‑paste code blocks** (YAML/Bash/Java).

## Prerequisites
- A **GitHub repository** (push access)
- **Git** locally
- **Java 17** (JDK) — `java -version`
- **Maven** — `mvn -v`
- Optional: an editor like VS Code or IntelliJ

---

## Project layout (after Step 2)

```text
.
├─ pom.xml
├─ src
│  ├─ main/java/com/example/hello/App.java
│  └─ test/java/com/example/hello/AppTest.java
└─ .github/workflows/ci.yml
```

---

# Demo 1 — Minimal “Hello CI” workflow

**Goal:** A first run that prints “Hello, CI!”.

**Explanation:**
- `on: [push, pull_request]` — runs on push & PR.
- One job with a single step that echoes to the logs.

### Instructions
1) Create folder `.github/workflows/`  
2) Create `ci.yml` and paste the content below  
3) Commit & push → **Actions** tab → open the run

### Copy block (YAML)
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Hello, CI!"
```

### Copy block (Bash)
```bash
mkdir -p .github/workflows
echo "foo" >> .github/workflows/ci.yml
git add .github/workflows/ci.yml
git commit -m "ci: add minimal hello workflow"
git push
```

---

# Demo 2 — Add a tiny Java project

**Goal:** A minimal Maven project (Java 17) + 2 unit tests.

**Explanation:**
- `pom.xml` sets Java version, JUnit 5 and Surefire (test plugin).
- `App.java` contains tiny logic; `AppTest.java` tests it.
- Run locally first, then push.

### Copy block (pom.xml)
```xml
<!-- pom.xml (minimal; Java 17 + JUnit 5 + Surefire 3.x) -->
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>java-hello</artifactId>
  <version>1.0.0</version>
  <properties>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <junit.jupiter.version>5.10.2</junit.jupiter.version>
  </properties>
  <dependencies>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-api</artifactId>
      <version>${junit.jupiter.version}</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-engine</artifactId>
      <version>${junit.jupiter.version}</version>
      <scope>test</scope>
    </dependency>
  </dependencies>
  <build>
    <plugins>
      <plugin>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.2.5</version>
        <configuration>
          <useModulePath>false</useModulePath>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
```

### Copy block (Java)
```java
// src/main/java/com/example/hello/App.java
package com.example.hello;

public class App {
    public static void main(String[] args) {
        System.out.println("Hello, Java CI!");
    }
    public static String greet(String name) {
        if (name == null || name.isBlank()) return "Hello, world!";
        return "Hello, " + name + "!";
    }
}
```

### Copy block (JUnit 5 tests)
```java
// src/test/java/com/example/hello/AppTest.java
package com.example.hello;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class AppTest {
    @Test void greet_default_whenNameBlank() {
        assertEquals("Hello, world!", App.greet(""));
    }
    @Test void greet_personalized() {
        assertEquals("Hello, Alice!", App.greet("Alice"));
    }
}
```

### Copy block (Bash — run locally & push)
```bash
# Run unit tests locally
mvn -q -DskipTests=false test

# Commit & push
git add .
git commit -m "feat: add minimal Java hello with tests"
git push
```

---

# Demo 3 — Extend workflow to “Build & Test (Java/Maven)”

**Goal:** Checkout + Java 17 + Maven tests in CI.

**Explanation:**
- `actions/checkout` pulls repo code.
- `actions/setup-java` installs **Temurin 17** (free OpenJDK Distribution) and enables Maven cache.
- `mvn test` runs Surefire (unit tests).
- needs: awaits finishing another job

### Copy block (YAML)
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Hello, CI!"
  
  build-test:
    needs: hello
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
          cache: maven

      - name: Build & Test
        run: mvn -B -DskipTests=false test
```

---

# Demo 4 — Upload test reports as an artifact

**Goal:** Make Surefire reports (Maven-Plugin für Unit-Tests) downloadable in Actions.

**Explanation:**
- `if: always()` ensures reports are uploaded even when tests fail.
- In GitHub Actions → run → **Artifacts** → `surefire-reports`.

### Copy block (YAML addition)
```yaml
      - name: Upload test reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: surefire-reports
          path: target/surefire-reports
```

---

# Demo 5 — Path & branch filters

**Goal:** Run CI only for relevant changes (Java/POM) and only on `main`.

**Explanation:**
- `paths`/`paths-ignore` reduce unnecessary runs (e.g., docs-only changes).
- Branch filters: CI only for `main`.

### Copy block (YAML)
```yaml
on:
  push:
    branches: [ main ]
    paths: [ 'pom.xml', 'src/**' ]
  pull_request:
    branches: [ main ]
    paths: [ 'pom.xml', 'src/**' ]
```

---

# Demo 6 — Concurrency (cancel duplicate runs)

**Goal:** Auto-cancel older runs for the same branch.

**Explanation:**
- `concurrency` groups runs by branch/ref.
- `cancel-in-progress: true` cancels older, still running builds.

### Copy block (YAML)
```yaml
# Add at workflow top-level (or job-level):
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
```

---

# Demo 7 — Matrix builds (OS × Java) + artifact naming

**Goal:** Test in parallel across multiple OS/Java versions and name artifacts per variant.

**Explanation:**
- `strategy.matrix` creates one job per combination.
- Use `${{ matrix.os }}` / `${{ matrix.java }}` in names/steps.
- `exclude` removes unneeded combinations.

### Copy block (YAML — full job)
```yaml
jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Hello, CI!"

  build-test:
    needs: hello
    name: "Test (${{ matrix.os }} / Java ${{ matrix.java }})"
    strategy:
      fail-fast: true
      matrix:
        os:   [ubuntu-latest, windows-latest]
        java: [17, 21]
        exclude:
          - os: windows-latest
            java: 21   # example: skip this combo
    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: ${{ matrix.java }}
          cache: maven

      - name: Build & Test
        run: mvn -B -DskipTests=false test

      - name: Upload test reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: surefire-${{ matrix.os }}-java${{ matrix.java }}
          path: target/surefire-reports
```


---

## Troubleshooting (quick)

- **“No tests found”** — check test class names (`*Test.java`), JUnit deps in `pom.xml`, and that you’re at the project root.
- **JDK mismatch** — ensure `setup-java` version matches the project (here **17**).
- **Fork PRs & secrets** — secrets are **not** available to untrusted PRs (by design).
- **Cache not used** — changed `pom.xml`? Key correct? Consider `restore-keys` fallback.
- **Slow runs** — enable cache, use path filters, avoid log flooding, use `fail-fast`.
