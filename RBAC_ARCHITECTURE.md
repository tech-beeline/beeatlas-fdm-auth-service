# Архитектура ролевой модели доступа (RBAC) — FDM

---

## Текущая архитектура (AS-IS)

```
Клиент (Bearer JWT)
    │
    ▼
fdm-gateway / ValidateTokenFilter
    ├─ Валидирует JWT (RSA/EAuth)
    ├─ GET /api/admin/v1/user/{login}/info → fdm-auth  →  userId, roles, permissions, productIds
    └─ Инжектирует заголовки: user-id, user-products-ids, user-roles, user-permission
    │
    ▼
Каждый сервис / HeaderInterceptor
    └─ Жёстко прописанные if/else по URI решают: нужна ли проверка и есть ли доступ
```

---

## Целевая архитектура (TO-BE)

```
Клиент (Bearer JWT)
    │
    ▼
fdm-gateway / ValidateTokenFilter
    ├─ Валидирует JWT (без изменений)
    ├─ GET /api/admin/v1/user/{login}/info → fdm-auth  (без изменений)
    ├─ POST /api/v1/authorize → fdm-auth  →  ALLOW | DENY 
    │
    ├─ ALLOW → инжектировать заголовки + пропустить
    ├─ DENY  → вернуть 403
    │
    ▼
Сервис (HeaderInterceptor остаётся до полного переноса политик, затем удаляется)
```

**Алгоритм оценки в AuthorizationService:**
```
1. Найти route по path + method (AntPathMatcher)
2. Нет route → deny
3. Найти ВСЕ подходящие policy: route + (role_alias IN user.roles) + (permission_alias IN user.permissions)
4. Нет policy → deny
5. Сгруппировать policy по priority DESC
6. Для каждой priority-группы (от высшей к низшей):
   a. Выполнить check_group каждой policy в группе
   b. Хоть одно ALLOW прошло → ALLOW (даже если DENY тоже прошло)
   c. Нет ALLOW, но есть DENY → DENY (без перехода к следующей группе)
   d. Ни одно не прошло → перейти к следующей priority-группе
7. Ни одна priority-группа не дала результат → deny

AND: несколько строк check_group с одним group_id — все должны пройти (AND внутри группы)
OR:  несколько policy одинакового priority — хоть одно ALLOW побеждает (OR между policy)
DENY побеждает только когда нет конкурирующего ALLOW в той же priority-группе
```

---

## Таблицы (schema: user_auth, миграция V0010)

Связи: `route ←── policy ──→ check_group (group_id) ──→ check_type`

**route**
| поле | тип | описание |
|---|---|---|
| `id` | bigserial PK | |
| `path_mask` | varchar | Ant-паттерн: `/api/v1/product/{productId}/structurizr-key` |
| `http_method` | varchar | GET/POST/..., NULL = любой метод |

**check_type** — реестр; каждое `name` = Java-класс `CheckStrategy`
| поле | тип | описание |
|---|---|---|
| `id` | bigserial PK | |
| `name` | varchar UNIQUE | ключ реализации: `PRODUCT_MEMBER`, `INDIRECT_PRODUCT_MEMBER`, `AUTHOR`, `OWNER` |

> Роль и пермишен — **не** check_type, проверяются через поля policy.  
> Новая проверка = строка в `check_type` + Java-класс `CheckStrategy` с тем же `name`.

**check_group** — строки группы проверок; несколько строк с одним `group_id` = AND
| поле | тип | описание |
|---|---|---|
| `id` | bigserial PK | идентификатор строки |
| `group_id` | integer NOT NULL | логический идентификатор группы (несколько строк могут иметь один `group_id`) |
| `name` | varchar | метка группы, напр. `ProductAndAuthorGroup` |
| `check_type_id` | bigint FK → check_type | одна проверка в составе группы |

> `policy.check_group_id` ссылается на `check_group.group_id` (не на `id`-строки).  
> Одна строка с `group_id=1` → одна проверка.  
> Две строки с `group_id=1` → обе должны пройти (AND).

