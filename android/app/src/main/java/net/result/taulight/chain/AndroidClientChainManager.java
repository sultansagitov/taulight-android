package net.result.taulight.chain;

import net.result.sandnode.chain.ReceiverChain;
import net.result.sandnode.chain.sender.BSTClientChainManager;
import net.result.sandnode.chain.receiver.UnhandledMessageTypeClientChain;
import net.result.sandnode.message.util.MessageType;
import net.result.taulight.Taulight;
import net.result.taulight.chain.client.AndroidForwardClientChain;
import net.result.taulight.db.ServerChatMessage;
import net.result.taulight.message.TauMessageTypes;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.Map;

public class AndroidClientChainManager extends BSTClientChainManager {
    private static final Logger LOGGER = LogManager.getLogger(AndroidClientChainManager.class);
    private final String uuid;
    private final Taulight taulight;

    public AndroidClientChainManager(String uuid, Taulight taulight) {
        super();
        this.uuid = uuid;
        this.taulight = taulight;
    }

    /** @noinspection rawtypes*/
    @Override
    public ReceiverChain createChain(MessageType type) {
        if (type == TauMessageTypes.FWD) {
            return new AndroidForwardClientChain(io, (ServerChatMessage message) -> {
                LOGGER.debug("onmessage");
                Map messageJson = taulight.objectMapper.convertValue(message, Map.class);
                taulight.sendToFlutter("onmessage", Map.of(
                        "uuid", uuid,
                        "message", messageJson
                ));
            });
        }
        return new UnhandledMessageTypeClientChain(io);
    }
}
