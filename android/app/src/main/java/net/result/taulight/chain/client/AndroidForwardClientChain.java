package net.result.taulight.chain.client;

import android.annotation.TargetApi;
import android.os.Build;

import net.result.sandnode.util.IOController;
import net.result.taulight.chain.receiver.ForwardClientChain;
import net.result.taulight.dto.ChatMessageViewDTO;
import net.result.taulight.message.types.ForwardResponse;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class AndroidForwardClientChain extends ForwardClientChain {
    public interface OnMessage {
        void handle(ChatMessageViewDTO message);
    }
    private static final Logger LOGGER = LogManager.getLogger(AndroidForwardClientChain.class);
    private final OnMessage onMessage;

    public AndroidForwardClientChain(IOController io, OnMessage onMessage) {
        super(io);
        this.onMessage = onMessage;
    }

    @Override
    @TargetApi(Build.VERSION_CODES.O)
    public void onMessage(ForwardResponse response) {
        LOGGER.info(response);
        ChatMessageViewDTO message = response.getServerMessage();
        onMessage.handle(message);
    }
}