**policy** — маршрут + роль + пермишен + группа проверок → решение
| поле | тип | описание |
|---|---|---|
| `id` | bigserial PK | |
| `route_id` | bigint FK → route | |
| `role_alias` | varchar | алиас роли, NULL = любая роль |
| `permission_alias` | varchar | алиас пермишена, NULL = не проверять |
| `effect` | varchar | `ALLOW` или `DENY` |
| `priority` | integer | чем больше, тем выше приоритет |
| `check_group_id` | integer, ссылка на `check_group.group_id` | NULL = только роль/пермишен |

> **AND**: несколько `check_group` строк с одним `group_id` — все должны пройти  
> **OR**: два policy одинакового priority — если хоть одно ALLOW прошло → ALLOW  
> **Hard DENY**: DENY policy с высоким priority проверяется первым

---

## Изменения в fdm-auth

**1. Данные (миграции)**
- `V0010` миграции
- `V0011` миграции


**2. Слой данных (JPA + репозитории)**
- JPA-entity для каждой таблицы в пакете `domain.rbac`
- `PolicyRepository` — один SQL: все подходящие policy по routeIds + roles + permissions
- `CheckGroupRepository`, `CheckTypeRepository`, `RouteRepository`

**3. Слой проверок (CheckStrategyExecutor)**

Класс `ru.beeline.fdmauth.service.rbac.CheckStrategyExecutor` — monolithic switch; каждая ветка — отдельный private-метод.

| check_type | реализация | источник данных |
|---|---|---|
| `PRODUCT_MEMBER` | не реализован (stub) | — |
| `INDIRECT_PRODUCT_MEMBER` | не реализован (stub) | — |
| `AUTHOR` | не реализован (stub) | — |
| `OWNER` | не реализован (stub) | — |
| `CJ_PRODUCT_MEMBER` | `cxClient.checkCjProductMember(id, productIds)` | cx-backend |
| `CJ_EDIT_PRODUCT_MEMBER` | `cxClient.checkCjEditAccess(id, productIds)` | cx-backend |
| `CJ_STEP_PRODUCT_MEMBER` | `cxClient.checkCjStepProductMember(id, productIds)` | cx-backend |
| `BI_PRODUCT_MEMBER` | `cxClient.checkBiProductMember(id, productIds)` | cx-backend |
| `BI_EDIT_PRODUCT_MEMBER` | `cxClient.checkBiEditAccess(id, productIds)` | cx-backend |
| `PRODUCT_MEMBER_FROM_BODY` | inline: `userInfo.productsIds.contains(body[paramKey])` | — |
| `PRODUCT_MEMBER_FROM_PATH` | inline: `userInfo.productsIds.contains(pathVars[paramKey])` | — |
| `BC_ORDER_DRAFT_OWNER` | `capabilityClient.checkBcOrderDraftOwner(orderId, userId)` | capability-backend |
| `APPLICATION_AUTHOR_OR_EXECUTOR` | `fdmBpmClient.checkApplicationAuthorOrExecutor(businessKey, userId)` | fdm-bpm |
| `APPLICATION_CURRENT_EXECUTOR` | `fdmBpmClient.checkApplicationCurrentExecutor(businessKey, userId)` | fdm-bpm |

Клиенты в `ru.beeline.fdmauth.client`:
- `CxClient` — cx-backend
- `CapabilityClient` — capability-backend (`integration.capability-server-url`)
- `FdmBpmClient` — fdm-bpm (`integration.fdm-bpm-server-url`)

Все клиенты используют `RestTemplate` + `UriComponentsBuilder`, возвращают `HasAccessDTO { boolean hasAccess }`. При ошибке возвращают `false` (fail-closed).

**4. Слой авторизации (AuthorizationService)**
- AntPathMatcher: сопоставить входящий path с `route.path_mask`
- Загрузить все подходящие policy (role + permission match)
- Сгруппировать по priority → по каждой priority-группе запустить check_group каждой policy через `CheckStrategyExecutor`
- Вернуть итоговое решение: ALLOW / DENY 

**5. Контроллер авторизации (для gateway)**
- `POST /api/v1/authorize` — принять запрос от gateway, вызвать `AuthorizationService`, вернуть решение

