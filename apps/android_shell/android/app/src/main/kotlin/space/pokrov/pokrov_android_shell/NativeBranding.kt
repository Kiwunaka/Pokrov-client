package space.pokrov.pokrov_android_shell

object NativeBranding {
    val appName: String = BuildConfig.OPEN_CLIENT_APP_NAME
    val runtimeDirectory: String = BuildConfig.OPEN_CLIENT_RUNTIME_DIRECTORY
    val notificationChannelId: String = BuildConfig.OPEN_CLIENT_RUNTIME_NOTIFICATION_CHANNEL_ID
    val notificationChannelName: String = BuildConfig.OPEN_CLIENT_RUNTIME_NOTIFICATION_CHANNEL_NAME
    val runtimeActionPrefix: String = BuildConfig.OPEN_CLIENT_RUNTIME_ACTION_PREFIX
    val debugExtraPrefix: String = BuildConfig.OPEN_CLIENT_DEBUG_EXTRA_PREFIX

    fun message(text: String): String = text.replace("{app}", appName)
}
