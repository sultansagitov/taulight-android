package net.result.taulight

import net.result.sandnode.chain.IChain
import net.result.sandnode.chain.sender.*
import net.result.sandnode.hubagent.ClientProtocol
import net.result.sandnode.link.SandnodeLinkRecord
import net.result.sandnode.serverclient.SandnodeClient
import net.result.sandnode.util.IOController
import net.result.taulight.chain.client.AndroidForwardRequestChain
import net.result.taulight.chain.sender.*
import net.result.taulight.dto.*
import net.result.taulight.exception.ClientNotFoundException
import java.time.Duration
import java.util.*
import android.util.Base64

class Runner(val taulight: Taulight) {

    @Throws(Exception::class)
    fun connect(clientID: UUID, link: SandnodeLinkRecord): Map<String, String> {
        taulight.addClient(clientID, link)
        return mapOf("endpoint" to link.endpoint().toString(52525))
    }

    @Throws(ClientNotFoundException::class)
    fun disconnect(uuid: String): String {
        val client = taulight.getClient(uuid).client
        client.close()
        return "disconnected"
    }

    @Throws(Exception::class)
    fun send(io: IOController, chatID: String, content: String, replies: Set<UUID>): String {
        val androidChain = io.chainManager.getChain("fwd_req")
            .orElseGet {
                AndroidForwardRequestChain(io).also {
                    io.chainManager.setName(it, "fwd_req")
                    io.chainManager.linkChain(it)
                }
            } as AndroidForwardRequestChain

        val message = ChatMessageInputDTO()
            .setChatID(UUID.fromString(chatID))
            .setContent(content)
            .setRepliedToMessages(replies)
            .setSentDatetimeNow()

        return androidChain.message(message).toString()
    }

    @Throws(Exception::class)
    fun groupAdd(client: SandnodeClient, group: String): String {
        ClientProtocol.addToGroups(client.io, setOf(group))
        return "sent"
    }

    @Throws(Exception::class)
    fun getChats(client: SandnodeClient): List<*> {
        val chain = ChatClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val infos = chain.getByMember(ChatInfoPropDTO.all())
        client.io.chainManager.removeChain(chain)
        return taulight.objectMapper.convertValue(infos, List::class.java)
    }

    @Throws(Exception::class)
    fun loadMessages(client: SandnodeClient, chatID: UUID, index: Int, size: Int): Map<String, Any> {
        val chain = MessageClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val paginated = chain.getMessages(chatID, index, size)
        client.io.chainManager.removeChain(chain)
        val messages = paginated.objects
        return mapOf(
            "count" to paginated.totalCount,
            "messages" to taulight.objectMapper.convertValue(messages, List::class.java)
        )
    }

    fun loadClient(): List<Map<String, String>> {
        return taulight.clients.entries.map { (clientID, mc) ->
            mapOf(
                "uuid" to clientID.toString(),
                "endpoint" to mc.client.endpoint.toString(),
                "link" to mc.link.toString()
            )
        }
    }

    @Throws(Exception::class)
    fun loadChat(client: SandnodeClient, chatID: UUID): Any {
        val chain = ChatClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val optChats = chain.getByID(listOf(chatID), ChatInfoPropDTO.all())
        client.io.chainManager.removeChain(chain)
        return taulight.objectMapper.convertValue(optChats.first(), Map::class.java)
    }

    @Throws(Exception::class)
    fun addMember(client: SandnodeClient, chatID: UUID, otherNickname: String): Map<String, String> {
        val chain = ChannelClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val code = chain.createInviteCode(chatID, otherNickname, Duration.ofDays(1))
        client.io.chainManager.removeChain(chain)
        return mapOf("code" to code)
    }

    @Throws(Exception::class)
    fun getChannelAvatar(client: SandnodeClient, chatID: UUID): Map<String, Any> {
        val chain = ChannelClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val file = chain.getAvatar(chatID)
        client.io.chainManager.removeChain(chain)

        if (file == null) return mapOf()

        val contentType: String = file.contentType()
        val body: ByteArray = file.body()

        val base64Avatar = Base64.encodeToString(body, Base64.NO_WRAP)

        return mapOf(
            "contentType" to contentType,
            "avatarBase64" to base64Avatar
        )
    }
}
