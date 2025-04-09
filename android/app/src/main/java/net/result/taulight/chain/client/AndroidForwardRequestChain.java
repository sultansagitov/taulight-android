package net.result.taulight.chain.client;

import net.result.sandnode.chain.sender.ClientChain;
import net.result.sandnode.exception.DeserializationException;
import net.result.sandnode.exception.ExpectedMessageException;
import net.result.sandnode.exception.UnprocessedMessagesException;
import net.result.sandnode.message.RawMessage;
import net.result.sandnode.message.util.MessageTypes;
import net.result.sandnode.util.IOController;
import net.result.taulight.db.ChatMessage;
import net.result.taulight.message.types.ForwardRequest;
import net.result.taulight.message.types.UUIDMessage;

import java.util.UUID;

public class AndroidForwardRequestChain extends ClientChain {
    public AndroidForwardRequestChain(IOController io) {
        super(io);
    }

    public synchronized UUID sendMessage(ChatMessage message) throws UnprocessedMessagesException,
            InterruptedException, ExpectedMessageException, DeserializationException {
        send(new ForwardRequest(message));
        RawMessage raw = queue.take();
        raw.expect(MessageTypes.HAPPY);
        return new UUIDMessage(raw).uuid;
    }
}
