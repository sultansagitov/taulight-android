package net.result.taulight

import net.result.sandnode.config.AgentConfig
import net.result.sandnode.encryption.KeyStorageRegistry
import net.result.taulight.hubagent.TauAgent
import java.util.*

class AndroidAgent(val taulight: Taulight, val uuid: UUID, config: AgentConfig)
    : TauAgent(KeyStorageRegistry(), config) {

    override fun close() {
        taulight.sendToFlutter("disconnect", mapOf("uuid" to uuid.toString()))
    }
}
