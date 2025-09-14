package net.result.taulight

import net.result.sandnode.chain.sender.DEKClientChain
import net.result.sandnode.dto.PaginatedDTO
import net.result.sandnode.encryption.SymmetricEncryptions
import net.result.sandnode.encryption.interfaces.KeyStorage
import net.result.sandnode.exception.error.KeyStorageNotFoundException
import net.result.sandnode.key.GeneratedSource
import net.result.sandnode.serverclient.SandnodeClient
import net.result.sandnode.util.Member
import net.result.taulight.chain.sender.MessageClientChain
import net.result.taulight.chain.sender.UpstreamClientChain
import net.result.taulight.dto.ChatInfoDTO
import net.result.taulight.dto.ChatMessageInputDTO
import net.result.taulight.dto.ChatMessageViewDTO
import net.result.taulight.dto.UpstreamResponseDTO
import org.apache.logging.log4j.LogManager
import org.apache.logging.log4j.Logger
import java.util.*

object MessageRunner {
    val LOGGER: Logger = LogManager.getLogger("MessageRunner")
}

fun send(
    client: SandnodeClient,
    chat: ChatInfoDTO,
    content: String,
    repliedToMessages: Set<UUID>,
    fileIDs: Set<UUID>
): Map<String, String> {
    if (chat.chatType == ChatInfoDTO.ChatType.DIALOG) {
        val agent = client.node().agent()
        val receiver = chat.otherNickname

        try {
            agent.config.loadDEK(Member(client), Member(receiver, client.address))
        } catch (_: KeyStorageNotFoundException) {
            val source = GeneratedSource()
            val key = SymmetricEncryptions.AES.generate()
            val encryptor: KeyStorage = try {
                agent.config.loadEncryptor(Member(receiver, client.address))
            } catch (_: KeyStorageNotFoundException) {
                // Load key if agent have no it
                val chain = DEKClientChain(client)
                client.io().chainManager.linkChain(chain)
                val e = chain.getKeyOf(receiver).keyStorage()
                client.io().chainManager.removeChain(chain)
                e
            }
            val chain = DEKClientChain(client)
            client.io().chainManager.linkChain(chain)
            chain.sendDEK(source, receiver, encryptor, key)
            client.io().chainManager.removeChain(chain)
        }
    }

    val message = ChatMessageInputDTO()
        .setChatID(chat.id)
        .setRepliedToMessages(repliedToMessages)
        .setFileIDs(fileIDs)
        .setSentDatetimeNow()

    val chain = UpstreamClientChain.getNamed(client, chat.id)
    val dto: UpstreamResponseDTO = chain.sendMessage(chat, message, content, false, false)
    client.io().chainManager.removeChain(chain)

    MessageRunner.LOGGER.info("Message ID: {}", dto.id)

    return mutableMapOf(
        "id" to dto.id.toString(),
        "creation-date" to dto.creationDate.toString(),
    ).apply { message.keyID?.let { put("key", it.toString()) } }
}

fun loadMessages(client: SandnodeClient, chatID: UUID, index: Int, size: Int): PaginatedDTO<ChatMessageViewDTO> {
    val chain = MessageClientChain(client)
    client.io().chainManager.linkChain(chain)
    val paginated = chain.getMessages(chatID, index, size)
    client.io().chainManager.removeChain(chain)
    return paginated
}
