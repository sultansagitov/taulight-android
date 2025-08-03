package net.result.taulight

import android.util.Base64
import net.result.sandnode.chain.sender.LoginClientChain
import net.result.sandnode.chain.sender.RegistrationClientChain
import net.result.sandnode.dto.RegistrationResponseDTO
import net.result.sandnode.encryption.AsymmetricEncryptions
import net.result.sandnode.serverclient.SandnodeClient

fun register(client: SandnodeClient, nickname: String, password: String, device: String): RegistrationResponseDTO {
    val agent = client.node().agent()
    val keyStorage = AsymmetricEncryptions.ECIES.generate()

    val chain = RegistrationClientChain(client)
    client.io().chainManager.linkChain(chain)
    val response = chain.register(nickname, password, device, keyStorage)
    client.io().chainManager.removeChain(chain)
    agent.config.savePersonalKey(client.address, nickname, keyStorage)
    return response
}

fun loginHistory(client: SandnodeClient): List<Map<String, Any>> {
    val chain = LoginClientChain(client)
    client.io().chainManager.linkChain(chain)
    val response = chain.history
    client.io().chainManager.removeChain(chain)

    val agent = client.node().agent()

    return response.map {
        val personalKey = agent.config.loadPersonalKey(client.address, client.nickname)

        mapOf(
            "time" to it.time.toString(),
            "ip" to personalKey.encryption().decrypt(Base64.decode(it.ip, Base64.NO_WRAP), personalKey),
            "device" to personalKey.encryption().decrypt(Base64.decode(it.device, Base64.NO_WRAP), personalKey),
            "online" to it.isOnline
        )
    }.toList()
}
