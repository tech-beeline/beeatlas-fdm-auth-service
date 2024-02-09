package ru.beeline.fdmauth.exception;

public class RoleConflictException extends RuntimeException {
    public RoleConflictException(String message) {
        super(message);
    }
}