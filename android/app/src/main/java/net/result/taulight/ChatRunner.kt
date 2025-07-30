package net.result.taulight

import android.util.Base64
import net.result.sandnode.chain.sender.DEKClientChain
import net.result.sandnode.dto.DEKResponseDTO
import net.result.sandnode.exception.error.KeyStorageNotFoundException
import net.result.sandnode.serverclient.SandnodeClient
import net.result.taulight.chain.sender.ChatClientChain
import net.result.taulight.dto.ChatInfoDTO
import net.result.taulight.dto.ChatInfoPropDTO
import org.apache.logging.log4j.LogManager
import java.util.*

object ChatRunner {
    val LOGGER = LogManager.getLogger("ChatRunner")!!
}

fun getChats(client: SandnodeClient): List<Map<String, Any>> {
    val chain = ChatClientChain(client)
    client.io().chainManager.linkChain(chain)
    val infos = chain.getByMember(ChatInfoPropDTO.all())
    client.io().chainManager.removeChain(chain)
    return infos.map {
        taulight!!.addChat(it)

        val map: MutableMap<String, Any> = mutableMapOf(
            "chat" to taulight!!.objectMapper.convertValue(it, Map::class.java)!!
        )

        try {
            decrypt(client, it)
            map["decrypted-last-message"] = it.decryptedMessage!!
        } catch (e: KeyStorageNotFoundException) {
            ChatRunner.LOGGER.error("Send to flutter without decrypting - {}, {}", client, it, e)
        }

        map
    }
}

fun loadChat(client: SandnodeClient, chatID: UUID): Map<String, Any> {
    val chain = ChatClientChain(client)
    client.io().chainManager.linkChain(chain)
    val optChats = chain.getByID(listOf(chatID), ChatInfoPropDTO.all())
    client.io().chainManager.removeChain(chain)

    val chat = optChats.first()

    taulight!!.addChat(chat)

    val map: MutableMap<String, Any> = mutableMapOf(
        "chat" to taulight!!.objectMapper.convertValue(chat, Map::class.java)!!
    )

    if (chat.lastMessage != null) {
        try {
            decrypt(client, chat)
            map["decrypted-last-message"] = chat.decryptedMessage!!
        } catch (e: KeyStorageNotFoundException) {
            ChatRunner.LOGGER.error("Send to flutter without decrypting - {}, {}", client, chat, e)
        }
    }
    return map
}

private fun decrypt(client: SandnodeClient, chat: ChatInfoDTO) {
    ChatRunner.LOGGER.info("Decrypting message with id {}", chat.lastMessage!!.id)

    try {
        chat.decrypt(client)
    } catch (e: KeyStorageNotFoundException) {
        val chain = DEKClientChain(client)
        client.io().chainManager.linkChain(chain)
        val deks = chain.get()
        ChatRunner.LOGGER.debug("DEKs from hub - {}", deks)
        client.io().chainManager.removeChain(chain)

        val agent = client.node().agent()

        var decrypted = false
        for (dto: DEKResponseDTO in deks) {
            val keyStorage = dto.dek.decrypt(agent.config.loadPersonalKey(client.address, client.nickname))
            agent.config.saveDEK(client.address, chat.otherNickname, dto.dek.id, keyStorage)

            if (dto.dek.id == chat.lastMessage!!.message.keyID) {
                val bytes = Base64.decode(chat.lastMessage!!.message.content, Base64.NO_WRAP)
                chat.decryptedMessage = keyStorage.encryption().decrypt(bytes, keyStorage)
                decrypted = true
            }
        }

        if (!decrypted) {
            throw e;
        }
    }
}
