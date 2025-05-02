package net.result.taulight.config

import android.os.Build
import androidx.annotation.RequiresApi
import net.result.sandnode.config.ClientConfig
import net.result.sandnode.encryption.SymmetricEncryptions
import net.result.sandnode.encryption.interfaces.AsymmetricKeyStorage
import net.result.sandnode.encryption.interfaces.SymmetricEncryption
import net.result.sandnode.util.Endpoint
import java.util.Optional

class AndroidClientConfig : ClientConfig {
    override fun symmetricKeyEncryption(): SymmetricEncryption = SymmetricEncryptions.AES
    override fun saveKey(endpoint: Endpoint, asymmetricKeyStorage: AsymmetricKeyStorage) {}

    @RequiresApi(Build.VERSION_CODES.N)
    override fun getPublicKey(endpoint: Endpoint): Optional<AsymmetricKeyStorage> = Optional.empty()
}
