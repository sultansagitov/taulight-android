package net.result.taulight

import net.result.sandnode.dto.PaginatedDTO
import net.result.sandnode.serverclient.SandnodeClient
import net.result.taulight.chain.sender.ForwardRequestClientChain
import net.result.taulight.chain.sender.MessageClientChain
import net.result.taulight.dto.ChatMessageInputDTO
import net.result.taulight.dto.ChatMessageViewDTO
import java.util.UUID

fun send(client: SandnodeClient, chatID: UUID, content: String, repliedToMessages: Set<UUID>): UUID {
    val chain = ForwardRequestClientChain(client)

    client.io.chainManager.linkChain(chain)

    val message = ChatMessageInputDTO()
        .setChatID(chatID)
        .setContent(content)
        .setRepliedToMessages(repliedToMessages)
        .setSentDatetimeNow()

    val id = chain.message(message)

    client.io.chainManager.removeChain(chain)

    return id
}

fun loadMessages(client: SandnodeClient, chatID: UUID, index: Int, size: Int): PaginatedDTO<ChatMessageViewDTO> {
    val chain = MessageClientChain(client)
    client.io.chainManager.linkChain(chain)
    val paginated = chain.getMessages(chatID, index, size)
    client.io.chainManager.removeChain(chain)
    return paginated
}