**6. Контроллер управления политиками (для UI)**
- `CRUD /api/admin/v1/rbac/route`
- `CRUD /api/admin/v1/rbac/check-type`
- `CRUD /api/admin/v1/rbac/check-group`
- `CRUD /api/admin/v1/rbac/policy`

---

## Реестр check_group (V0010)

| group_id | name | check_type | param_key | использует |
|---|---|---|---|---|
| 1–6 | (из V0011) | различные CX-проверки | — | cx-backend |
| 7 | `CjCreateProductGroup` | `PRODUCT_MEMBER_FROM_PATH` | `productId` | cx-backend: POST CJ |
| 8 | `CjEditProductGroup` | `CJ_EDIT_PRODUCT_MEMBER` | — | cx-backend: PATCH/PUT/DELETE CJ |
| 9 | `BcOrderDraftOwnerGroup` | `BC_ORDER_DRAFT_OWNER` | — | capability-backend: PATCH order/draft/{id} |
| 10 | `ApplicationAuthorOrExecutorGroup` | `APPLICATION_AUTHOR_OR_EXECUTOR` | — | fdm-bpm: PATCH change-status |
| 11 | `ApplicationCurrentExecutorGroup` | `APPLICATION_CURRENT_EXECUTOR` | — | fdm-bpm: PATCH executor/{new_executor_id} |
| 12 | `ProductMemberByIdGroup` | `PRODUCT_MEMBER_FROM_PATH` | `id` | fdm-products: GET structurizr-key |

---

## Паттерн перевода сервиса

Одинаковый набор изменений применяется к каждому сервису:

### В самом сервисе

**1. HeaderInterceptor → pass-through**
```java
public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
    logger.debug("Request: {} {}", request.getMethod(), request.getRequestURI());
    return true;
}
```
Всю логику (`setHeaders`, NullPointerException-бросок при отсутствии заголовков) удалить.

**2. Контроллеры: `HttpServletRequest` → `@RequestHeader`**
```java
// Было:
public ResponseEntity foo(HttpServletRequest request) {
    String userId = request.getHeader(USER_ID_HEADER);
}
// Стало:
public ResponseEntity foo(@RequestHeader(value = USER_ID_HEADER) String userId) {
}
```

**3. Сервисы: удалить проверки ролей**

Все блоки вида:
```java
if (!RequestContext.getRoles().contains("ADMINISTRATOR")) {
    throw new ForbiddenException("...");
}
```
удалить целиком — fdm-auth теперь отклоняет запрос до вызова сервиса.

**4. Сервисы: удалить `RequestContext` / каскадировать userId**

Если сервис использовал `RequestContext.getUserId()` — добавить параметр `String userId` в сигнатуру метода и каскадировать из контроллера.

**Исключение — data-filtering по ролям:** если роли нужны не для авторизации, а для фильтрации данных (например `getAssignedApplications`, `getProductsByUserAdmin`) — каскадировать `String userRolesHeader` как обычный параметр. Роли при этом НЕ используются для `ForbiddenException`.

### В fdm-auth

**5. Добавить маршруты в V0010__Add_service_policies.sql**

Три категории policy:

```sql
-- ADMINISTRATOR-only (только администратор, без доп. проверок):
INSERT INTO user_auth.policy (...) SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM ...;

-- ADMINISTRATOR bypass OR check (admin может всегда; остальные — только через check_group):
INSERT INTO user_auth.policy (...) SELECT id, 'ADMINISTRATOR', NULL, 'ALLOW', 0, NULL FROM ...;
INSERT INTO user_auth.policy (...) SELECT id, NULL,            NULL, 'ALLOW', 0, N   FROM ...; -- N = check_group_id

-- Любой аутентифицированный пользователь:
INSERT INTO user_auth.policy (...) SELECT id, NULL, NULL, 'ALLOW', 0, NULL FROM ...;
```

---

## InternalCheckController — паттерн для бизнес-логических проверок

Когда fdm-auth не может определить доступ без данных из другого сервиса, целевой сервис реализует **internal check endpoint**:

