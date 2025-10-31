# CI Demos – GitHub Actions + Java/Maven

This repository is the entrypoint for the lecture "**Continous Integration / Continous Delivery**" in the **Mobile Computing** Bachelors degree by **FH-Prof. Dr. Marc Kurz**. The README contains all necessary information for a step-by-step construction of a CI pipeline.


This README walks you step by step from a **minimal “Hello CI” workflow** to **matrix builds (OS × Java)** and **SonarCloud** integration.
Each step includes **explanations** and **copy‑paste code blocks** (YAML/Bash/Java).

## Hint: 
- start from empty repo containing only the Readme.md

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

# LVA-Lecture 02: Demo 1 — Minimal “Hello CI” workflow

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

---

# LVA-Lecture 03: SonarCloud Integration

## Demo 1 — Add JaCoCo coverage locally

**Goal:** produce a coverage report SonarCloud can ingest.

Add to pom.xml (single module):

```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.jacoco</groupId>
      <artifactId>jacoco-maven-plugin</artifactId>
      <version>0.8.11</version>
      <executions>
        <execution>
          <goals>
            <goal>prepare-agent</goal>
          </goals>
        </execution>
        <execution>
          <id>report</id>
          <phase>test</phase>
          <goals>
            <goal>report</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>

```


### Copy block (Bash)
Run locally: 

```bash
mvn -q -DskipTests=false test
ls -la target/site/jacoco/jacoco.xml   # coverage report

```


## Demo 2 — Create SonarCloud project & token

1. In SonarCloud: create org/project (GitHub-linked)
2. Generate SONAR_TOKEN (user token)
3. Note organization and projectKey
4. In GitHub repo → Settings → Secrets and variables → Actions → New repository secret:
	- SONAR_TOKEN = your token
	- (optional) SONAR_PROJECT_KEY, SONAR_ORGANIZATION if not using auto-detect
	- Docs: SonarCloud + GitHub Actions overview & action page.

## Demo 3 — CI job: build, test, coverage, Sonar scan

Add/replace `.github/workflows/ci.yml`:

```yaml
name: CI
on:
  push:
    branches: [ main ]
    paths: [ 'pom.xml', 'src/**', '.github/workflows/**' ]
  pull_request:
    branches: [ main ]
    paths: [ 'pom.xml', 'src/**', '.github/workflows/**' ]

permissions:
  contents: read

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-test-analyze:
    name: "Build, Test, Analyze"
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
          cache: maven

      - name: Build & Test (with coverage)
        run: mvn -B -DskipTests=false test

      - name: Upload test reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: surefire-reports
          path: target/surefire-reports

      - name: Upload JaCoCo HTML (optional)
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: jacoco-site
          path: target/site/jacoco

      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@v2
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        with:
          # explicit params if auto-detect fails:
          # projectKey: your_org_your_project
          # organization: your_org
          args: >
             -Dsonar.projectKey=<projectkey> # mrckurz_cicd-01
             -Dsonar.organization=<organization> # mrckurz
             -Dsonar.branch.name=main  
             -Dsonar.java.binaries=target/classes
             -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
```

**Notes:**

- We pass the JaCoCo XML path explicitly. 
- We keep least-privilege permissions & add concurrency to avoid duplicate runs.
- The SonarCloud action & marketplace info are here. 
- Artifact notes & v4 details here. 


## Demo 4 — Break & fix (hands-on narrative)
- **Break:** add a nested if/else chain to push **cognitive complexity** over the rule threshold; commit; watch PR fail.
- **Fix:** refactor into small methods; complexity drops; gate passes. (Explain what “Cognitive Complexity” penalizes.)

---

# LVA-Lecture 04: Docker Containerization

## Goals
- Build a **Docker image** for the existing Java app (multi-stage).
- Run the container locally and verify behavior.
- In CI: **build the image** and **upload it as an artifact named with the commit SHA** (no registry push).
- Add **badges** to the README.

---

## Prerequisites
- Working **Java/Maven** project from earlier IL/UE (tests pass locally).
- Docker Desktop or Docker Engine (CLI available).
- GitHub repo with Actions enabled.

---

## Demo 01 — Local Containerization

### 1) Add `.dockerignore` (repo root)
Create a `.dockerignore` file to keep the build context small:
```gitignore
# build output
target/
# VCS / IDE
.git/
.gitignore
.github/
.idea/
.vscode/
# OS files
.DS_Store
```

**Why?** smaller context → faster builds; no secrets/garbage in the image layers.

