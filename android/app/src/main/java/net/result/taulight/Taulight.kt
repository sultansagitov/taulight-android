package net.result.taulight

import android.os.Handler
import android.os.Looper
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.SerializationFeature
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule
import io.flutter.plugin.common.MethodChannel
import net.result.sandnode.encryption.KeyStorageRegistry
import net.result.sandnode.hubagent.ClientProtocol
import net.result.sandnode.link.SandnodeLinkRecord
import net.result.sandnode.serverclient.SandnodeClient
import net.result.taulight.chain.AndroidClientChainManager
import net.result.taulight.config.AndroidClientConfig
import net.result.taulight.exception.ClientNotFoundException
import org.apache.logging.log4j.LogManager
import org.apache.logging.log4j.Logger
import java.util.*

class Taulight(val methodChannel: MethodChannel) {
    companion object {
        private val LOGGER: Logger = LogManager.getLogger(Taulight::class.java)
    }

    val clients: MutableMap<UUID, MemberClient> = mutableMapOf()
    val objectMapper: ObjectMapper = ObjectMapper()
        .registerModule(JavaTimeModule())
        .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)

    private val handler: Handler = Handler(Looper.getMainLooper())

    fun sendToFlutter(method: String, obj: Map<String, Any>) = handler.post { methodChannel.invokeMethod(method, obj) }

    fun addClient(uuid: UUID, link: SandnodeLinkRecord) {
        val keyStorageRegistry = KeyStorageRegistry()
        val agent = AndroidAgent(keyStorageRegistry, this, uuid)

        val clientConfig = AndroidClientConfig()
        val client = SandnodeClient.fromLink(link, agent, clientConfig)
        client.start(AndroidClientChainManager(uuid, this))

        client.io.setServerKey(link.keyStorage())
        ClientProtocol.sendSYM(client)

        LOGGER.debug("Saving client of {} with uuid {}", client.endpoint, uuid)
        clients[uuid] = MemberClient(client, link)
    }

    fun getClient(uuid: String): MemberClient = getClient(UUID.fromString(uuid))

    fun getClient(uuid: UUID): MemberClient {
        return clients[uuid] ?: throw ClientNotFoundException(uuid)
    }
}
