package net.result.taulight.chain;

import net.result.sandnode.chain.ReceiverChain;
import net.result.sandnode.chain.sender.BSTClientChainManager;
import net.result.sandnode.chain.receiver.UnhandledMessageTypeClientChain;
import net.result.sandnode.message.util.MessageType;
import net.result.taulight.Taulight;
import net.result.taulight.chain.client.AndroidForwardClientChain;
import net.result.taulight.dto.ChatMessageViewDTO;
import net.result.taulight.message.TauMessageTypes;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.Map;
import java.util.UUID;

public class AndroidClientChainManager extends BSTClientChainManager {
    private static final Logger LOGGER = LogManager.getLogger(AndroidClientChainManager.class);
    private final UUID uuid;
    private final Taulight taulight;

    public AndroidClientChainManager(UUID uuid, Taulight taulight) {
        super();
        this.uuid = uuid;
        this.taulight = taulight;
    }

    /** @noinspection rawtypes*/
    @Override
    public ReceiverChain createChain(MessageType type) {
        if (type == TauMessageTypes.FWD) {
            return new AndroidForwardClientChain(io, (ChatMessageViewDTO message) -> {
                LOGGER.debug("onmessage");
                Map messageJson = taulight.objectMapper.convertValue(message, Map.class);
                taulight.sendToFlutter("onmessage", Map.of(
                        "uuid", uuid.toString(),
                        "message", messageJson
                ));
            });
        }
        return new UnhandledMessageTypeClientChain(io);
    }
}
