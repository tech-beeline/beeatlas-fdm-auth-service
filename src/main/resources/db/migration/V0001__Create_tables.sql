/* Create Tables */

CREATE TABLE user_auth.permission
(
    id integer NOT NULL,	-- Уникальный идентификатор разрешения
    name varchar(80) NOT NULL,	-- Имя разрешения
    descr varchar(255) NULL,	-- Описание разрешения
    alias varchar(50) NOT NULL,	-- Алиас разрешения для enum внутри java кода
    deleted boolean NULL   DEFAULT false	-- Признак удаленного разрешения (физически строки из таблицы не  удаляем, проставляем этот признак)
);

CREATE TABLE user_auth.product
(
    id integer NOT NULL,	-- Внешний идентификатор продукта из MyProduct
    name varchar(250) NOT NULL,	-- Имя продукта
    alias varchar(50) NOT NULL	-- Алиас (код) продукта
);

CREATE TABLE user_auth.role
(
    id integer NOT NULL,	-- Уникальный идентификатор роли
    name varchar(80) NOT NULL,	-- Имя роли
    descr varchar(255) NULL,	-- Описание роли
    alias varchar(50) NOT NULL,	-- Алиас роли для enum в Java
    deleted boolean NULL   DEFAULT false	-- Признак удаленной роли. Строки в таблице не удаляем, помечаем признаком.
);

CREATE TABLE user_auth.role_permissions
(
    id_rec integer NOT NULL,	-- идентификатор записи, первичный ключ
    id_permission integer NOT NULL,	-- идентификатор разрешения
    b_set boolean NOT NULL,	-- флаг установки пермишена
    id_role integer NOT NULL	-- Идентификатор роли
);

CREATE TABLE user_auth.user_product
(
    id_rec integer NOT NULL,	-- идентификатор записи, первичный ключ
    id_profile integer NULL,	-- идентификатор пользователя,, внешний ключ
    id_product integer NULL	-- Идентификатор продукта, внешний ключ
);

CREATE TABLE user_auth.user_profile
(
    id integer NOT NULL,	-- Идентификатор пользователя внутренний
    id_ext varchar(50) NOT NULL,	-- Идентификатор пользователя внешний, табельный номер
    full_name varchar(255) NOT NULL,	-- Полное имя (ФИО)
    login varchar(50) NOT NULL,	-- учетная запись, логин из AD
    last_login timestamp without time zone NULL,	-- Дата последнего входа в систему
    email varchar(100) NOT NULL	-- E-mail пользователя
);

CREATE TABLE user_auth.user_roles
(
    id_rec integer NOT NULL,	-- Идентификатор записи, первичный ключ
    id_profile integer NULL,	-- Идентификатор профиля, внешний ключ
    id_role integer NULL	-- Идентификтаор внутренней роли, внешний ключ
);

/* Create Primary Keys, Indexes, Uniques, Checks */

ALTER TABLE user_auth.permission ADD CONSTRAINT "PK_Permission"
    PRIMARY KEY (id);

ALTER TABLE user_auth.permission
    ADD CONSTRAINT "UI_Premission_Alias" UNIQUE (alias);

ALTER TABLE user_auth.product ADD CONSTRAINT "PK_Product"
    PRIMARY KEY (id);

ALTER TABLE user_auth.role ADD CONSTRAINT "PK_Role"
    PRIMARY KEY (id)
;

ALTER TABLE user_auth.role
    ADD CONSTRAINT "UI_Role_Name" UNIQUE (name);

ALTER TABLE user_auth.role_permissions ADD CONSTRAINT "PK_RolePermissions"
    PRIMARY KEY (id_rec);

CREATE INDEX "IXFK_RolePermissions_Permission" ON user_auth.role_permissions (id_permission ASC);

CREATE INDEX "IXFK_RolePermissions_Role" ON user_auth.role_permissions (id_role ASC);

ALTER TABLE user_auth.user_product ADD CONSTRAINT "PK_UserProductRolesExt"
    PRIMARY KEY (id_rec);

CREATE INDEX "IXFK_UserProductRolesExt_Product" ON user_auth.user_product (id_product ASC);

CREATE INDEX "IXFK_UserProductRolesExt_UserProfile" ON user_auth.user_product (id_profile ASC);

ALTER TABLE user_auth.user_profile ADD CONSTRAINT "PK_UserProfile"
    PRIMARY KEY (id);

ALTER TABLE user_auth.user_profile
    ADD CONSTRAINT "uniqLogin" UNIQUE (login);

ALTER TABLE user_auth.user_roles ADD CONSTRAINT "PK_UserRoles"
    PRIMARY KEY (id_rec);

CREATE INDEX "IXFK_UserRoles_Role" ON user_auth.user_roles (id_role ASC);

CREATE INDEX "IXFK_UserRoles_UserProfile" ON user_auth.user_roles (id_profile ASC);

/* Create Foreign Key Constraints */

