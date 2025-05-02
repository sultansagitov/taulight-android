package net.result.taulight

import android.os.Handler
import android.os.Looper

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.SerializationFeature
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule

import net.result.sandnode.exception.InvalidSandnodeLinkException
import net.result.sandnode.exception.UnprocessedMessagesException
import net.result.sandnode.exception.crypto.CreatingKeyException
import net.result.sandnode.exception.crypto.KeyNotCreatedException
import net.result.sandnode.link.Links
import net.result.sandnode.link.SandnodeLinkRecord
import net.result.taulight.chain.AndroidClientChainManager
import net.result.taulight.config.AndroidClientConfig
import net.result.sandnode.config.ClientConfig
import net.result.sandnode.encryption.interfaces.AsymmetricKeyStorage
import net.result.sandnode.hubagent.Agent
import net.result.sandnode.hubagent.ClientProtocol
import net.result.sandnode.exception.ConnectionException
import net.result.sandnode.exception.InputStreamException
import net.result.sandnode.exception.OutputStreamException
import net.result.sandnode.serverclient.SandnodeClient
import net.result.sandnode.exception.ExpectedMessageException
import net.result.sandnode.encryption.KeyStorageRegistry
import net.result.taulight.exception.ClientNotFoundException

import org.apache.logging.log4j.LogManager
import org.apache.logging.log4j.Logger

import java.util.UUID

import io.flutter.plugin.common.MethodChannel

class Taulight(val methodChannel: MethodChannel) {
    companion object {
        private val LOGGER: Logger = LogManager.getLogger(Taulight::class.java)
    }

    val clients: MutableMap<UUID, MemberClient> = mutableMapOf()
    val objectMapper: ObjectMapper = ObjectMapper()
        .registerModule(JavaTimeModule())
        .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)

    private val handler: Handler = Handler(Looper.getMainLooper())

    fun sendToFlutter(method: String, obj: Map<String, Any>) =
        handler.post({ methodChannel.invokeMethod(method, obj) })

    fun addClient(uuid: UUID, link: SandnodeLinkRecord) {
        val keyStorageRegistry: KeyStorageRegistry = KeyStorageRegistry()
        val agent: Agent = AndroidAgent(keyStorageRegistry, this, uuid)

        val clientConfig: ClientConfig = AndroidClientConfig()
        val client: SandnodeClient = SandnodeClient.fromLink(link, agent, clientConfig)
        client.start(AndroidClientChainManager(uuid, this))

        val keyStorage: AsymmetricKeyStorage = link.keyStorage()
        client.io.setServerKey(keyStorage)
        ClientProtocol.sendSYM(client)

        LOGGER.debug("Saving client of {} with uuid {}", client.endpoint, uuid)
        clients[uuid] = MemberClient(client, link)
    }

    fun getClient(uuid: String): MemberClient = getClient(UUID.fromString(uuid))

    fun getClient(uuid: UUID): MemberClient {
        return clients[uuid] ?: throw ClientNotFoundException(uuid)
    }
}
