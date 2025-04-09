package net.result.taulight.config;

import android.annotation.TargetApi;
import android.os.Build;

import java.util.Optional;

import net.result.sandnode.config.ClientConfig;
import net.result.sandnode.encryption.SymmetricEncryptions;
import net.result.sandnode.encryption.interfaces.AsymmetricKeyStorage;
import net.result.sandnode.encryption.interfaces.SymmetricEncryption;
import net.result.sandnode.util.Endpoint;

public class AndroidClientConfig implements ClientConfig {
    @Override
    public SymmetricEncryption symmetricKeyEncryption() {
        return SymmetricEncryptions.AES;
    }

    @Override
    public void saveKey(Endpoint endpoint, AsymmetricKeyStorage asymmetricKeyStorage) {}

    @TargetApi(Build.VERSION_CODES.N)
    @Override
    public Optional<AsymmetricKeyStorage> getPublicKey(Endpoint endpoint) {
        return Optional.empty();
    }
}
