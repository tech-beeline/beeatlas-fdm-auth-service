package ru.beeline.fdmauth.exception;

public class MethodUnauthorizedException extends RuntimeException {
    public MethodUnauthorizedException(String message) {
        super(message);
    }
}
