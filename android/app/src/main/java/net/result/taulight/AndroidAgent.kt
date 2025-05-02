package net.result.taulight;

import net.result.sandnode.encryption.KeyStorageRegistry;
import net.result.taulight.hubagent.TauAgent;

import java.util.Map;
import java.util.UUID;

public class AndroidAgent extends TauAgent {
    private final Taulight taulight;
    private final UUID uuid;

    public AndroidAgent(KeyStorageRegistry keyStorageRegistry, Taulight taulight, UUID uuid) {
        super(keyStorageRegistry);
        this.taulight = taulight;
        this.uuid = uuid;
    }

    public void close() {
        taulight.sendToFlutter("disconnect", Map.of("uuid", uuid.toString()));
    }
}
