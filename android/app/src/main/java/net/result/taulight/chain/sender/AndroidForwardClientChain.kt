package net.result.taulight.chain.sender

import net.result.sandnode.serverclient.SandnodeClient
import net.result.taulight.Taulight
import net.result.taulight.chain.receiver.ForwardClientChain
import net.result.taulight.dto.ChatMessageViewDTO
import java.util.UUID

class AndroidForwardClientChain(client: SandnodeClient, val taulight: Taulight, val clientID: UUID)
    : ForwardClientChain(client) {
    override fun onMessage(message: ChatMessageViewDTO, decrypted: String, yourSession: Boolean) {
        val messageJson = taulight.objectMapper.convertValue(message, Map::class.java)
        taulight.sendToFlutter("onmessage", mapOf(
            "uuid" to clientID.toString(),
            "your-session" to yourSession,
            "message" to messageJson,
            "decrypted" to decrypted
        ))
    }
}
