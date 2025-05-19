package net.result.taulight

import android.os.Build
import androidx.annotation.RequiresApi
import net.result.sandnode.chain.sender.WhoAmIClientChain
import net.result.sandnode.dto.FileDTO
import net.result.sandnode.dto.PaginatedDTO
import net.result.sandnode.hubagent.ClientProtocol
import net.result.sandnode.link.SandnodeLinkRecord
import net.result.sandnode.serverclient.SandnodeClient
import net.result.sandnode.util.Endpoint
import net.result.sandnode.util.IOController
import net.result.taulight.chain.client.AndroidForwardRequestChain
import net.result.taulight.chain.sender.ChannelClientChain
import net.result.taulight.chain.sender.ChatClientChain
import net.result.taulight.chain.sender.DialogClientChain
import net.result.taulight.chain.sender.MessageClientChain
import net.result.taulight.dto.ChatInfoDTO
import net.result.taulight.dto.ChatInfoPropDTO
import net.result.taulight.dto.ChatMessageInputDTO
import net.result.taulight.dto.ChatMessageViewDTO
import net.result.taulight.exception.ClientNotFoundException
import java.time.Duration
import java.util.*

class Runner(val taulight: Taulight) {

    @Throws(Exception::class)
    fun connect(clientID: UUID, link: SandnodeLinkRecord): Endpoint {
        taulight.addClient(clientID, link)
        return link.endpoint()
    }

    @Throws(ClientNotFoundException::class)
    fun disconnect(uuid: String): String {
        val client = taulight.getClient(uuid).client
        client.close()
        return "disconnected"
    }

    @RequiresApi(Build.VERSION_CODES.N)
    @Throws(Exception::class)
    fun send(io: IOController, chatID: String, content: String, replies: Set<UUID>): UUID {
        val opt = io.chainManager.getChain("fwd_req")
        val androidChain = if (opt.isPresent) {
            opt.get() as AndroidForwardRequestChain
        } else {
            AndroidForwardRequestChain(io).also {
                io.chainManager.setName(it, "fwd_req")
                io.chainManager.linkChain(it)
            }
        }

        val message = ChatMessageInputDTO()
            .setChatID(UUID.fromString(chatID))
            .setContent(content)
            .setRepliedToMessages(replies)
            .setSentDatetimeNow()

        return androidChain.message(message)
    }

    @Throws(Exception::class)
    fun groupAdd(client: SandnodeClient, group: String): String {
        ClientProtocol.addToGroups(client.io, setOf(group))
        return "sent"
    }

    @Throws(Exception::class)
    fun getChats(client: SandnodeClient): Collection<ChatInfoDTO> {
        val chain = ChatClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val infos = chain.getByMember(ChatInfoPropDTO.all())
        client.io.chainManager.removeChain(chain)
        return infos
    }

    @Throws(Exception::class)
    fun loadMessages(client: SandnodeClient, chatID: UUID, index: Int, size: Int): PaginatedDTO<ChatMessageViewDTO> {
        val chain = MessageClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val paginated = chain.getMessages(chatID, index, size)
        client.io.chainManager.removeChain(chain)
        return paginated;
    }

    fun loadClients(): Map<UUID, MemberClient> {
        return taulight.clients
    }

    @Throws(Exception::class)
    fun loadChat(client: SandnodeClient, chatID: UUID): ChatInfoDTO {
        val chain = ChatClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val optChats = chain.getByID(listOf(chatID), ChatInfoPropDTO.all())
        client.io.chainManager.removeChain(chain)
        return optChats.first()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    @Throws(Exception::class)
    fun addMember(client: SandnodeClient, chatID: UUID, otherNickname: String): String {
        val chain = ChannelClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val code = chain.createInviteCode(chatID, otherNickname, Duration.ofDays(1))
        client.io.chainManager.removeChain(chain)
        return code;
    }

    @Throws(Exception::class)
    fun getChannelAvatar(client: SandnodeClient, chatID: UUID): FileDTO? {
        val chain = ChannelClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val file = chain.getAvatar(chatID)
        client.io.chainManager.removeChain(chain)
        return file;
    }

    @Throws(Exception::class)
    fun getDialogAvatar(client: SandnodeClient, chatID: UUID): FileDTO? {
        val chain = DialogClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        val file = chain.getAvatar(chatID)
        client.io.chainManager.removeChain(chain)
        return file;
    }

    fun getAvatar(client: SandnodeClient): FileDTO? {
        val chain = WhoAmIClientChain(client.io)
        client.io.chainManager.linkChain(chain)

        val avatar = chain.avatar
        client.io.chainManager.removeChain(chain)

        return avatar;
    }

    fun setAvatar(client: SandnodeClient, path: String) {
        val chain = WhoAmIClientChain(client.io)
        client.io.chainManager.linkChain(chain)
        chain.setAvatar(path)
        client.io.chainManager.removeChain(chain)
    }
}