```
GET /api/v1/internal/check/{entity}/{id}/{checkType}?userId={userId}
→ { "hasAccess": true/false }
```

Пути `/api/v1/internal/**` **не регистрируются** в таблице `route` fdm-auth и не проходят через gateway — они вызываются напрямую между сервисами.

**Реализованные internal check endpoints:**

| Сервис | URL | Логика |
|---|---|---|
| capability-backend | `GET /api/v1/internal/check/bc-order-draft/{id}/owner?userId=` | `order.ownerId == userId` |
| fdm-bpm | `GET /api/v1/internal/check/application/{businessKey}/author-or-executor?userId=` | `authorId == userId \|\| executorId == userId` |
| fdm-bpm | `GET /api/v1/internal/check/application/{businessKey}/current-executor?userId=` | `executorId == userId` |

Клиент в fdm-auth (`CapabilityClient`, `FdmBpmClient`) вызывает endpoint и возвращает `result.isHasAccess()`. При сетевой ошибке → `false`.

---

## Детали перевода по сервисам

### techradar-backend (V0010)

**Что удалено из сервисов:**
- `CategoryService`: роль `ADMINISTRATOR` в `addCategory`, `putCategory`, `patchCategory`, `deleteCategory`
- `TechService`: роль `ADMINISTRATOR` в 6 методах; `RequestContext.getUserId()` → параметр `String userId` в `getTechSubscribed`
- `PatternService`: роль `ADMINISTRATOR` + `String userRoles` параметр из 6 write-методов; метод `validateAdminRole()`

**Что добавлено в fdm-auth V0010:**
- 41 маршрут; ADMINISTRATOR-only: POST tech, PATCH/DELETE tech/{id}, POST/DELETE/PATCH версий, POST/PATCH/DELETE pattern, POST/PATCH/DELETE category; остальные — ANY authenticated

---

### capability-backend (V0010)

**InternalCheckController** в capability-backend:
- `GET /api/v1/internal/check/bc-order-draft/{id}/owner?userId=`
- Проверяет `order.orderOwnerId == userId`

**fdm-auth:**
- `CapabilityClient` → `checkBcOrderDraftOwner(orderId, userId)`
- check_group 9 (`BcOrderDraftOwnerGroup`)
- `PATCH /api/v1/business-capability/order/draft/{id}`: ADMINISTRATOR bypass (group_id=NULL) OR check_group=9

---

### fdm-bpm (V0010)

**Что удалено из сервисов:**
- `ApplicationService`: `HttpServletRequest`, `RequestContext`, `ForbiddenException`; методы `getAuthorizedApplication()` и `hasAccessRole()`; роль-проверка в `changeExecutor`

**Что изменено:**
- `patchChangeStatus` и `changeExecutor` теперь принимают `String userId` как параметр
- `getAssignedApplications(String userRolesHeader)` — роли каскадируются для **фильтрации данных** (не авторизации); добавлен `parseRoles()` helper

**InternalCheckController** (новый файл):
```
GET /api/v1/internal/check/application/{businessKey}/author-or-executor?userId=
GET /api/v1/internal/check/application/{businessKey}/current-executor?userId=
```

**fdm-auth:**
- `FdmBpmClient` (новый класс): `integration.fdm-bpm-server-url`
- check_group 10 (`ApplicationAuthorOrExecutorGroup`), group 11 (`ApplicationCurrentExecutorGroup`)
- `PATCH change-status/{status_alias}`: ADMIN bypass OR group 10
- `PATCH executor/{new_executor_id}`: ADMIN bypass OR group 11

---

### fdm-products (V0010)

**Что удалено из сервисов:**
- `ProductService`: `RequestContext` (продуктовая проверка в `getKey`), `ForbiddenException` в `updateProduct`/`deleteProduct`, `UnauthorizedException`, метод `validateRoles()`
- `ChapterService`: `ForbiddenException`, метод `ensureAdministratorRole()`
- `RequirementCreateService`: `RequestContext.getRoles()` + admin-check; `RequestContext.getUserId()` → параметр `String userId`
- `RequirementVersionService`: `RequestContext.getRoles()` + admin-check

