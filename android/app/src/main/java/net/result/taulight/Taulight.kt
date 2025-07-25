package net.result.taulight

import android.os.Handler
import android.os.Looper
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.SerializationFeature
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule
import io.flutter.plugin.common.MethodChannel
import net.result.sandnode.hubagent.AgentProtocol
import net.result.sandnode.hubagent.ClientProtocol
import net.result.sandnode.link.SandnodeLinkRecord
import net.result.sandnode.serverclient.SandnodeClient
import net.result.taulight.chain.AndroidClientChainManager
import net.result.taulight.config.AndroidAgentConfig
import net.result.taulight.config.AndroidClientConfig
import net.result.taulight.exception.ClientNotFoundException
import org.apache.logging.log4j.LogManager
import java.util.*
import java.util.concurrent.CountDownLatch

class Taulight(val methodChannel: MethodChannel) {
    companion object {
        val LOGGER = LogManager.getLogger(Taulight::class.java)!!
    }

    val clients: MutableMap<UUID, MemberClient> = mutableMapOf()
    val objectMapper: ObjectMapper = ObjectMapper()
        .registerModule(JavaTimeModule())
        .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)

    private val handler: Handler = Handler(Looper.getMainLooper())

    fun sendToFlutter(method: String, obj: Map<String, Any>) = handler.post { methodChannel.invokeMethod(method, obj) }

    fun callFromFlutter(method: String, obj: Map<String, Any>): Map<String, String> {
        val latch = CountDownLatch(1)
        var resultMap: Map<String, String>? = null

        handler.post {
            methodChannel.invokeMethod(method, obj, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    LOGGER.debug("Result from flutter: {}", result.toString())
                    resultMap = (result as? Map<*, *>)?.mapNotNull {
                        val key = it.key as? String
                        val value = it.value as? String
                        if (key != null && value != null) key to value else null
                    }?.toMap() ?: emptyMap()
                    latch.countDown()
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    LOGGER.error(errorCode)
                    LOGGER.error(errorMessage ?: "null")
                    LOGGER.error(errorDetails?.toString() ?: "null")
                    latch.countDown()
                }

                override fun notImplemented() {
                    LOGGER.error("notImplemented")
                    latch.countDown()
                }
            })
        }

        latch.await()
        return resultMap ?: throw RuntimeException(obj.toString())
    }


    fun addClient(uuid: UUID, link: SandnodeLinkRecord) {
        val agentConfig = AndroidAgentConfig(this)
        val agent = AndroidAgent(this, uuid, agentConfig)

        val clientConfig = AndroidClientConfig()
        val client = SandnodeClient.fromLink(link, agent, clientConfig)

        LOGGER.info("Saving client of {} with uuid {}", client.address, uuid)
        val mc = MemberClient(uuid, client, link)

        client.start(AndroidClientChainManager(mc, this))

        val serverKey = AgentProtocol.loadOrFetchServerKey(client, link)
        client.io().setServerKey(serverKey)
        ClientProtocol.sendSYM(client)

        clients[uuid] = mc
    }

    fun getClient(uuid: String): MemberClient = getClient(UUID.fromString(uuid))

    fun getClient(uuid: UUID): MemberClient {
        return clients[uuid] ?: throw ClientNotFoundException(uuid)
    }
}
