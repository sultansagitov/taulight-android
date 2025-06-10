package net.result.taulight.config

import android.os.Build
import android.util.Base64
import androidx.annotation.RequiresApi
import net.result.sandnode.config.AgentConfig
import net.result.sandnode.config.KeyEntry
import net.result.sandnode.encryption.EncryptionManager
import net.result.sandnode.encryption.interfaces.AsymmetricKeyStorage
import net.result.sandnode.encryption.interfaces.KeyStorage
import net.result.sandnode.exception.error.KeyStorageNotFoundException
import net.result.sandnode.util.Address
import net.result.taulight.Taulight
import java.util.*

class AndroidAgentConfig(val taulight: Taulight) : AgentConfig {
    private val publicKeyCache = mutableMapOf<Address, AsymmetricKeyStorage>()
    private val personalKeyCache = mutableMapOf<UUID, KeyStorage>()
    private val encryptorCache = mutableMapOf<String, KeyEntry>()
    private val dekByNicknameCache = mutableMapOf<String, KeyEntry>()
    private val dekByIdCache = mutableMapOf<UUID, KeyStorage>()

    override fun saveServerKey(address: Address, keyStorage: AsymmetricKeyStorage) {
        taulight.sendToFlutter("save-key", mapOf(
            "address" to address.toString(),
            "encryption" to keyStorage.encryption().name(),
            "public" to keyStorage.encodedPublicKey(),
        ))
        publicKeyCache[address] = keyStorage
    }

    override fun loadServerKey(address: Address): AsymmetricKeyStorage {
        publicKeyCache[address]?.let { return it }

        val result = try {
            taulight.callFromFlutter("get-public", mapOf("address" to address.toString()))
        } catch (_: Exception) {
            throw KeyStorageNotFoundException(address.toString())
        }

        val publicKey = result["public"]!!
        val encryptionString = result["encryption"]!!

        val encryption = EncryptionManager.find(encryptionString).asymmetric()
        val keyStorage = encryption.publicKeyConvertor().toKeyStorage(publicKey)

        publicKeyCache[address] = keyStorage
        return keyStorage
    }

    override fun savePersonalKey(address: Address, keyID: UUID, keyStorage: KeyStorage) {
        val data = mutableMapOf(
            "address" to address.toString(52525),
            "key-id" to keyID.toString(),
            "encryption" to keyStorage.encryption().name()
        )

        if (keyStorage.encryption().isSymmetric) {
            data["sym"] = keyStorage.symmetric().encoded()
        }

        if (keyStorage.encryption().isAsymmetric) {
            data["public"] = keyStorage.asymmetric().encodedPublicKey()
            data["private"] = keyStorage.asymmetric().encodedPrivateKey()
        }

        taulight.sendToFlutter("save-personal-key", data)
        personalKeyCache[keyID] = keyStorage
    }

    override fun saveEncryptor(address: Address, nickname: String, keyID: UUID, keyStorage: KeyStorage) {
        val data = mutableMapOf(
            "address" to address.toString(52525),
            "nickname" to nickname,
            "key-id" to keyID.toString(),
            "encryption" to keyStorage.encryption().name()
        )

        if (keyStorage.encryption().isSymmetric) {
            data["sym"] = keyStorage.symmetric().encoded()
        }

        if (keyStorage.encryption().isAsymmetric) {
            data["public"] = keyStorage.asymmetric().encodedPublicKey()
        }

        taulight.sendToFlutter("save-encryptor", data)
        encryptorCache[nickname] = KeyEntry(keyID, keyStorage)
    }

