/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.exception;

public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(String message) {
        super(message);
    }
}
