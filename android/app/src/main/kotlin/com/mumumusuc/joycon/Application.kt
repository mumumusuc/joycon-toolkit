package com.mumumusuc.joycon

import androidx.appcompat.app.AppCompatDelegate
import io.flutter.app.FlutterApplication

class Application : FlutterApplication() {
    companion object {
        init {
            AppCompatDelegate.setDefaultNightMode(
                    AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM);
        }
    }
}