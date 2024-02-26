package ru.beeline.fdmauth.exception;

public class OnlyAdminAccessException extends RuntimeException {
    public OnlyAdminAccessException(String message) {
        super(message);
    }
}