**Что изменено в контроллерах:**
- `ProductController`: `HttpServletRequest` → `@RequestHeader` в `getProducts`, `getProductsAdmin`, `updateProduct`
- `ProductDeleteController`: `HttpServletRequest` убран; `USER_ROLES_HEADER` убран
- `ChapterController`: `userRoles` убран из `createChapter` и `patchChapter`
- `RequirementController`: добавлен `@RequestHeader USER_ID_HEADER` в `createRequirement`
- `getProductsByUserAdmin`: роли каскадируются (`String userRoles`) для **фильтрации данных**

**fdm-auth:**
- 75+ маршрутов; check_group 12 (`ProductMemberByIdGroup`, PRODUCT_MEMBER_FROM_PATH, param_key=`id`)
- ADMINISTRATOR-only: `PUT /api/v1/product`, `DELETE /api/v1/product/{id}`, `POST/PATCH /api/v1/chapter`, `POST /api/v1/requirement`, `POST /api/v1/requirement/version`
- `GET /api/v1/product/{id}/structurizr-key`: ADMIN bypass OR group 12 (проверка членства в команде продукта по `userInfo.productsIds`)
- Остальные: ANY authenticated

---

## Авто-регистрация маршрутов (fdm-rbac-starter)

Чтобы не деплоить fdm-auth при каждом новом контроллере, каждый микросервис подключает общую библиотеку `fdm-rbac-starter`, которая автоматически регистрирует все его эндпоинты в fdm-auth при старте.

**Принцип работы:**

```
Сервис стартует
    └─ ApplicationReadyEvent
        ├─ Сканирует все RequestMappingHandlerMapping из Spring-контекста
        ├─ Собирает List<{method, path}> всех @RequestMapping / @GetMapping / ...
        └─ POST /api/v1/rbac/routes/register → fdm-auth
               └─ INSERT route ON CONFLICT DO NOTHING
               └─ INSERT default policy: ALLOW, role=null, priority=0
```

**Подключение в сервисе:**
```xml
<dependency>
    <groupId>ru.beeline</groupId>
    <artifactId>fdm-rbac-starter</artifactId>
</dependency>
```
```yaml
fdm:
  rbac:
    enabled: true
    auth-url: http://fdm-auth:8080
    service-name: my-service
```

**Что делает fdm-auth при получении:**
- `POST /api/v1/rbac/routes/register` — принимает `List<{method, path, serviceName}>`
- Для каждого маршрута: если не существует → создать `route` + дефолтную `policy` (ALLOW, без роли, priority=0)
- Если уже существует → пропустить (сохранять операторские настройки)
- Инвалидирует in-memory cache маршрутов

**Реализация стартера** (`ApplicationReadyEvent` listener):
```java
@EventListener(ApplicationReadyEvent.class)
public void registerRoutes(ApplicationReadyEvent event) {
    RequestMappingHandlerMapping mapping = event.getApplicationContext()
            .getBean(RequestMappingHandlerMapping.class);
    List<RouteRegistrationDTO> routes = mapping.getHandlerMethods().keySet().stream()
            .flatMap(info -> {
                Set<String> patterns = info.getPatternValues();
                Set<RequestMethod> methods = info.getMethodsCondition().getMethods();
                return patterns.stream().flatMap(path ->
                    (methods.isEmpty() ? Stream.of((String) null)
                                       : methods.stream().map(Enum::name))
                        .map(method -> new RouteRegistrationDTO(method, path, serviceName))
                );
            })
            .collect(Collectors.toList());
    restTemplate.postForObject(authUrl + "/api/v1/rbac/routes/register", routes, Void.class);
}
```

---

## Экспорт / Импорт политик (dev → prod)

**Экспорт** всех политик из окружения:
```
GET /api/admin/v1/rbac/export  →  List<PolicyFullDTO> (JSON)
```

**Импорт** в целевое окружение:
```
POST /api/admin/v1/rbac/import?reWrite=false  →  только новые, конфликты → 409 + список различий
POST /api/admin/v1/rbac/import?reWrite=true   →  новые + перезапись при конфликтах
```

