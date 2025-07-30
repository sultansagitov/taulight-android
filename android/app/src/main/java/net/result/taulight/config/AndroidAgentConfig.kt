package net.result.taulight.config

import android.util.Base64
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
    private val personalKeyCache = mutableMapOf<String, KeyStorage>()
    private val encryptorCache = mutableMapOf<String, KeyStorage>()
    private val dekByNicknameCache = mutableMapOf<String, KeyEntry>()
    private val dekByIdCache = mutableMapOf<UUID, KeyStorage>()

    override fun saveServerKey(address: Address, keyStorage: AsymmetricKeyStorage) {
        taulight.sendToFlutter("save-server-key", mapOf(
            "address" to address.toString(),
            "encryption" to keyStorage.encryption().name(),
            "public" to keyStorage.encodedPublicKey(),
        ))
        publicKeyCache[address] = keyStorage
    }

    override fun loadServerKey(address: Address): AsymmetricKeyStorage {
        publicKeyCache[address]?.let { return it }

        val result = taulight.callFromFlutter("load-server-key", mapOf("address" to address.toString()))

        val publicKey = result["public"]!!
        val encryptionString = result["encryption"]!!

        val encryption = EncryptionManager.find(encryptionString).asymmetric()
        val keyStorage = encryption.publicKeyConvertor().toKeyStorage(publicKey)

        publicKeyCache[address] = keyStorage
        return keyStorage
    }

    override fun savePersonalKey(address: Address, nickname: String, keyStorage: KeyStorage) {
        val data = mutableMapOf(
            "address" to address.toString(52525),
            "nickname" to nickname,
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
        personalKeyCache["$nickname@$address"] = keyStorage
    }

    override fun saveEncryptor(address: Address, nickname: String, keyStorage: KeyStorage) {
        val data = mutableMapOf(
            "address" to address.toString(52525),
            "nickname" to nickname,
            "encryption" to keyStorage.encryption().name()
        )

        if (keyStorage.encryption().isSymmetric) {
            data["sym"] = keyStorage.symmetric().encoded()
        }

        if (keyStorage.encryption().isAsymmetric) {
            data["public"] = keyStorage.asymmetric().encodedPublicKey()
        }

        taulight.sendToFlutter("save-encryptor", data)
        encryptorCache["$nickname@$address"] = keyStorage
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
        dekByNicknameCache["$nickname@$address"] = KeyEntry(keyID, keyStorage)
        dekByIdCache[keyID] = keyStorage
    }

    override fun loadPersonalKey(address: Address, nickname: String): KeyStorage {
        personalKeyCache["$nickname@$address"]?.let { return it }

        val result = taulight.callFromFlutter("load-personal-key", mapOf(
            "address" to address.toString(52525),
            "nickname" to nickname
        ))

        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage = if (encryption.isAsymmetric) {
            val pub = encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public"]!!)
            val pri = encryption.asymmetric().privateKeyConvertor().toKeyStorage(result["private"]!!)
            encryption.asymmetric().merge(pub, pri)
        } else {
            encryption.symmetric().toKeyStorage(Base64.decode(result["sym"]!!, Base64.NO_WRAP))
        }

        personalKeyCache["$nickname@$address"] = keyStorage
        return keyStorage
    }

    override fun loadEncryptor(address: Address, nickname: String): KeyStorage {
        encryptorCache["$nickname@$address"]?.let { return it }

        val result = taulight.callFromFlutter("load-encryptor", mapOf(
            "address" to address.toString(52525),
            "nickname" to nickname,
        ))

        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage = if (encryption.isAsymmetric) {
            encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public"]!!)
        } else {
            encryption.symmetric().toKeyStorage(Base64.decode(result["sym"]!!, Base64.NO_WRAP))
        }

        encryptorCache["$nickname@$address"] = keyStorage
        return keyStorage
    }

    override fun loadDEK(address: Address, nickname: String): KeyEntry {
        dekByNicknameCache["$nickname@$address"]?.let { return it }

        val result = taulight.callFromFlutter("load-dek", mapOf(
            "address" to address.toString(52525),
            "nickname" to nickname,
        ))

        val keyID = UUID.fromString(result["key-id"])
        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage = if (encryption.isAsymmetric) {
            val pub = encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public"]!!)
            val pri = encryption.asymmetric().privateKeyConvertor().toKeyStorage(result["private"]!!)
            encryption.asymmetric().merge(pub, pri)
        } else {
            encryption.symmetric().toKeyStorage(Base64.decode(result["sym"]!!, Base64.NO_WRAP))
        }

        val keyEntry = KeyEntry(keyID, keyStorage)
        dekByNicknameCache["$nickname@$address"] = keyEntry
        dekByIdCache[keyID] = keyStorage
        return keyEntry
    }

    override fun loadDEK(address: Address, keyID: UUID): KeyStorage {
        dekByIdCache[keyID]?.let { return it }

        val result = taulight.callFromFlutter("load-dek-by-id", mapOf(
            "address" to address.toString(52525),
            "key-id" to keyID.toString(),
        ))

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
