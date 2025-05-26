package net.result.taulight.config

import android.os.Build
import android.util.Base64
import android.util.Log
import androidx.annotation.RequiresApi
import net.result.sandnode.config.ClientConfig
import net.result.sandnode.config.KeyEntry
import net.result.sandnode.encryption.EncryptionManager
import net.result.sandnode.encryption.SymmetricEncryptions
import net.result.sandnode.encryption.interfaces.AsymmetricKeyStorage
import net.result.sandnode.encryption.interfaces.KeyStorage
import net.result.sandnode.encryption.interfaces.SymmetricEncryption
import net.result.sandnode.exception.error.KeyStorageNotFoundException
import net.result.sandnode.util.Endpoint
import net.result.taulight.Taulight
import java.util.UUID
import kotlin.collections.set

class AndroidClientConfig(val taulight: Taulight, val uuid: UUID) : ClientConfig {

    override fun symmetricKeyEncryption(): SymmetricEncryption = SymmetricEncryptions.AES

    override fun saveKey(endpoint: Endpoint, keyStorage: AsymmetricKeyStorage) {
        taulight.sendToFlutter("save-key", mapOf(
            "uuid" to uuid.toString(),
            "endpoint" to endpoint.toString(),
            "encryption" to keyStorage.encryption().name(),
            "public-key" to keyStorage.encodedPublicKey(),
            "private-key" to keyStorage.encodedPrivateKey()
        ))
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun getPublicKey(endpoint: Endpoint): AsymmetricKeyStorage {
        val result = taulight
            .callFromFlutter("get-public-key", mapOf(
                "uuid" to uuid.toString(),
                "endpoint" to endpoint.toString()
            ))
            ?: throw KeyStorageNotFoundException(endpoint.toString())

        val publicKey = result["public-key"]!!
        val privateKey = result["private-key"]!!
        val encryptionString = result["encryption"]!!

        val encryption = EncryptionManager.find(encryptionString).asymmetric()

        val pub = encryption.publicKeyConvertor().toKeyStorage(publicKey)
        val pri = encryption.privateKeyConvertor().toKeyStorage(privateKey)
        val keyStorage = encryption.merge(pub, pri)
        return keyStorage
    }

    override fun savePersonalKey(keyID: UUID, keyStorage: KeyStorage) {
        val data = mutableMapOf(
            "uuid" to uuid.toString(),
            "key-id" to keyID.toString(),
            "encryption" to keyStorage.encryption().name()
        )

        if (keyStorage.encryption().isSymmetric) {
            data["sym-key"] = keyStorage.symmetric().encoded()
        }

        if (keyStorage.encryption().isAsymmetric) {
            data["public-key"] = keyStorage.asymmetric().encodedPublicKey()
            data["private-key"] = keyStorage.asymmetric().encodedPrivateKey()
        }

        taulight.sendToFlutter("save-personal-key", data)
    }

    override fun saveEncryptor(nickname: String, keyID: UUID, keyStorage: KeyStorage) {
        val data = mutableMapOf(
            "uuid" to uuid.toString(),
            "nickname" to nickname,
            "key-id" to keyID.toString(),
            "encryption" to keyStorage.encryption().name()
        )

        if (keyStorage.encryption().isSymmetric) {
            data["sym-key"] = keyStorage.symmetric().encoded()
        }

        if (keyStorage.encryption().isAsymmetric) {
            data["public-key"] = keyStorage.asymmetric().encodedPublicKey()
            data["private-key"] = keyStorage.asymmetric().encodedPrivateKey()
        }

        taulight.sendToFlutter("save-encryptor", data)
    }

    override fun saveDEK(nickname: String, keyID: UUID, keyStorage: KeyStorage) {
        val data = mutableMapOf(
            "uuid" to uuid.toString(),
            "nickname" to nickname,
            "key-id" to keyID.toString(),
            "encryption" to keyStorage.encryption().name()
        )

        if (keyStorage.encryption().isSymmetric) {
            data["sym-key"] = keyStorage.symmetric().encoded()
        }

        if (keyStorage.encryption().isAsymmetric) {
            data["public-key"] = keyStorage.asymmetric().encodedPublicKey()
            data["private-key"] = keyStorage.asymmetric().encodedPrivateKey()
        }

        taulight.sendToFlutter("save-dek", data)
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun loadPersonalKey(keyID: UUID): KeyStorage {
        val result = taulight
            .callFromFlutter("load-personal-key", mapOf(
                "uuid" to uuid.toString(),
                "key-id" to keyID.toString()
            ))
            ?: throw KeyStorageNotFoundException(keyID)

        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage: KeyStorage
        if (encryption.isAsymmetric) {
            val pub = encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public-key"]!!)
            val pri = encryption.asymmetric().privateKeyConvertor().toKeyStorage(result["private-key"]!!)
            keyStorage = encryption.asymmetric().merge(pub, pri)
        } else {
            keyStorage = encryption.symmetric().toKeyStorage(Base64.decode(result["sym-key"]!!, Base64.DEFAULT))
        }

        return keyStorage
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun loadEncryptor(nickname: String): KeyEntry {
        val result = taulight
            .callFromFlutter("load-encryptor", mapOf(
                "uuid" to uuid.toString(),
                "nickname" to nickname
            ))
            ?: throw KeyStorageNotFoundException(nickname)

        val keyID = result["key-id"]
        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage: KeyStorage
        if (encryption.isAsymmetric) {
            val pub = encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public-key"]!!)
            val pri = encryption.asymmetric().privateKeyConvertor().toKeyStorage(result["private-key"]!!)
            keyStorage = encryption.asymmetric().merge(pub, pri)
        } else {
            keyStorage = encryption.symmetric().toKeyStorage(Base64.decode(result["sym-key"]!!, Base64.DEFAULT))
        }

        return KeyEntry(UUID.fromString(keyID), keyStorage)
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun loadDEK(nickname: String): KeyEntry {
        val result = taulight
            .callFromFlutter("load-dek", mapOf(
                "uuid" to uuid.toString(),
                "nickname" to nickname
            ))
            ?: throw KeyStorageNotFoundException(nickname)

        val keyID = result["key-id"]
        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage: KeyStorage
        if (encryption.isAsymmetric) {
            val pub = encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public-key"]!!)
            val pri = encryption.asymmetric().privateKeyConvertor().toKeyStorage(result["private-key"]!!)
            keyStorage = encryption.asymmetric().merge(pub, pri)
        } else {
            keyStorage = encryption.symmetric().toKeyStorage(Base64.decode(result["sym-key"]!!, Base64.DEFAULT))
        }

        return KeyEntry(UUID.fromString(keyID), keyStorage)
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun loadDEK(keyID: UUID): KeyStorage {
        val result = taulight
            .callFromFlutter("load-dek-by-id", mapOf(
                "uuid" to uuid.toString(),
                "key-id" to keyID.toString()
            ))
            ?: throw KeyStorageNotFoundException(keyID)

        Log.d(javaClass.simpleName, "${result.size}")
        for (entry in result.entries) Log.d(javaClass.simpleName, "${entry.key} ${entry.value}")

        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage: KeyStorage
        if (encryption.isAsymmetric) {
            val pub = encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public-key"]!!)
            val pri = encryption.asymmetric().privateKeyConvertor().toKeyStorage(result["private-key"]!!)
            keyStorage = encryption.asymmetric().merge(pub, pri)
        } else {
            keyStorage = encryption.symmetric().toKeyStorage(Base64.decode(result["sym-key"]!!, Base64.DEFAULT))
        }

        return keyStorage
    }
}
