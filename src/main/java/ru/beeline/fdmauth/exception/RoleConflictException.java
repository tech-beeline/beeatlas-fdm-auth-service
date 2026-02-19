/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.exception;

public class RoleConflictException extends RuntimeException {
    public RoleConflictException(String message) {
        super(message);
    }
}