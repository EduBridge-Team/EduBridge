package com.edubridge.app

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        super.onCreate(savedInstanceState)

        // Android 12+ always owns a short system splash. Remove its exit
        // animation immediately so the user only perceives the branded
        // Flutter splash that follows.
        splashScreen.setOnExitAnimationListener { provider ->
            provider.remove()
        }
    }
}
