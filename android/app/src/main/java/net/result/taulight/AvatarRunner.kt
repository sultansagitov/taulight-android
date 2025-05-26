package net.result.taulight

import net.result.sandnode.chain.sender.WhoAmIClientChain
import net.result.sandnode.dto.FileDTO
import net.result.sandnode.serverclient.SandnodeClient

fun getAvatar(client: SandnodeClient): FileDTO? {
    val chain = WhoAmIClientChain(client)
    client.io.chainManager.linkChain(chain)

    val avatar = chain.avatar
    client.io.chainManager.removeChain(chain)

    return avatar
}

fun setAvatar(client: SandnodeClient, path: String) {
    val chain = WhoAmIClientChain(client)
    client.io.chainManager.linkChain(chain)
    chain.setAvatar(path)
    client.io.chainManager.removeChain(chain)
}
