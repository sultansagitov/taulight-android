package net.result.taulight

import net.result.sandnode.dto.FileDTO
import net.result.sandnode.serverclient.SandnodeClient
import net.result.taulight.chain.sender.ChannelClientChain
import net.result.taulight.chain.sender.DialogClientChain
import java.util.UUID

fun getChannelAvatar(client: SandnodeClient, chatID: UUID): FileDTO? {
    val chain = ChannelClientChain(client)
    client.io.chainManager.linkChain(chain)
    val file = chain.getAvatar(chatID)
    client.io.chainManager.removeChain(chain)
    return file
}

fun getDialogAvatar(client: SandnodeClient, chatID: UUID): FileDTO? {
    val chain = DialogClientChain(client)
    client.io.chainManager.linkChain(chain)
    val file = chain.getAvatar(chatID)
    client.io.chainManager.removeChain(chain)
    return file
}