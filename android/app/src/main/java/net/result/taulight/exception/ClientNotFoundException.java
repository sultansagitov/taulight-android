package net.result.taulight.exception;

public class ClientNotFoundException extends Exception {
    public ClientNotFoundException(String uuid) {
        super(uuid);
    }
}
