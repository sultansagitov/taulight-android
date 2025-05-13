package net.result.taulight.chain.client

import net.result.sandnode.chain.ClientChain
import net.result.sandnode.error.ServerErrorManager
import net.result.sandnode.message.RawMessage
import net.result.sandnode.message.UUIDMessage
import net.result.sandnode.message.util.MessageTypes
import net.result.sandnode.util.IOController
import net.result.taulight.dto.ChatMessageInputDTO
import net.result.taulight.message.types.ForwardRequest
import java.util.*

class AndroidForwardRequestChain(io: IOController) : ClientChain(io) {
    @Synchronized
    fun message(input: ChatMessageInputDTO): UUID {
        send(ForwardRequest(input))

        val raw: RawMessage = queue.take()
        ServerErrorManager.instance().handleError(raw)
        raw.expect(MessageTypes.HAPPY)

        return UUIDMessage(raw).uuid
    }
}
