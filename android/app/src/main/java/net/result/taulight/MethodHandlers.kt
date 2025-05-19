package net.result.taulight

import android.os.Build
import android.util.Base64
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import net.result.sandnode.chain.IChain
import net.result.sandnode.chain.sender.WhoAmIClientChain
import net.result.sandnode.exception.ExpectedMessageException
import net.result.sandnode.exception.FSException
import net.result.sandnode.exception.UnknownSandnodeErrorException
import net.result.sandnode.exception.UnprocessedMessagesException
import net.result.sandnode.exception.error.SandnodeErrorException
import net.result.sandnode.link.Links
import net.result.sandnode.serverclient.SandnodeClient
import net.result.sandnode.util.IOController
import net.result.taulight.exception.ClientNotFoundException
import org.apache.logging.log4j.LogManager
import org.apache.logging.log4j.Logger
import java.lang.reflect.InvocationTargetException
import java.util.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MethodHandlers(flutterEngine: FlutterEngine) {
    companion object {
        private val LOGGER: Logger = LogManager.getLogger(MethodHandlers::class.java)
        private val uuidRegex = Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$")
    }

    private val methodHandlerMap: Map<String, (MethodCall) -> Any?>
    private val taulight: Taulight

    private val executorService: ExecutorService = Executors.newCachedThreadPool()

    private val runner: Runner

    init {
        val binaryMessenger: BinaryMessenger = flutterEngine.dartExecutor.binaryMessenger
        val CHANNEL = "net.result.taulight/messenger"

        val methodChannel = MethodChannel(binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler(this::onMethodCallHandler)

        taulight = Taulight(methodChannel)

        runner = Runner(taulight)

        methodHandlerMap = mapOf(
            "connect" to this::connect,
            "disconnect" to this::disconnect,
            "send" to this::send,
            "group" to this::groupAdd,
            "get-chats" to this::getChats,
            "load-messages" to this::loadMessages,
            "load-clients" to this::loadClients,
            "load-chat" to this::loadChat,
            "add-member" to this::addMember,
            "get-channel-avatar" to this::getChannelAvatar,
            "get-dialog-avatar" to this::getDialogAvatar,
            "get-avatar" to this::getAvatar,
            "set-avatar" to this::setAvatar,
            "chain" to this::chain,
        )
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun onMethodCallHandler(call: MethodCall, result: MethodChannel.Result) {
        executorService.execute {
            val handler = methodHandlerMap[call.method]
            if (handler != null) {
                taulight.clients.entries.removeIf{ (_, mc) -> !mc.client.io.isConnected }

                try {
                    val res: Any? = handler(call)
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
        val uuid = call.argument<String>("uuid")!!
        val clientID = UUID.fromString(uuid)

        val linkString = call.argument<String>("link")!!
        val link = Links.parse(linkString)

        val endpoint = runner.connect(clientID, link)

        return mapOf("endpoint" to endpoint.toString(52525))
    }

    @Throws(ClientNotFoundException::class)
    private fun disconnect(call: MethodCall): String {
        val uuid: String = call.argument<String>("uuid")!!
        return runner.disconnect(uuid)
    }

    @RequiresApi(Build.VERSION_CODES.N)
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

        return runner.send(io, chatID, content, replies).toString()
    }

    @Throws(Exception::class)
    private fun groupAdd(call: MethodCall): String {
        val uuid: String = call.argument<String>("uuid")!!
        val group: String = call.argument<String>("group")!!

        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.groupAdd(client, group)
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    @Throws(Exception::class)
    private fun getChats(call: MethodCall): List<*> {
        val uuid: String = call.argument<String>("uuid")!!
        val client: SandnodeClient = taulight.getClient(uuid).client

        val chats = runner.getChats(client)

        return taulight.objectMapper.convertValue(chats, List::class.java)
    }

    @Throws(Exception::class)
    private fun loadMessages(call: MethodCall): Map<String, Any> {
        val uuid: String = call.argument<String>("uuid")!!
        val chatIDStr: String = call.argument<String>("chat-id")!!
        val index: Int = call.argument<Int>("index")!!
        val size: Int = call.argument<Int>("size")!!

        val client: SandnodeClient = taulight.getClient(uuid).client
        val chatID: UUID = UUID.fromString(chatIDStr)

        val paginated = runner.loadMessages(client, chatID, index, size)

        val messages = paginated.objects
        return mapOf(
            "count" to paginated.totalCount,
            "messages" to taulight.objectMapper.convertValue(messages, List::class.java)
        )
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun loadClients(ignoredCall: MethodCall): List<Map<String, String>?> {
        return runner.loadClients().entries.map { (clientID, mc) ->
            mapOf(
                "uuid" to clientID.toString(),
                "endpoint" to mc.client.endpoint.toString(),
                "link" to mc.link.toString()
            )
        }
    }

    @RequiresApi(Build.VERSION_CODES.N)
    @Throws(Exception::class)
    private fun loadChat(call: MethodCall): Any {
        val uuid: String = call.argument<String>("uuid")!!
        val chatString: String = call.argument<String>("chat-id")!!

        val chatID: UUID = UUID.fromString(chatString)
        val client: SandnodeClient = taulight.getClient(uuid).client

        val chat = runner.loadChat(client, chatID)
        return taulight.objectMapper.convertValue(chat, Map::class.java)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    @Throws(Exception::class)
    private fun addMember(call: MethodCall): Map<String, String> {
        val uuid: String = call.argument<String>("uuid")!!
        val chatIDString: String = call.argument<String>("chat-id")!!
        val otherNickname: String = call.argument<String>("nickname")!!

        val chatID: UUID = UUID.fromString(chatIDString)

        val client: SandnodeClient = taulight.getClient(uuid).client

        val code = runner.addMember(client, chatID, otherNickname)
        return mapOf("code" to code)
    }

    private fun getChannelAvatar(call: MethodCall): Map<String, String> {
        val uuid: String = call.argument<String>("uuid")!!
        val chatIDString: String = call.argument<String>("chat-id")!!

        val chatID: UUID = UUID.fromString(chatIDString)

        val client: SandnodeClient = taulight.getClient(uuid).client

        val file = runner.getChannelAvatar(client, chatID)
        if (file == null) return mapOf()

        val contentType = file.contentType()
        val body = file.body()

        val base64Avatar = Base64.encodeToString(body, Base64.NO_WRAP)

        return mapOf(
            "contentType" to contentType,
            "avatarBase64" to base64Avatar
        )
    }

    private fun getDialogAvatar(call: MethodCall): Map<String, String> {
        val uuid: String = call.argument<String>("uuid")!!
        val chatIDString: String = call.argument<String>("chat-id")!!

        val chatID: UUID = UUID.fromString(chatIDString)

        val client: SandnodeClient = taulight.getClient(uuid).client

        val file = runner.getDialogAvatar(client, chatID)
        if (file == null) return mapOf()

        val contentType = file.contentType()
        val body = file.body()

        val base64Avatar = Base64.encodeToString(body, Base64.NO_WRAP)

        return mapOf(
            "contentType" to contentType,
            "avatarBase64" to base64Avatar
        )
    }

    @Throws(Exception::class)
    private fun chain(call: MethodCall): Any? {
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
        } catch (_: ClassNotFoundException) {
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
            return if (result == Unit) {
                null
            } else {
                taulight.objectMapper.convertValue(result, Any::class.java)
            }
        } catch (e: InvocationTargetException) {
            throw e.cause ?: e
        } finally {
            client.io.chainManager.removeChain(chain)
        }
    }

    @Throws(UnprocessedMessagesException::class, InterruptedException::class)
    private fun getAvatar(call: MethodCall): Map<String, String> {
        val uuid: String = call.argument<String>("uuid")!!
        val client = taulight.getClient(uuid).client

        try {
            val avatar = runner.getAvatar(client);

            if (avatar != null) {
                val mimeType = avatar.contentType()
                val base64 = Base64.encodeToString(avatar.body(), Base64.NO_WRAP)
                return mapOf("contentType" to mimeType, "avatarBase64" to base64)
            }
        } catch (e: Exception) {
            println("Exception: ${e.javaClass.simpleName}")
        }
        return mapOf()
    }

    @Throws(UnprocessedMessagesException::class, InterruptedException::class)
    private fun setAvatar(call: MethodCall): Boolean {
        val uuid: String = call.argument<String>("uuid")!!
        val path: String? = call.argument<String>("path")

        if (path.isNullOrEmpty()) {
            println("Usage: setAvatar <path>")
            return false
        }

        val client = taulight.getClient(uuid).client

         try {
             runner.setAvatar(client, path);

             return true
        } catch (e: Exception) {
            println("Exception: ${e.javaClass.simpleName}")
        }

        return false;
    }

}