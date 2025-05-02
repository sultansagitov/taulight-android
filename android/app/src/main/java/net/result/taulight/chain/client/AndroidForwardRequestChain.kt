package net.result.taulight.chain.client;

import net.result.sandnode.chain.sender.ClientChain;
import net.result.sandnode.error.ServerErrorManager;
import net.result.sandnode.exception.DeserializationException;
import net.result.sandnode.exception.ExpectedMessageException;
import net.result.sandnode.exception.UnknownSandnodeErrorException;
import net.result.sandnode.exception.UnprocessedMessagesException;
import net.result.sandnode.exception.error.SandnodeErrorException;
import net.result.sandnode.message.RawMessage;
import net.result.sandnode.message.UUIDMessage;
import net.result.sandnode.message.util.MessageTypes;
import net.result.sandnode.util.IOController;
import net.result.taulight.dto.ChatMessageInputDTO;
import net.result.taulight.message.types.ForwardRequest;

import java.util.UUID;

public class AndroidForwardRequestChain extends ClientChain {
    public AndroidForwardRequestChain(IOController io) {
        super(io);
    }

    public synchronized UUID message(ChatMessageInputDTO input)
            throws InterruptedException, DeserializationException, ExpectedMessageException,
            UnknownSandnodeErrorException, UnprocessedMessagesException, SandnodeErrorException {
        send(new ForwardRequest(input));
        RawMessage raw = queue.take();
        ServerErrorManager.instance().handleError(raw);
        raw.expect(MessageTypes.HAPPY);
        return new UUIDMessage(raw).uuid;
    }
}
