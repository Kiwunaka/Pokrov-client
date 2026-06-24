package io.nekohasekai.libbox

interface BoxService {
    fun start()
    fun close()
}

interface InterfaceUpdateListener {
    fun updateDefaultInterface(name: String, index: Int)
}

interface StringIterator {
    fun hasNext(): Boolean
    fun next(): String
}

interface RoutePrefixIterator {
    fun hasNext(): Boolean
    fun next(): RoutePrefix
}

interface NetworkInterfaceIterator {
    fun hasNext(): Boolean
    fun next(): NetworkInterface
}

interface LocalDNSTransport {
    fun raw(): Boolean
    fun exchange(ctx: ExchangeContext, message: ByteArray)
    fun lookup(ctx: ExchangeContext, network: String, domain: String)
}

interface ExchangeContext {
    fun onCancel(callback: () -> Unit)
    fun rawSuccess(message: ByteArray)
    fun success(message: String)
    fun errorCode(code: Int)
    fun errnoCode(code: Int)
}

interface PlatformInterface {
    fun autoDetectInterfaceControl(fd: Int)
    fun clearDNSCache()
    fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener)
    fun findConnectionOwner(
        ipProtocol: Int,
        sourceAddress: String,
        sourcePort: Int,
        destinationAddress: String,
        destinationPort: Int,
    ): Int
    fun getInterfaces(): NetworkInterfaceIterator
    fun includeAllNetworks(): Boolean
    fun openTun(options: TunOptions): Int
    fun packageNameByUid(uid: Int): String
    fun readWIFIState(): WIFIState?
    fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener)
    fun uidByPackageName(packageName: String): Int
    fun underNetworkExtension(): Boolean
    fun usePlatformAutoDetectInterfaceControl(): Boolean
    fun usePlatformDefaultInterfaceMonitor(): Boolean
    fun usePlatformInterfaceGetter(): Boolean
    fun useProcFS(): Boolean
    fun writeLog(message: String)
}

class NetworkInterface {
    fun setIndex(value: Int) = Unit
    fun setMTU(value: Int) = Unit
    fun setName(value: String) = Unit
    fun setAddresses(value: StringIterator) = Unit
}

class RoutePrefix(
    private val address: String = "",
    private val prefix: Int = 0,
) {
    fun address(): String = address
    fun prefix(): Int = prefix
}

class TunOptions {
    fun getMTU(): Int = 0
    fun getAutoRoute(): Boolean = false
    fun getDNSServerAddress(): String = ""
    fun getInet4Address(): RoutePrefixIterator? = null
    fun getInet6Address(): RoutePrefixIterator? = null
    fun getInet4RouteAddress(): RoutePrefixIterator? = null
    fun getInet6RouteAddress(): RoutePrefixIterator? = null
    fun getInet4RouteExcludeAddress(): RoutePrefixIterator? = null
    fun getInet6RouteExcludeAddress(): RoutePrefixIterator? = null
    fun getInet4RouteRange(): RoutePrefixIterator? = null
    fun getInet6RouteRange(): RoutePrefixIterator? = null
    fun getIncludePackage(): StringIterator? = null
    fun getExcludePackage(): StringIterator? = null
}

class WIFIState

object Libbox {
    fun touch() = Unit
    fun setup(
        baseDirectory: String,
        workingDirectory: String,
        tempDirectory: String,
        debug: Boolean,
    ) = Unit

    fun registerLocalDNSTransport(transport: LocalDNSTransport?) = Unit

    fun newService(content: String, platformInterface: PlatformInterface): BoxService {
        return object : BoxService {
            override fun start() = Unit
            override fun close() = Unit
        }
    }
}
