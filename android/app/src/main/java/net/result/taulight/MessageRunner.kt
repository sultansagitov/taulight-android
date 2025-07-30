package net.result.taulight

import net.result.sandnode.chain.sender.DEKClientChain
import net.result.sandnode.dto.PaginatedDTO
import net.result.sandnode.encryption.SymmetricEncryptions
import net.result.sandnode.encryption.interfaces.KeyStorage
import net.result.sandnode.exception.error.KeyStorageNotFoundException
import net.result.sandnode.serverclient.SandnodeClient
import net.result.taulight.chain.sender.ForwardRequestClientChain
import net.result.taulight.chain.sender.MessageClientChain
import net.result.taulight.dto.ChatInfoDTO
import net.result.taulight.dto.ChatMessageInputDTO
import net.result.taulight.dto.ChatMessageViewDTO
import java.util.*

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
            agent.config.loadDEK(client.address, receiver)
        } catch (_: KeyStorageNotFoundException) {
            val key = SymmetricEncryptions.AES.generate()
            val encryptor: KeyStorage = try {
                agent.config.loadEncryptor(client.address, receiver)
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
            val uuid = chain.sendDEK(receiver, encryptor, key)
            client.io().chainManager.removeChain(chain)

            agent.config.saveDEK(client.address, receiver, uuid, key)
        }
    }

    val chain = ForwardRequestClientChain(client)

    client.io().chainManager.linkChain(chain)

    val message = ChatMessageInputDTO()
        .setChatID(chat.id)
        .setContent(content)
        .setRepliedToMessages(repliedToMessages)
        .setFileIDs(fileIDs)
        .setSentDatetimeNow()

    val id = chain.messageWithoutFallback(chat, message, content)

    client.io().chainManager.removeChain(chain)

    return mutableMapOf("message" to id.toString())
}

fun loadMessages(client: SandnodeClient, chatID: UUID, index: Int, size: Int): PaginatedDTO<ChatMessageViewDTO> {
    val chain = MessageClientChain(client)
    client.io().chainManager.linkChain(chain)
    val paginated = chain.getMessages(chatID, index, size)
    client.io().chainManager.removeChain(chain)
    return paginated
}
