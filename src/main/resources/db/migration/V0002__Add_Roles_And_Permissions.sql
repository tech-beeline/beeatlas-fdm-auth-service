/* Add Roles */

INSERT INTO user_auth.role (id, name, descr, alias, deleted)
VALUES (1, 'Сотрудник', 'Дефолтная роль', 'DEFAULT', FALSE);

INSERT INTO user_auth.role (id, name, descr, alias, deleted)
VALUES (2, 'Администратор', 'Администратор', 'ADMINISTRATOR', FALSE);

/* Create sequence role_id_seq */

CREATE SEQUENCE user_auth.role_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 3
    CACHE 1
;

/* Add Permissions */

INSERT INTO user_auth.permission (id, name, descr, alias, deleted)
VALUES (1, 'Создание артефактов', 'Создание артефактов', 'CREATE_ARTIFACT', false);

INSERT INTO user_auth.permission (id, name, descr, alias, deleted)
VALUES (2, 'Редактирование артефактов', 'Редактирование артефактов', 'EDIT_ARTIFACT', false);

INSERT INTO user_auth.permission (id, name, descr, alias, deleted)
VALUES (3, 'Удаление артефактов', 'Удаление артефактов', 'DELETE_ARTIFACT', false);

insert into user_auth.permission (id, name, descr, alias, deleted)
values (4, 'Доступ к артефактам всех продуктов', 'Доступ к артиефактам всех продуктов', 'DESIGN_ARTIFACT', false);

/* Create sequence permission_id_seq */

CREATE SEQUENCE user_auth.permission_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 5
    CACHE 1
;

/* Add Role Permissions */

INSERT INTO user_auth.role_permissions (id_rec, id_permission, b_set, id_role) VALUES (1, 1, true, 2);

INSERT INTO user_auth.role_permissions (id_rec, id_permission, b_set, id_role) VALUES (2, 2, true, 2);

INSERT INTO user_auth.role_permissions (id_rec, id_permission, b_set, id_role) VALUES (3, 3, true, 2);

INSERT INTO user_auth.role_permissions (id_rec, id_permission, b_set, id_role) VALUES (4, 4, true, 2);

/* Create sequence role_permissions_id_rec_seq */

CREATE SEQUENCE user_auth.role_permissions_id_rec_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 5
    CACHE 1
;
