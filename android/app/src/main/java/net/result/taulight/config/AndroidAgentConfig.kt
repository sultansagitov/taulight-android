package net.result.taulight.config

import android.util.Base64
import net.result.sandnode.config.AgentConfig
import net.result.sandnode.config.KeyEntry
import net.result.sandnode.encryption.EncryptionManager
import net.result.sandnode.encryption.interfaces.AsymmetricKeyStorage
import net.result.sandnode.encryption.interfaces.KeyStorage
import net.result.sandnode.key.Source
import net.result.sandnode.util.Address
import net.result.sandnode.util.Member
import net.result.taulight.Taulight
import java.util.*

class AndroidAgentConfig(val taulight: Taulight) : AgentConfig {
    private val publicKeyCache = mutableMapOf<Address, AsymmetricKeyStorage>()
    private val personalKeyCache = mutableMapOf<String, KeyStorage>()
    private val encryptorCache = mutableMapOf<String, KeyStorage>()
    private val dekByNicknameCache = mutableMapOf<String, KeyEntry>()
    private val dekByIdCache = mutableMapOf<UUID, KeyStorage>()

    override fun saveServerKey(source: Source, address: Address, keyStorage: AsymmetricKeyStorage) {
        taulight.sendToFlutter("save-server-key", mapOf(
            "address" to address.toString(),
            "encryption" to keyStorage.encryption().name(),
            "public" to keyStorage.encodedPublicKey(),
            "source" to mapOf<String, Any>(
                "name" to source.javaClass.simpleName,
                "data" to taulight.convertValue(source, Map::class.java)!!,
            ),
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

    override fun savePersonalKey(source: Source, member: Member, keyStorage: KeyStorage) {
        val data = mutableMapOf(
            "address" to member.address.toString(52525),
            "nickname" to member.nickname,
            "encryption" to keyStorage.encryption().name(),
            "source" to mapOf<String, Any>(
                "name" to source.javaClass.simpleName,
                "data" to taulight.convertValue(source, Map::class.java)!!,
            ),
        )

        if (keyStorage.encryption().isSymmetric) {
            data["sym"] = keyStorage.symmetric().encoded()
        }

        if (keyStorage.encryption().isAsymmetric) {
            data["public"] = keyStorage.asymmetric().encodedPublicKey()
            data["private"] = keyStorage.asymmetric().encodedPrivateKey()
        }

        taulight.sendToFlutter("save-personal-key", data)
        personalKeyCache[member.toString()] = keyStorage
    }

    override fun loadPersonalKey(member: Member): KeyStorage {
        personalKeyCache[member.toString()]?.let { return it }

        val result = taulight.callFromFlutter("load-personal-key", mapOf(
            "address" to member.address.toString(52525),
            "nickname" to member.nickname
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

        personalKeyCache[member.toString()] = keyStorage
        return keyStorage
    }

    override fun saveEncryptor(source: Source, member: Member, keyStorage: KeyStorage) {
        val data = mutableMapOf(
            "address" to member.address.toString(52525),
            "nickname" to member.nickname,
            "encryption" to keyStorage.encryption().name(),
            "source" to mapOf<String, Any>(
                "name" to source.javaClass.simpleName,
                "data" to taulight.convertValue(source, Map::class.java)!!,
            ),
        )

        if (keyStorage.encryption().isSymmetric) {
            data["sym"] = keyStorage.symmetric().encoded()
        }

        if (keyStorage.encryption().isAsymmetric) {
            data["public"] = keyStorage.asymmetric().encodedPublicKey()
        }

        taulight.sendToFlutter("save-encryptor", data)
        encryptorCache[member.toString()] = keyStorage
    }

    override fun loadEncryptor(member: Member): KeyStorage {
        encryptorCache[member.toString()]?.let { return it }

        val result = taulight.callFromFlutter("load-encryptor", mapOf(
            "address" to member.address.toString(52525),
            "nickname" to member.nickname,
        ))

        val encryptionString = result["encryption"]

        val encryption = EncryptionManager.find(encryptionString)

        val keyStorage = if (encryption.isAsymmetric) {
            encryption.asymmetric().publicKeyConvertor().toKeyStorage(result["public"]!!)
        } else {
            encryption.symmetric().toKeyStorage(Base64.decode(result["sym"]!!, Base64.NO_WRAP))
        }

        encryptorCache[member.toString()] = keyStorage
        return keyStorage
    }

    override fun saveDEK(source: Source, m1: Member, m2: Member, keyID: UUID, keyStorage: KeyStorage) {
        val data = mutableMapOf(
            "m1" to mapOf(
                "address" to m1.address.toString(52525),
                "nickname" to m1.nickname,
            ),
            "m2" to mapOf(
                "address" to m2.address.toString(52525),
                "nickname" to m2.nickname,
            ),
            "key-id" to keyID.toString(),
            "encryption" to keyStorage.encryption().name(),
            "source" to mapOf<String, Any>(
                "name" to source.javaClass.simpleName,
                "data" to taulight.convertValue(source, Map::class.java)!!,
            ),
        )

        if (keyStorage.encryption().isSymmetric) {
            data["sym"] = keyStorage.symmetric().encoded()
        }

        if (keyStorage.encryption().isAsymmetric) {
            data["public"] = keyStorage.asymmetric().encodedPublicKey()
            data["private"] = keyStorage.asymmetric().encodedPrivateKey()
        }

        taulight.sendToFlutter("save-dek", data)
        val key = listOf(m1.toString(), m2.toString()).sorted().joinToString(" ")
        dekByNicknameCache[key] = KeyEntry(keyID, keyStorage)
        dekByIdCache[keyID] = keyStorage
    }

    override fun loadDEK(m1: Member, m2: Member): KeyEntry {
        val key = listOf(m1.toString(), m2.toString()).sorted().joinToString(" ")
        dekByNicknameCache[key]?.let { return it }

        val result = taulight.callFromFlutter("load-dek", mapOf(
            "m1" to mapOf(
                "address" to m1.address.toString(52525),
                "nickname" to m1.nickname,
            ),
            "m2" to mapOf(
                "address" to m2.address.toString(52525),
                "nickname" to m2.nickname,
            ),
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

        dekByNicknameCache[key] = keyEntry
        dekByIdCache[keyID] = keyStorage
        return keyEntry
    }

    override fun loadDEK(keyID: UUID): KeyStorage {
        dekByIdCache[keyID]?.let { return it }

        val result = taulight.callFromFlutter("load-dek-by-id", mapOf("key-id" to keyID.toString(),))

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