ALTER TABLE user_auth.role_permissions ADD CONSTRAINT "FK_RolePermissions_Permission"
    FOREIGN KEY (id_permission) REFERENCES permission (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE user_auth.role_permissions ADD CONSTRAINT "FK_RolePermissions_Role"
    FOREIGN KEY (id_role) REFERENCES role (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE user_auth.user_product ADD CONSTRAINT "FK_UserProductRolesExt_Product"
    FOREIGN KEY (id_product) REFERENCES product (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE user_auth.user_product ADD CONSTRAINT "FK_UserProductRolesExt_UserProfile"
    FOREIGN KEY (id_profile) REFERENCES user_profile (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE user_auth.user_roles ADD CONSTRAINT "FK_UserRoles_Role"
    FOREIGN KEY (id_role) REFERENCES role (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE user_auth.user_roles ADD CONSTRAINT "FK_UserRoles_UserProfile"
    FOREIGN KEY (id_profile) REFERENCES user_profile (id) ON DELETE No Action ON UPDATE No Action;

/* Create Table Comments, Sequences for Autonumber Columns */

COMMENT ON TABLE user_auth.permission
    IS 'Справочная таблица хранения разрешений';

COMMENT ON COLUMN user_auth.permission.id
    IS 'Уникальный идентификатор разрешения';

COMMENT ON COLUMN user_auth.permission.name
    IS 'Имя разрешения';

COMMENT ON COLUMN user_auth.permission.descr
    IS 'Описание разрешения';

COMMENT ON COLUMN user_auth.permission.alias
    IS 'Алиас разрешения для enum внутри java кода';

COMMENT ON COLUMN user_auth.permission.deleted
    IS 'Признак удаленного разрешения (физически строки из таблицы не  удаляем, проставляем этот признак)';

COMMENT ON CONSTRAINT "PK_Permission" ON user_auth.permission IS 'Первичный ключ';

COMMENT ON CONSTRAINT "UI_Premission_Alias" ON user_auth.permission IS 'Уникальный ключ для алиаса';

COMMENT ON TABLE user_auth.product
    IS 'Таблица с описанием продуктов компании. Синхронизировать полностью не будем, наполняется новыми строками, когда какой-то пользователь, имеющий роль в этом продукте, залогинится к нам.';

COMMENT ON COLUMN user_auth.product.id
    IS 'Внешний идентификатор продукта из MyProduct';

COMMENT ON COLUMN user_auth.product.name
    IS 'Имя продукта';

COMMENT ON COLUMN user_auth.product.alias
    IS 'Алиас (код) продукта';

COMMENT ON CONSTRAINT "PK_Product" ON user_auth.product IS 'Первичный ключ';

COMMENT ON TABLE user_auth.role
    IS 'Справочник ролей в нашем продукте';

COMMENT ON COLUMN user_auth.role.id
    IS 'Уникальный идентификатор роли';

COMMENT ON COLUMN user_auth.role.name
    IS 'Имя роли';

COMMENT ON COLUMN user_auth.role.descr
    IS 'Описание роли';

COMMENT ON COLUMN user_auth.role.alias
    IS 'Алиас роли для enum в Java';

COMMENT ON COLUMN user_auth.role.deleted
    IS 'Признак удаленной роли. Строки в таблице не удаляем, помечаем признаком.';

COMMENT ON CONSTRAINT "PK_Role" ON user_auth.role IS 'первичный ключ';

COMMENT ON CONSTRAINT "UI_Role_Name" ON user_auth.role IS 'Уникальный ключ на имя роли';

COMMENT ON TABLE user_auth.role_permissions
    IS 'Разрешения привязанные к роли (внутренней)';

COMMENT ON COLUMN user_auth.role_permissions.id_rec
    IS 'идентификатор записи, первичный ключ';

COMMENT ON COLUMN user_auth.role_permissions.id_permission
    IS 'идентификатор разрешения';

COMMENT ON COLUMN user_auth.role_permissions.b_set
    IS 'флаг установки пермишена';

COMMENT ON COLUMN user_auth.role_permissions.id_role
    IS 'Идентификатор роли';

COMMENT ON CONSTRAINT "FK_RolePermissions_Permission" ON user_auth.role_permissions IS 'Внешний ключ на разрешение';

COMMENT ON CONSTRAINT "FK_RolePermissions_Role" ON user_auth.role_permissions IS 'внешний ключ на роль';

COMMENT ON CONSTRAINT "PK_RolePermissions" ON user_auth.role_permissions IS 'первичный ключ';

COMMENT ON TABLE user_auth.user_product
    IS 'связь пользователя с продуктом (эту инфу берем из BeeWorks и MyProduct)';

COMMENT ON COLUMN user_auth.user_product.id_rec
    IS 'идентификатор записи, первичный ключ';

COMMENT ON COLUMN user_auth.user_product.id_profile
    IS 'идентификатор пользователя,, внешний ключ';

COMMENT ON COLUMN user_auth.user_product.id_product
    IS 'Идентификатор продукта, внешний ключ';

COMMENT ON TABLE user_auth.user_profile
    IS 'Таблица с профилями внутренних пользователей';

COMMENT ON COLUMN user_auth.user_profile.id
    IS 'Идентификатор пользователя внутренний';

COMMENT ON COLUMN user_auth.user_profile.id_ext
    IS 'Идентификатор пользователя внешний, табельный номер';

COMMENT ON COLUMN user_auth.user_profile.full_name
    IS 'Полное имя (ФИО)';

COMMENT ON COLUMN user_auth.user_profile.login
    IS 'учетная запись, логин из AD';

COMMENT ON COLUMN user_auth.user_profile.last_login
    IS 'Дата последнего входа в систему';

COMMENT ON COLUMN user_auth.user_profile.email
    IS 'E-mail пользователя';

COMMENT ON TABLE user_auth.user_roles
    IS 'Список ролей (внутренних ) для пользователя';

COMMENT ON COLUMN user_auth.user_roles.id_rec
    IS 'Идентификатор записи, первичный ключ';

COMMENT ON COLUMN user_auth.user_roles.id_profile
    IS 'Идентификатор профиля, внешний ключ';

COMMENT ON COLUMN user_auth.user_roles.id_role
    IS 'Идентификтаор внутренней роли, внешний ключ';