### 2) Create a multi-stage `Dockerfile` (repo root)
This produces a small runtime image and keeps build tools out of production:

```Dockerfile
# ===== STAGE 1: Build =====
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

COPY pom.xml .
COPY src ./src

# Baue und liste auf, damit wir sehen, was im target/ liegt
RUN mvn -B -DskipTests=false package && ls -la target


# ===== STAGE 2: Runtime =====
FROM eclipse-temurin:17-jre
WORKDIR /app

# Kopiere das erzeugte JAR aus target nach /app/app.jar
COPY --from=build /app/target/*.jar /app/app.jar

# Wenn kein Main-Manifest vorhanden ist: starte per FQCN - fully qualified name (deine Main-Klasse)
ENTRYPOINT ["java","-cp","/app/app.jar","com.example.hello.App"]

# Falls deine App ein HTTP-Server ist, öffne den Port:
# EXPOSE 8080
```

**Notes:**
- If your artifact name isn’t *-SNAPSHOT.jar, replace the COPY pattern accordingly (e.g., /app/target/myapp.jar).
- If your app listens on a different port, change EXPOSE and your run command accordingly.

### 3) Build & run locally
```bash
# 1) build (local development tag)
docker build --no-cache -t local/app:dev .

# 2) run it (map host port to container port if your app exposes 8080)
docker run --rm --name app-demo local/app:dev   
```

To inspect the runtime image:
```bash
docker run --rm -it --entrypoint sh local/app:dev -lc 'ls -la /app'
```

Useful checks:
```bash
docker logs -f app-demo              # live logs
docker images | head                 # list images
docker history local/app:dev         # see layers
docker stop app-demo                 # stop container
```



## Demo 02: Build Image & Upload as Artifact (tagged with SHA)
Create `.github/workflows/docker.yml`:

```yaml
name: Docker Image (Artifact)

on:
  push:
    branches: [ main ]
    paths: [ 'Dockerfile', '.dockerignore', 'pom.xml', 'src/**', '.github/workflows/**' ]
  pull_request:
    branches: [ main ]
    paths: [ 'Dockerfile', '.dockerignore', 'pom.xml', 'src/**', '.github/workflows/**' ]

permissions:
  contents: read

jobs:
  docker-build-artifact:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK (warm up Maven cache for build stage)
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
          cache: maven

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Compute short SHA
        id: vars
        run: echo "short_sha=${GITHUB_SHA::7}" >> $GITHUB_OUTPUT

      # Build single-platform image and load into the Docker engine (required for docker save)
      - name: Build (load to engine)
        uses: docker/build-push-action@v6
        with:
          context: .
          platforms: linux/amd64
          load: true
          tags: local/app:${{ steps.vars.outputs.short_sha }}

      # Save the image to a tarball named with the commit SHA
      - name: Save image as artifact tar
        run: docker save -o image-${{ steps.vars.outputs.short_sha }}.tar local/app:${{ steps.vars.outputs.short_sha }}

      - name: Upload image artifact
        uses: actions/upload-artifact@v4
        with:
          name: docker-image-${{ steps.vars.outputs.short_sha }}
          path: image-${{ steps.vars.outputs.short_sha }}.tar
          retention-days: 7
```

**What this does**
- Builds the Docker image from your Dockerfile for linux/amd64 and loads it into the job’s Docker engine.
- Exports the image as image-<shortSHA>.tar and uploads it as a workflow artifact.
- You can download and load it locally with docker load -i image-<shortSHA>.tar.

Tip: Keep the Docker job separate from your Maven test job to isolate failures and keep logs focused.

## Demo 03: Badges (README)

Add badges near the top of your project `README.md`:

```md
![CI](https://github.com/<owner>/<repo>/actions/workflows/ci.yml/badge.svg)
![Docker Image](https://github.com/<owner>/<repo>/actions/workflows/docker.yml/badge.svg)
```

Replace `<owner>/<repo>` with your values.

## Troubleshooting
- **Image tar not downloadable?** Check the artifact name in the run summary; ensure the artifact step didn’t get skipped.
- **Buildx error on load**: true: Ensure you specify a single platform (e.g., linux/amd64) when using load.
- **JAR not found at COPY**: Confirm the exact JAR name in target/ and update the COPY pattern.
- **Port issues**: Confirm the app’s listening port; change EXPOSE and docker run -p mapping accordingly.
- **Large artifacts**: Consider keeping retention short (e.g., 7 days) and avoid embedding dependencies in the runtime image.