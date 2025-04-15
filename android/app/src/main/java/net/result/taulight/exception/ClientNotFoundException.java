package net.result.taulight.exception;

import java.util.UUID;

public class ClientNotFoundException extends Exception {
    public ClientNotFoundException(UUID uuid) {
        super(uuid.toString());
    }
}