**Конфликт** = существует policy с теми же (pathMask, httpMethod, roleAlias, permissionAlias, effect), но разными priority или checkTypeNames.

Типичный сценарий переноса настроек из dev в prod:
```bash
curl -s https://dev/api/admin/v1/rbac/export > policies.json
curl -X POST https://prod/api/admin/v1/rbac/import?reWrite=false \
     -H "Content-Type: application/json" -d @policies.json
```

---

## Изменения в fdm-gateway

- Создать `AuthorizationClient`: `POST /api/v1/authorize` → `AuthDecision` (ALLOW/DENY)
- Внедрить `AuthorizationClient` в `ValidateTokenFilter` после получения `userInfo`
- При `DENY` — вернуть 403, не форвардить запрос
- При `ALLOW`  — инжектировать заголовок юзер айди и форвардить
- При недоступности fdm-auth — fallback на (fail-open, не ломать продакшн)

---

## Контракт: Gateway → AuthService

**Запрос** `POST /api/v1/authorize`:
```json
{
  "path": "/api/v1/product/123/structurizr-key",
  "method": "GET",
  "userId": 456,
  "roles": ["DEVELOPER"],
  "permissions": ["DESIGN_ARTIFACT"],
  "productIds": [123, 789],
  "queryParams": { "someParam": "someValue" }
}
```

**Ответ**:
```json
{
  "decision": "ALLOW",
  "reason": "Policy#5 matched"
}
```

`decision`: `ALLOW` — пропустить | `DENY` — 403 | 

---

## Пилотный перевод: fdm-pack-loader

Перевод сервисов (по очереди)

Для каждого сервиса:
0. собрать все проверки сервиса
1. Добавить маршруты и политики в fdm-auth (миграция Vxxxx) и написать проверки в CheckStrategyExecutor  если требуются дополнительные данные из другого микросервиса - написать клиент(взять существующий) и добавить в него вызов микросервиса. если требуется реализация кконтроллера в микросервисе в котором тянут эти данные добавить ту реализацию
2. Убедиться что все внутренние REST-вызовы между сервисами не зависят от заголовков (`user-id`, `user-roles` и т.д.) — они должны работать через собственную авторизацию или без неё
3. Удалить `HeaderInterceptor` и `RequestContext` из сервиса

**Порядок перевода:**

| Сервис | Сложность | Причина |
|---|---|---|
| fdm-pack-loader | минимальная | ✅ переведён (V0010) |
| project-backend | низкая | ✅ переведён (V0010) |
| fdm-notifications-management | низкая | ✅ переведён (V0010) |
| cx-backend | средняя | ✅ переведён (V0010) |
| document-service | средняя | ✅ переведён (V0010  |
| capability-backend | средняя |✅ переведён (V0010)  |
| techradar-backend | средняя |✅ переведён (V0010)  |
| fdm-bpm | высокая | сложная бизнес-логика | ✅ переведён (V0010) 
| fdm-products | высокая | сложная логика, много эндпоинтов | ✅ переведён (V0011) |
_ auth

### Фаза 3 — Проверка внутренних вызовов между сервисами

Перед удалением HeaderInterceptor в каждом сервисе проверить:
- Все REST-вызовы, которые сервис получает от **других сервисов** (не от гейтвея) — убедиться что они не зависят от заголовков пользователя
- Пути `/api/v1/internal/**` не проходят через гейтвей — они не получат заголовки → убедиться что эти эндпоинты исключены из HeaderInterceptor
- Сервисы, которые вызывают друг друга через гейтвей, получат заголовки user-id(ALLOW)

### Фаза 4 — Финальный переход гейтвея

После перевода всех сервисов:
- Убрать `UserService` и `UserClient` из гейтвея — `authorize` возвращает всё необходимое
- Оставить только `AuthorizationClient`
- в сервисе документации есть дока...нужно  сделать pull что бы подтянуть свежее...потом сделать документацию типовую что мы тут с тобой нахреначили в итоге

