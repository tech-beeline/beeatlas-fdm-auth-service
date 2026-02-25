/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.exception;

public class OnlyAdminAccessException extends RuntimeException {
    public OnlyAdminAccessException(String message) {
        super(message);
    }
}