    override fun saveDEK(address: Address, nickname: String, keyID: UUID, keyStorage: KeyStorage) {
        val data = mutableMapOf(
            "address" to address.toString(52525),
            "nickname" to nickname,
            "key-id" to keyID.toString(),
            "encryption" to keyStorage.encryption().name()
        )

        if (keyStorage.encryption().isSymmetric) {
            data["sym"] = keyStorage.symmetric().encoded()
        }

        if (keyStorage.encryption().isAsymmetric) {
            data["public"] = keyStorage.asymmetric().encodedPublicKey()
            data["private"] = keyStorage.asymmetric().encodedPrivateKey()
        }

        taulight.sendToFlutter("save-dek", data)
        dekByNicknameCache[nickname] = KeyEntry(keyID, keyStorage)
        dekByIdCache[keyID] = keyStorage
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun loadPersonalKey(address: Address, keyID: UUID): KeyStorage {
        personalKeyCache[keyID]?.let { return it }

        val result = try {
            taulight.callFromFlutter("load-personal-key", mapOf(
                "address" to address.toString(52525),
                "key-id" to keyID.toString())
            )
        } catch (_: Exception) {
            throw KeyStorageNotFoundException(keyID)
        }

        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage = if (encryption.isAsymmetric) {
            val pub = encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public"]!!)
            val pri = encryption.asymmetric().privateKeyConvertor().toKeyStorage(result["private"]!!)
            encryption.asymmetric().merge(pub, pri)
        } else {
            encryption.symmetric().toKeyStorage(Base64.decode(result["sym"]!!, Base64.NO_WRAP))
        }

        personalKeyCache[keyID] = keyStorage
        return keyStorage
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun loadEncryptor(address: Address, nickname: String): KeyEntry {
        encryptorCache[nickname]?.let { return it }

        val result = try {
            taulight.callFromFlutter("load-encryptor", mapOf(
                "address" to address.toString(52525),
                "nickname" to nickname),
            )
        } catch (_: Exception) {
            throw KeyStorageNotFoundException(nickname)
        }

        val keyID = result["key-id"]
        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage = if (encryption.isAsymmetric) {
            encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public"]!!)
        } else {
            encryption.symmetric().toKeyStorage(Base64.decode(result["sym"]!!, Base64.NO_WRAP))
        }

        val keyEntry = KeyEntry(UUID.fromString(keyID), keyStorage)
        encryptorCache[nickname] = keyEntry
        return keyEntry
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun loadDEK(address: Address, nickname: String): KeyEntry {
        dekByNicknameCache[nickname]?.let { return it }

        val result = try {
            taulight.callFromFlutter("load-dek", mapOf(
                "address" to address.toString(52525),
                "nickname" to nickname),
            )
        } catch (_: Exception) {
            throw KeyStorageNotFoundException(nickname)
        }

        val keyID = result["key-id"]
        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage = if (encryption.isAsymmetric) {
            val pub = encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public"]!!)
            val pri = encryption.asymmetric().privateKeyConvertor().toKeyStorage(result["private"]!!)
            encryption.asymmetric().merge(pub, pri)
        } else {
            encryption.symmetric().toKeyStorage(Base64.decode(result["sym"]!!, Base64.NO_WRAP))
        }

        val keyEntry = KeyEntry(UUID.fromString(keyID), keyStorage)
        dekByNicknameCache[nickname] = keyEntry
        dekByIdCache[UUID.fromString(keyID)] = keyStorage
        return keyEntry
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun loadDEK(address: Address, keyID: UUID): KeyStorage {
        dekByIdCache[keyID]?.let { return it }

        val result = try {
            taulight.callFromFlutter("load-dek-by-id", mapOf(
                "address" to address.toString(52525),
                "key-id" to keyID.toString()),
            )
        } catch (_: Exception) {
            throw KeyStorageNotFoundException(keyID)
        }

        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage = if (encryption.isAsymmetric) {
            val pub = encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public"]!!)
            val pri = encryption.asymmetric().privateKeyConvertor().toKeyStorage(result["private"]!!)
            encryption.asymmetric().merge(pub, pri)
        } else {
            encryption.symmetric().toKeyStorage(Base64.decode(result["sym"]!!, Base64.NO_WRAP))
        }

        dekByIdCache[keyID] = keyStorage
        return keyStorage
    }
}
