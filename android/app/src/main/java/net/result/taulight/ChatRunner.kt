package net.result.taulight

import net.result.sandnode.serverclient.SandnodeClient
import net.result.taulight.chain.sender.ChatClientChain
import net.result.taulight.dto.ChatInfoDTO
import net.result.taulight.dto.ChatInfoPropDTO
import java.util.UUID

fun getChats(client: SandnodeClient): Collection<ChatInfoDTO> {
    val chain = ChatClientChain(client)
    client.io.chainManager.linkChain(chain)
    val infos = chain.getByMember(ChatInfoPropDTO.all())
    client.io.chainManager.removeChain(chain)
    return infos
}

fun loadChat(client: SandnodeClient, chatID: UUID): ChatInfoDTO {
    val chain = ChatClientChain(client)
    client.io.chainManager.linkChain(chain)
    val optChats = chain.getByID(listOf(chatID), ChatInfoPropDTO.all())
    client.io.chainManager.removeChain(chain)
    return optChats.first()
}