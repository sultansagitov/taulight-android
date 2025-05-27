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

    private val publicKeyCache = mutableMapOf<Endpoint, AsymmetricKeyStorage>()
    private val personalKeyCache = mutableMapOf<UUID, KeyStorage>()
    private val encryptorCache = mutableMapOf<String, KeyEntry>()
    private val dekByNicknameCache = mutableMapOf<String, KeyEntry>()
    private val dekByIdCache = mutableMapOf<UUID, KeyStorage>()

    override fun symmetricKeyEncryption(): SymmetricEncryption = SymmetricEncryptions.AES

    override fun saveKey(endpoint: Endpoint, keyStorage: AsymmetricKeyStorage) {
        taulight.sendToFlutter("save-key", mapOf(
            "uuid" to uuid.toString(),
            "endpoint" to endpoint.toString(),
            "encryption" to keyStorage.encryption().name(),
            "public-key" to keyStorage.encodedPublicKey(),
        ))
        publicKeyCache[endpoint] = keyStorage
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun getPublicKey(endpoint: Endpoint): AsymmetricKeyStorage {
        publicKeyCache[endpoint]?.let { return it }

        val result = try {
            taulight.callFromFlutter("get-public-key", mapOf(
                "uuid" to uuid.toString(),
                "endpoint" to endpoint.toString()
            ))
        } catch (_: Exception) {
            throw KeyStorageNotFoundException(endpoint.toString())
        }

        val publicKey = result["public-key"]!!
        val encryptionString = result["encryption"]!!

        val encryption = EncryptionManager.find(encryptionString).asymmetric()
        val keyStorage = encryption.publicKeyConvertor().toKeyStorage(publicKey)

        publicKeyCache[endpoint] = keyStorage
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
        personalKeyCache[keyID] = keyStorage
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
        }

        taulight.sendToFlutter("save-encryptor", data)
        encryptorCache[nickname] = KeyEntry(keyID, keyStorage)
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
        dekByNicknameCache[nickname] = KeyEntry(keyID, keyStorage)
        dekByIdCache[keyID] = keyStorage
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun loadPersonalKey(keyID: UUID): KeyStorage {
        personalKeyCache[keyID]?.let { return it }

        val result = try {
            taulight.callFromFlutter("load-personal-key", mapOf(
                "uuid" to uuid.toString(),
                "key-id" to keyID.toString()
            ))
        } catch (_: Exception) {
            throw KeyStorageNotFoundException(keyID)
        }

        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage = if (encryption.isAsymmetric) {
            val pub = encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public-key"]!!)
            val pri = encryption.asymmetric().privateKeyConvertor().toKeyStorage(result["private-key"]!!)
            encryption.asymmetric().merge(pub, pri)
        } else {
            encryption.symmetric().toKeyStorage(Base64.decode(result["sym-key"]!!, Base64.NO_WRAP))
        }

        personalKeyCache[keyID] = keyStorage
        return keyStorage
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun loadEncryptor(nickname: String): KeyEntry {
        encryptorCache[nickname]?.let { return it }

        val result = try {
            taulight.callFromFlutter("load-encryptor", mapOf(
                "uuid" to uuid.toString(),
                "nickname" to nickname
            ))
        } catch (_: Exception) {
            throw KeyStorageNotFoundException(nickname)
        }

        val keyID = result["key-id"]
        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage = if (encryption.isAsymmetric) {
            encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public-key"]!!)
        } else {
            encryption.symmetric().toKeyStorage(Base64.decode(result["sym-key"]!!, Base64.NO_WRAP))
        }

        val keyEntry = KeyEntry(UUID.fromString(keyID), keyStorage)
        encryptorCache[nickname] = keyEntry
        return keyEntry
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun loadDEK(nickname: String): KeyEntry {
        dekByNicknameCache[nickname]?.let { return it }

        val result = try {
            taulight.callFromFlutter("load-dek", mapOf(
                "uuid" to uuid.toString(),
                "nickname" to nickname
            ))
        } catch (_: Exception) {
            throw KeyStorageNotFoundException(nickname)
        }

        val keyID = result["key-id"]
        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage = if (encryption.isAsymmetric) {
            val pub = encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public-key"]!!)
            val pri = encryption.asymmetric().privateKeyConvertor().toKeyStorage(result["private-key"]!!)
            encryption.asymmetric().merge(pub, pri)
        } else {
            encryption.symmetric().toKeyStorage(Base64.decode(result["sym-key"]!!, Base64.NO_WRAP))
        }

        val keyEntry = KeyEntry(UUID.fromString(keyID), keyStorage)
        dekByNicknameCache[nickname] = keyEntry
        dekByIdCache[UUID.fromString(keyID)] = keyStorage
        return keyEntry
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun loadDEK(keyID: UUID): KeyStorage {
        dekByIdCache[keyID]?.let { return it }

        val result = try {
            taulight.callFromFlutter("load-dek-by-id", mapOf(
                "uuid" to uuid.toString(),
                "key-id" to keyID.toString()
            ))
        } catch (_: Exception) {
            throw KeyStorageNotFoundException(keyID)
        }

        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage = if (encryption.isAsymmetric) {
            val pub = encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public-key"]!!)
            val pri = encryption.asymmetric().privateKeyConvertor().toKeyStorage(result["private-key"]!!)
            encryption.asymmetric().merge(pub, pri)
        } else {
            encryption.symmetric().toKeyStorage(Base64.decode(result["sym-key"]!!, Base64.NO_WRAP))
        }

        dekByIdCache[keyID] = keyStorage
        return keyStorage
    }
}
