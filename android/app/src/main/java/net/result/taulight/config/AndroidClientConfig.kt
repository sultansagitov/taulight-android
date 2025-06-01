package net.result.taulight.config

import net.result.sandnode.config.ClientConfig
import net.result.sandnode.encryption.SymmetricEncryptions
import net.result.sandnode.encryption.interfaces.SymmetricEncryption

class AndroidClientConfig : ClientConfig {

    override fun symmetricKeyEncryption(): SymmetricEncryption = SymmetricEncryptions.AES

}
