package ru.beeline.fdmauth.exception;

public class NameConflictException extends RuntimeException {
    public NameConflictException(String message) {
        super(message);
    }
}
