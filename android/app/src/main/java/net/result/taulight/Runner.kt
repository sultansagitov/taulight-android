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

class Runner(val taulight: Taulight) {

    @Throws(Exception::class)
    fun connect(clientID: UUID, link: SandnodeLinkRecord): Map<String, String> {
        taulight.addClient(clientID, link)
        return mapOf("endpoint" to link.endpoint().toString(52525))
    }

    @Throws(Exception::class)
    fun members(client: SandnodeClient, chatID: UUID): Any {
        val chain = MembersClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val members = chain.getMembers(chatID)
        client.io.chainManager.removeChain(chain)

        return taulight.objectMapper.convertValue(members, List::class.java)
    }

    @Throws(Exception::class)
    fun login(client: SandnodeClient, nickname: String, password: String): Map<String, String> {
        val chain = LogPasswdClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val token = chain.getToken(nickname, password)
        client.io.chainManager.removeChain(chain)

        return mapOf("token" to token)
    }

    @Throws(Exception::class)
    fun register(client: SandnodeClient, nickname: String, password: String): Map<String, String> {
        val chain = RegistrationClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val token = chain.getTokenFromRegistration(nickname, password)
        client.io.chainManager.removeChain(chain)

        return mapOf("token" to token)
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
        chain.getMessages(chatID, index, size)
        client.io.chainManager.removeChain(chain)
        val messages = chain.getMessages()
        return mapOf(
            "count" to chain.getCount(),
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
    fun createChannel(client: SandnodeClient, title: String): Map<String, String> {
        val chain = ChannelClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val chatID = chain.sendNewChannelRequest(title)
        client.io.chainManager.removeChain(chain)
        return mapOf("chat-id" to chatID.toString())
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
    fun token(client: SandnodeClient, token: String): Map<String, String> {
        val chain = LoginClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val nickname = chain.getNickname(token)
        client.io.chainManager.removeChain(chain)
        return mapOf("nickname" to nickname)
    }

    @Throws(Exception::class)
    fun checkCode(client: SandnodeClient, code: String): Any {
        val chain = CheckCodeClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val c = chain.check(code)
        client.io.chainManager.removeChain(chain)
        return taulight.objectMapper.convertValue(c, Map::class.java)
    }

    @Throws(Exception::class)
    fun useCode(client: SandnodeClient, code: String): String {
        val chain = UseCodeClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        chain.use(code)
        client.io.chainManager.removeChain(chain)
        return "success"
    }

    @Throws(Exception::class)
    fun dialog(client: SandnodeClient, nickname: String): Map<String, String> {
        val chain = DialogClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val chatID = chain.getDialogID(nickname)
        client.io.chainManager.removeChain(chain)
        return mapOf("chat-id" to chatID.toString())
    }

    @Throws(Exception::class)
    fun leave(client: SandnodeClient, chatID: UUID): String {
        val chain = ChannelClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        chain.sendLeaveRequest(chatID)
        client.io.chainManager.removeChain(chain)
        return "success"
    }

    @Throws(Exception::class)
    fun channelCodes(client: SandnodeClient, chatID: UUID): List<*> {
        val chain = ChannelClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val codes = chain.getChannelCodes(chatID)
        client.io.chainManager.removeChain(chain)
        return taulight.objectMapper.convertValue(codes, List::class.java)
    }

    @Throws(Exception::class)
    fun react(client: SandnodeClient, msgID: UUID, reactionType: String): String {
        val chain = ReactionRequestClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        chain.react(msgID, reactionType)
        println("Added reaction '$reactionType' to message $msgID")
        client.io.chainManager.removeChain(chain)
        return "success"
    }

    @Throws(Exception::class)
    fun unreact(client: SandnodeClient, msgID: UUID, reactionType: String): String {
        val chain = ReactionRequestClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        chain.unreact(msgID, reactionType)
        println("Removed reaction '$reactionType' from message $msgID")
        client.io.chainManager.removeChain(chain)
        return "success"
    }
}
