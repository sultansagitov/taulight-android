package net.result.taulight

import net.result.sandnode.chain.sender.LoginClientChain
import net.result.sandnode.chain.sender.RegistrationClientChain
import net.result.sandnode.dto.RegistrationResponseDTO
import net.result.sandnode.encryption.AsymmetricEncryptions
import net.result.sandnode.hubagent.Agent
import net.result.sandnode.serverclient.SandnodeClient

fun register(client: SandnodeClient, nickname: String, password: String, device: String)
        : RegistrationResponseDTO {
    val agent = client.node as Agent

    val chain = RegistrationClientChain(client)
    client.io.chainManager.linkChain(chain)
    val keyStorage = AsymmetricEncryptions.ECIES.generate()
    val response = chain.register(nickname, password, device, keyStorage)
    client.io.chainManager.removeChain(chain)
    agent.config.savePersonalKey(response.keyID, keyStorage)
    return response
}

fun login(client: SandnodeClient, token: String): String {
    val chain = LoginClientChain(client)
    client.io.chainManager.linkChain(chain)
    val response = chain.login(token)
    client.io.chainManager.removeChain(chain)
    return response.nickname
}