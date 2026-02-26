## beeatlas-fdm-auth-service

**beeatlas-fdm-auth-service** is an authorization and access management service for FDM products.  
The service is responsible for storing user profiles, roles and permissions, as well as checking user access rights to products.  
It works together with an API Gateway that performs authentication and forwards enriched user headers to this service.

### Technology stack

- **Java 17**
- **Spring Boot 2.7.3** (`spring-boot-starter-web`, `spring-boot-starter-actuator`)
- **Spring Data JPA** + **Hibernate**
- **PostgreSQL** as the primary data store
- **Flyway** for database migrations (`src/main/resources/db/migration`)
- **Swagger (springfox)** for REST API documentation
- **Micrometer + Prometheus** for metrics
- **OpenTelemetry** (`opentelemetry-spring-boot-starter`)
- Build: **Maven**
- Containerization: **Docker**, **docker-compose**

### Service responsibilities

- **Roles**: role directory, role management, binding roles to users.
- **Permissions**: permissions directory and binding permissions to roles.
- **Products**: product storage and binding products to users.
- **Integrations with external systems**:
    - BeeWorks (`BeeWorksController`, `BWEmployeeClient`) — fetching employee product information.
    - External notification/document/product services via URLs from environment variables.

---

## Integration with API Gateway

The service expects **API Gateway** to:

- Perform user authentication (e.g. via JWT).
- Resolve internal user identifier and his access rights.
- Forward the following headers to `fdm-auth`:
    - `user-id` — user ID in the system.
    - `user-products-ids` — list of user product IDs.
    - `user-permission` — list of permissions.
    - `user-roles` — list of user roles (must contain `ADMINISTRATOR` for admin operations).

These headers are used by `AccessControlAspect`:

- `@AccessControl` annotation:
    - Validates that all required headers are present.
    - Verifies the presence of `ADMINISTRATOR` role in `user-roles`.
    - Throws `401 Unauthorized` if headers are missing.
    - Throws `403 Permission denied` if the user is not an administrator.

- `@HeaderControl` annotation:
    - Validates only presence of required headers (`user-id`, `user-products-ids`, `user-permission`, `user-roles`).
    - Used, for example, in `ProductController` for admin-related endpoints.

Swagger UI is configured with **Bearer** auth via `Authorization` header.  
The JWT token is decoded by the `JwtUtils` utility (`ru.beeline.fdmauth.utils.jwt.JwtUtils`).

---

## Service run options

### 1. Run with Docker Compose (recommended)

**Requirements:**

- Installed **Docker** and **docker-compose**.

Run from the project root:

```bash
docker-compose up -d
```

`docker-compose.yml` starts:

- **fdm-auth-postgres**
    - Image: `postgres:15-alpine`
    - Parameters (can be overridden via env vars):
        - `POSTGRES_DB` (default `fdm-auth`)
        - `POSTGRES_USER` (default `postgres`)
        - `POSTGRES_PASSWORD` (default `postgres`)
        - Port: `${FDM_AUTH_POSTGRES_NODEPORT:-5432} -> 5432`

- **fdm-auth-backend**
    - Built using the project `Dockerfile`.
    - Starts after Postgres healthcheck is successful.
    - Application port: `8080` inside container, external port:
        - `${FDM_AUTH_SERVICE_PORT:-8081} -> 8080` (by default service is available at `http://localhost:8081`).

After successful startup:

- Service healthcheck: `GET http://localhost:8081/actuator/health`
- Test greeting: `GET http://localhost:8081/`  
  Returns a string: `Welcome <app.name> <app.version>`.

### 2. Local run without Docker

**Requirements:**

- **JDK 17**
- **Maven 3.x**
- Running **PostgreSQL** instance (local or via Docker).

1. Start PostgreSQL (example via Docker):

```bash
docker run --name fdm-auth-postgres \
  -e POSTGRES_DB=fdm-auth \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -d postgres:15-alpine
```

2. Set application environment variables (similar to `docker-compose.yml`):

- `SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/fdm-auth`
- `SPRING_DATASOURCE_USERNAME=postgres`
- `SPRING_DATASOURCE_PASSWORD=postgres`
- (optional) `SPRING_JPA_HIBERNATE_DDL_AUTO=none`
- (optional) `SPRING_FLYWAY_DEFAULT_SCHEMA=user_auth`

3. Build and run the service:

```bash
mvn clean package -DskipTests
mvn spring-boot:run
```

By default, the application starts on port `8080` (unless overridden via `server.port` / env vars).

---

## Environment variables

### Database (used in docker-compose)

- **FDM_AUTH_POSTGRES_DB** — database name (default `fdm-auth`).
- **FDM_AUTH_POSTGRES_USER** — database user (default `postgres`).
- **FDM_AUTH_POSTGRES_PASSWORD** — database password (default `postgres`).
- **FDM_AUTH_POSTGRES_NODEPORT** — external Postgres port (default `5432`).

### Auth service

- **FDM_AUTH_SERVICE_PORT** — external port for the application container (default `8081`).

### Integrations with external services

Defined in `docker-compose.yml` as examples and should be configured per environment:

- **INTEGRATION_PRODUCTS_SERVER_URL** — product service URL.

