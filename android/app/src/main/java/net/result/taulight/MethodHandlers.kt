package net.result.taulight

import android.annotation.TargetApi
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import net.result.sandnode.chain.IChain
import net.result.sandnode.exception.error.SandnodeErrorException
import net.result.sandnode.link.Links
import net.result.sandnode.link.SandnodeLinkRecord
import net.result.sandnode.serverclient.SandnodeClient
import net.result.sandnode.util.IOController
import net.result.taulight.exception.ClientNotFoundException
import org.apache.logging.log4j.LogManager
import org.apache.logging.log4j.Logger
import java.lang.Class
import java.lang.ClassNotFoundException
import java.lang.Exception
import java.util.UUID
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MethodHandlers(flutterEngine: FlutterEngine) {
    companion object {
        private val LOGGER: Logger = LogManager.getLogger(MethodHandlers::class.java)
        private val uuidRegex = Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$")
    }

    private val methodHandlerMap: Map<String, (MethodCall) -> Any>
    private val taulight: Taulight

    private val executorService: ExecutorService

    private val runner: Runner

    init {
        executorService = Executors.newCachedThreadPool()

        val binaryMessenger: BinaryMessenger = flutterEngine.getDartExecutor().getBinaryMessenger()
        val CHANNEL: String = "net.result.taulight/messenger"

        val methodChannel: MethodChannel = MethodChannel(binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler(this::onMethodCallHandler)

        taulight = Taulight(methodChannel)

        runner = Runner(taulight)

        methodHandlerMap = HashMap<String, (MethodCall) -> Any>()
        methodHandlerMap.put("connect", this::connect)
        methodHandlerMap.put("disconnect", this::disconnect)
        methodHandlerMap.put("send", this::send)
        methodHandlerMap.put("group", this::groupAdd)
        methodHandlerMap.put("get-chats", this::getChats)
        methodHandlerMap.put("load-messages", this::loadMessages)
        methodHandlerMap.put("load-clients", this::loadClient)
        methodHandlerMap.put("load-chat", this::loadChat)
        methodHandlerMap.put("add-member", this::addMember)
        methodHandlerMap.put("get-channel-avatar", this::getChannelAvatar)
        methodHandlerMap.put("chain", this::chain)
    }

    @TargetApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun onMethodCallHandler(call: MethodCall, result: MethodChannel.Result) {
        executorService.execute {
            val handler = methodHandlerMap.get(call.method)
            if (handler != null) {
                taulight.clients.entries.removeIf{ (_, mc) -> !mc.client.io.isConnected() }

                try {
                    val res: Any = handler(call)
                    result.success(mapOf("success" to res))
                } catch (e: SandnodeErrorException) {
                    result.success(mapOf(
                        "error" to mapOf(
                            "name" to e.javaClass.getSimpleName(),
                            "message" to e.message
                        )
                    ))
                } catch (e: Exception) {
                    LOGGER.error("Unhandled", e)
                    result.success(mapOf(
                        "error" to mapOf(
                            "name" to e.javaClass.getSimpleName(),
                            "message" to e.message
                        )
                    ))
                }
            } else result.error("UNAVAILABLE", "Unknown method type", call.method)
        }
    }

    @Throws(Exception::class)
    private fun connect(call: MethodCall): Map<String, String> {
        val uuid: String = call.argument<String>("uuid")!!
        val linkString: String = call.argument<String>("link")!!

        val link: SandnodeLinkRecord = Links.parse(linkString)

        val clientID: UUID = UUID.fromString(uuid)

        return runner.connect(clientID, link)
    }

    @Throws(ClientNotFoundException::class)
    private fun disconnect(call: MethodCall): String {
        val uuid: String = call.argument<String>("uuid")!!
        return runner.disconnect(uuid)
    }

    @TargetApi(Build.VERSION_CODES.N)
    @Throws(Exception::class)
    private fun send(call: MethodCall): String {
        val uuid: String = call.argument<String>("uuid")!!
        val chatID: String = call.argument<String>("chat-id")!!
        val content: String = call.argument<String>("content")!!
        val repliedToMessagesString: List<String> =
            call.argument<List<String>>("repliedToMessages")!!

        val replies: Set<UUID> = repliedToMessagesString.map { UUID.fromString(it) }.toSet()

        val mc: MemberClient = taulight.getClient(uuid)
        val io: IOController = mc.client.io

        return runner.send(io, chatID, content, replies)
    }

    @Throws(Exception::class)
    private fun groupAdd(call: MethodCall): String {
        val uuid: String = call.argument<String>("uuid")!!
        val group: String = call.argument<String>("group")!!

        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.groupAdd(client, group)
    }

    /** @noinspection rawtypes*/
    @TargetApi(Build.VERSION_CODES.TIRAMISU)
    @Throws(Exception::class)
    private fun getChats(call: MethodCall): List<*> {
        val uuid: String = call.argument<String>("uuid")!!
        val client: SandnodeClient = taulight.getClient(uuid).client
        return runner.getChats(client)
    }

    @Throws(Exception::class)
    private fun loadMessages(call: MethodCall): Map<String, Any> {
        val uuid: String = call.argument<String>("uuid")!!
        val chatID_str: String = call.argument<String>("chat-id")!!
        val index: Int = call.argument<Int>("index")!!
        val size: Int = call.argument<Int>("size")!!

        val client: SandnodeClient = taulight.getClient(uuid).client
        val chatID: UUID = UUID.fromString(chatID_str)

        return runner.loadMessages(client, chatID, index, size)
    }

    @TargetApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun loadClient(ignoredCall: MethodCall): List<Map<String, String>?> {
        return runner.loadClient()
    }

    @TargetApi(Build.VERSION_CODES.N)
    @Throws(Exception::class)
    private fun loadChat(call: MethodCall): Any {
        val uuid: String = call.argument<String>("uuid")!!
        val chat: String = call.argument<String>("chat-id")!!

        val chatID: UUID = UUID.fromString(chat)
        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.loadChat(client, chatID)
    }

    @TargetApi(Build.VERSION_CODES.O)
    @Throws(Exception::class)
    private fun addMember(call: MethodCall): Map<String, String> {
        val uuid: String = call.argument<String>("uuid")!!
        val chatIDString: String = call.argument<String>("chat-id")!!
        val otherNickname: String = call.argument<String>("nickname")!!

        val chatID: UUID = UUID.fromString(chatIDString)

        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.addMember(client, chatID, otherNickname)
    }

    private fun getChannelAvatar(call: MethodCall): Any {
        val uuid: String = call.argument<String>("uuid")!!
        val chatIDString: String = call.argument<String>("chat-id")!!

        val chatID: UUID = UUID.fromString(chatIDString)

        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.getChannelAvatar(client, chatID)
    }

    @Throws(Exception::class)
    private fun chain(call: MethodCall): Any {
        val uuid: String = call.argument<String>("uuid")!!
        val full: String = call.argument<String>("method")!!
        val params: List<Any> = call.argument<List<Any>>("params") ?: emptyList()

        val splitted = full.split(".")

        val className = splitted[0]
        val methodName = splitted[1]

        val client: SandnodeClient = taulight.getClient(uuid).client

        var clazz: Class<*>
        try {
            clazz = Class.forName("net.result.taulight.chain.sender.$className")
        } catch (e: ClassNotFoundException) {
            clazz = Class.forName("net.result.sandnode.chain.sender.$className")
        }
        val declaredConstructor = clazz.getDeclaredConstructor(IOController::class.java)
        val method = clazz.methods
            .firstOrNull { it.name == methodName && it.parameterTypes.size == params.size }
            ?: throw ClassNotFoundException()

        val chain: IChain? = declaredConstructor.newInstance(client.io) as IChain?

        client.io.chainManager.linkChain(chain)
        try {
            val processedParams = params.map { param ->
                if (param is String && uuidRegex.matches(param)) {
                    UUID.fromString(param)
                } else {
                    param
                }
            }

            val result = method.invoke(chain, *processedParams.toTypedArray())
            return taulight.objectMapper.convertValue(result, Any::class.java)
        } finally {
            client.io.chainManager.removeChain(chain)
        }
    }
}