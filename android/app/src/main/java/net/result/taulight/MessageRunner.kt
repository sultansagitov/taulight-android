package net.result.taulight

import net.result.sandnode.chain.sender.DEKClientChain
import net.result.sandnode.config.KeyEntry
import net.result.sandnode.dto.KeyDTO
import net.result.sandnode.dto.PaginatedDTO
import net.result.sandnode.encryption.SymmetricEncryptions
import net.result.sandnode.exception.error.KeyStorageNotFoundException
import net.result.sandnode.hubagent.Agent
import net.result.sandnode.serverclient.SandnodeClient
import net.result.taulight.chain.sender.ForwardRequestClientChain
import net.result.taulight.chain.sender.MessageClientChain
import net.result.taulight.dto.ChatMessageInputDTO
import net.result.taulight.dto.ChatMessageViewDTO
import org.apache.logging.log4j.LogManager
import java.util.*

object MessageRunner {
    val LOGGER = LogManager.getLogger("MessageRunner")!!
}

fun groupSend(client: SandnodeClient, chatID: UUID, content: String, repliedToMessages: Set<UUID>): Map<String, String> {
    val chain = ForwardRequestClientChain(client)

    client.io.chainManager.linkChain(chain)

    val message = ChatMessageInputDTO()
        .setChatID(chatID)
        .setContent(content)
        .setRepliedToMessages(repliedToMessages)
        .setSentDatetimeNow()

    val id = chain.message(message)

    client.io.chainManager.removeChain(chain)

    return mutableMapOf("message" to id.toString())
}

fun dialogSend(
    client: SandnodeClient,
    nickname: String,
    chatID: UUID,
    content: String,
    repliedToMessages: Set<UUID>
): Map<String, String> {
    val chain = ForwardRequestClientChain(client)

    client.io.chainManager.linkChain(chain)

    val message = ChatMessageInputDTO()
        .setChatID(chatID)
        .setRepliedToMessages(repliedToMessages)
        .setSentDatetimeNow()

    var dekChain: DEKClientChain? = null
    var dek: KeyEntry? = null
    try {
        val agent = client.node as Agent

        dek = try {
            agent.config.loadDEK(nickname)
        } catch (_: KeyStorageNotFoundException) {
            dekChain = DEKClientChain(client)
            client.io.chainManager.linkChain(dekChain)

            val encryptor = try {
                agent.config.loadEncryptor(nickname)
            } catch (_: KeyStorageNotFoundException) {
                val dto = dekChain.getKeyOf(nickname)
                KeyEntry(dto.keyID, dto.keyStorage)
            }

            val dek = SymmetricEncryptions.AES.generate()
            val dekID = dekChain.sendDEK(nickname, KeyDTO(encryptor.id, encryptor.keyStorage), dek)

            agent.config.saveDEK(nickname, dekID, dek)

            KeyEntry(dekID, dek)
        } finally {
            dekChain?.also { client.io.chainManager.removeChain(it) }
        }

        message.setEncryptedContent(dek!!.id, dek.keyStorage, content)
    } catch (e: Exception) {
        MessageRunner.LOGGER.error("Sending unencrypted", e)
        message.setContent(content)
    }

    val id = chain.message(message)

    client.io.chainManager.removeChain(chain)

    return mutableMapOf("message" to id.toString()).apply { dek?.id?.let { put("key", it.toString()) } }
}

fun loadMessages(client: SandnodeClient, chatID: UUID, index: Int, size: Int): PaginatedDTO<ChatMessageViewDTO> {
    val chain = MessageClientChain(client)
    client.io.chainManager.linkChain(chain)
    val paginated = chain.getMessages(chatID, index, size)
    client.io.chainManager.removeChain(chain)
    return paginated
}