---

## Main REST endpoints (brief)

Below is not an exhaustive list, but a guide to key controllers.  
For the full specification, use Swagger.

### Users (`UserController`, `/api/v1`)

- **GET `/api/v1/user/{id}`** — get user profile by ID.
- **GET `/api/v1/user?ids=1,2,...`** — get short profiles by list of IDs.
- **GET `/api/v1/user/role/{aliasRole}`** — get all users with the specified role.
- **GET `/api/v1/users`** — get all FDM users (requires `@AccessControl` → `ADMINISTRATOR` role).
- **POST `/api/v1/user/list`** — search user profiles by list of IDs.

### User administration (`AdminUserController`, `/api/admin/v1/user`)

- **GET `/api/admin/v1/user`** — list all user profiles.
- **GET `/api/admin/v1/user/find?text=...&filter=...`** — search profiles (currently returns all, logic can be refined).
- **GET `/api/admin/v1/user/{login}`** — get user profile by login.
- **GET `/api/admin/v1/user/{login}/roles`** — get user roles.
- **GET `/api/admin/v1/user/{login}/permissions`** — get user permissions.
- **PUT `/api/admin/v1/user/{login}/roles`** — set user roles.
- **GET `/api/admin/v1/user/{id}/existence`** — check user existence.
- **GET `/api/admin/v1/user/{login}/info`** — extended user info.

All controller endpoints (except a few) are protected by `@AccessControl` and require admin role.

### Roles (`RoleController`, `/api/admin/v1/roles`)

- **GET `/api/admin/v1/roles`** — get all non-deleted roles.
- **POST `/api/admin/v1/roles`** — create a new role.
- **PATCH `/api/admin/v1/roles`** — update a role.
- **GET `/api/admin/v1/roles/{id}`** — get role by ID.
- **DELETE `/api/admin/v1/roles/{id}`** — mark role as deleted (default roles cannot be deleted).
- **GET `/api/admin/v1/roles/{id}/permissions`** — get role permissions.
- **PUT `/api/admin/v1/roles/{id}/permissions`** — save role permissions (except for default roles).

All operations require `@AccessControl` (admin role).

### Permissions (`PermissionController`, `/api/admin/v1/permissions`)

- **GET `/api/admin/v1/permissions`** — get full permissions directory (also protected with `@AccessControl`).

### Products (`ProductController`, `/api`)

- **GET `/api/product/{id}/existence`** — check product existence by ID.
- **GET `/api/user/{id}/product`** — get list of products for user ID.
- **GET `/api/admin/v1/product`** — get user products by `user-id` header (`@HeaderControl` annotation).

### Profiles / BeeWorks integration (`ProfileController`, `/api/v1/profiles`)

- **GET `/api/v1/profiles/{userId}/email`** — get user email by ID.

### BeeWorks integration (`BeeWorksController`, `/api/bw`)

- **GET `/api/bw/products/{login}`** — get employee products from BeeWorks by login.

---

## Swagger documentation

Swagger is configured via `SwaggerConfig` (`ru.beeline.fdmauth.config.SwaggerConfig`).  
After the service is started, the UI is usually available at one of (depending on Springfox/Spring Boot setup):

- `http://localhost:8081/swagger-ui/`
- or `http://localhost:8081/swagger-ui/index.html`

Swagger uses **Bearer** security scheme:

- Add `Authorization: Bearer <jwt>` header to call protected endpoints.

---

## Database migrations

Migrations are located under `src/main/resources/db/migration`:

- **V0001__Create_tables.sql** — create core tables (users, roles, permissions, etc.).
- **V0002__Add_Roles_And_Permissions.sql** — seed roles and permissions directories.
- **V0003__Add_sequences.sql** — add sequences.
- **V0004__Add_Default_Role_Permissions.sql** — default permissions for base roles.
- **V0005__Add_Default_Product.sql** — add default product.
- **V0006__Add_unique_user_product_constraint.sql** — unique constraints for user–product relations.

Flyway is configured via `application.properties`:

- `spring.flyway.default-schema=user_auth`
- `spring.flyway.baseline-on-migrate=true`
- `spring.flyway.clean-disabled=true`

---

## Monitoring and healthcheck

Spring Boot Actuator exposes the following useful endpoints:

- **Health**: `GET /actuator/health`
- **Info**: `GET /actuator/info`
- **Metrics**: `GET /actuator/metrics`
- **Prometheus**: `GET /actuator/prometheus`

Some Actuator and Micrometer parameters are configured in `application.properties`:

- `management.endpoints.web.exposure.include=health,info,metrics,prometheus`
- `management.metrics.web.server.auto-time-requests=true`

The container healthcheck in `docker-compose.yml` uses `http://localhost:8080/actuator/health`.

---

## Versioning and build

- Application version is taken from `pom.xml` (`<version>1.1.9</version>`).
- Resulting artifact: `target/fdm-auth-<version>.jar`.
- Docker image is built in two stages (`Dockerfile`):
    - Build stage: jar build via Maven.
    - Runtime stage: minimal JRE image (`eclipse-temurin:17-jre-jammy`) running `java -jar app.jar`.
