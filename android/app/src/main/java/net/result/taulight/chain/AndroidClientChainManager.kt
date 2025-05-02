package net.result.taulight.chain

import net.result.sandnode.chain.ReceiverChain
import net.result.sandnode.chain.BSTClientChainManager
import net.result.sandnode.chain.receiver.UnhandledMessageTypeClientChain
import net.result.sandnode.message.util.MessageType
import net.result.taulight.Taulight
import net.result.taulight.chain.receiver.ReactionResponseClientChain
import net.result.taulight.chain.client.AndroidForwardClientChain
import net.result.taulight.dto.ChatMessageViewDTO
import net.result.taulight.message.TauMessageTypes

import org.apache.logging.log4j.LogManager
import org.apache.logging.log4j.Logger

import java.util.Map
import java.util.UUID

class AndroidClientChainManager(val uuid: UUID, val taulight: Taulight) : BSTClientChainManager() {
    companion object {
        private val LOGGER: Logger = LogManager.getLogger(AndroidClientChainManager::class.java)
    }

    override fun createChain(type: MessageType): ReceiverChain = when (type) {
        TauMessageTypes.FWD -> AndroidForwardClientChain(io) { message, yourSession ->
            LOGGER.debug("onmessage")
            val messageJson = taulight.objectMapper.convertValue(message, Map::class.java)
            taulight.sendToFlutter("onmessage", mapOf(
                "uuid" to uuid.toString(),
                "your-session" to yourSession,
                "message" to messageJson
            ))
        }
        else -> UnhandledMessageTypeClientChain(io)
    }

}
