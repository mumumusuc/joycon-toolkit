package com.mumumusuc.joycon

import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.location.LocationManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import com.mumumusuc.libjoycon.BluetoothHelper
import com.mumumusuc.libjoycon.BluetoothHelper.Companion.BT_STATE_DEVICE_MASK
import com.mumumusuc.libjoycon.Controller
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.*
import android.os.Build.VERSION.SDK_INT
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink


class JoyConPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler, BluetoothHelper.StateChangedCallback {
    companion object {
        const val ROOT = "com.mumumusuc.libjoycon"
    }

    private val btHelper by lazy { BluetoothHelper() }
    private var context: Context? = null
    private var mBluetoothChannel: MethodChannel? = null
    private var mControllerChannel: MethodChannel? = null
    private var mVersionChannel: MethodChannel? = null
    private var mStateCallback: BasicMessageChannel<Any>? = null
    private val controllers = HashSet<Controller>()
    private var mEventSink: EventSink? = null

    private fun init(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        val messenger = binding.binaryMessenger
        mBluetoothChannel = MethodChannel(messenger, "$ROOT/bluetooth")
        mBluetoothChannel!!.setMethodCallHandler(this)
        mControllerChannel = MethodChannel(messenger, "$ROOT/controller")
        mControllerChannel!!.setMethodCallHandler(this)
        mVersionChannel = MethodChannel(messenger, "$ROOT/version")
        mVersionChannel!!.setMethodCallHandler(this)
        mStateCallback = BasicMessageChannel(messenger, "$ROOT/bluetooth/state", StandardMessageCodec())
        val eventChannel = EventChannel(messenger, "$ROOT/location/state")
        eventChannel.setStreamHandler(this)
        btHelper.register(context!!, this)
    }

    private fun deInit() {
        btHelper.unregister(context!!)
        context!!.unregisterReceiver(locationReceiver)
        context = null
        mBluetoothChannel!!.setMethodCallHandler(null)
        mBluetoothChannel = null
        mControllerChannel!!.setMethodCallHandler(null)
        mControllerChannel = null
        mStateCallback = null
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        init(binding)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        deInit()
    }

    override fun onListen(arguments: Any?, events: EventSink) {
        val filter = IntentFilter(LocationManager.MODE_CHANGED_ACTION)
        context!!.registerReceiver(locationReceiver, filter)
        mEventSink = events
        emitLocationServiceStatus(isLocationServiceEnabled(context!!))
    }

    override fun onCancel(arguments: Any?) {
        context!!.unregisterReceiver(locationReceiver)
        mEventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAndroidQ" -> {
                result.success(SDK_INT >= 29)
            }
            /* bluetooth methods */
            "enable" -> {
                val on = call.argument<Boolean>("on")!!
                btHelper.enable(on)
                result.success(0)
            }
            "discovery" -> {
                try {
                    val on = call.argument<Boolean>("on")!!
                    btHelper.discovery(on)
                    result.success(0)
                } catch (e: Exception) {
                    result.error(e::class.java.simpleName, e.message, null)
                }
            }
            "pair" -> {
                try {
                    val address = call.argument<String>("address")!!
                    btHelper.pair(address)
                    result.success(0)
                } catch (e: IllegalArgumentException) {
                    result.error("IllegalArgumentException", e.message, null)
                }
            }
            "connect" -> {
                try {
                    val address = call.argument<String>("address")!!
                    val on = call.argument<Boolean>("on")!!
                    btHelper.connect(address, on)
                    result.success(0)
                } catch (e: IllegalArgumentException) {
                    result.error("IllegalArgumentException", e.message, null)
                }
            }
            "getAdapterState" -> {
                result.success(btHelper.getAdapterState())
            }
            "getDeviceState" -> {
                try {
                    val address = call.argument<String>("address")!!
                    val ret = btHelper.getDeviceState(address)
                    result.success(ret)
                } catch (e: IllegalArgumentException) {
                    result.error("IllegalArgumentException", e.message, null)
                }
            }
            "getPairedDevices" -> {
                val devices: Set<BluetoothDevice> = btHelper.getPairedDevices()
                result.success(devices.filter { filterDevice(it) }.map {
                    mapOf<String, String>(Pair("name", it.name), Pair("address", it.address))
                })
            }
            "getConnectedDevices" -> {
                val devices: Set<BluetoothDevice> = btHelper.getConnectedDevices()
                result.success(devices.filter { filterDevice(it) }.map {
                    mapOf<String, String>(Pair("name", it.name), Pair("address", it.address))
                })
            }
            /* controller methods */
            "create" -> {
                try {
                    val address = call.argument<String>("address")
                            ?: throw IllegalArgumentException("require field 'address'")
                    val device = btHelper.getBluetoothDevice(address)
                    controllers.add(Controller(btHelper, device))
                    result.success(address)
                } catch (e: IllegalArgumentException) {
                    result.error("IllegalArgumentException", e.message, null)
                }
            }
            "destroy" -> {
                try {
                    val address = call.argument<String>("address")
                            ?: throw IllegalArgumentException("require field 'address'")
                    val device = btHelper.getBluetoothDevice(address)
                    val controller = controllers.firstOrNull {
                        it.device == device
                    } ?: throw IllegalArgumentException("controller $address not exist")
                    controllers.remove(controller)
                    result.success(address)
                } catch (e: IllegalArgumentException) {
                    result.error("IllegalArgumentException", e.message, null)
                }
            }
            "poll" -> {
                try {
                    val address = call.argument<String>("address")
                            ?: throw IllegalArgumentException("require field 'address'")
                    val type = call.argument<Int>("type")
                            ?: throw IllegalArgumentException("require field 'type'")
                    val device = btHelper.getBluetoothDevice(address)
                    val controller = controllers.firstOrNull {
                        it.device == device
                    } ?: throw IllegalArgumentException("controller $address not exist")
                    //controller.poll(type)
                    result.success(0)
                } catch (e: IllegalArgumentException) {
                    result.error("IllegalArgumentException", e.message, null)
                }
            }
            "setHomeLight" -> {
                try {
                    val address = call.argument<String>("address")
                            ?: throw IllegalArgumentException("require field 'address'")
                    val intensity = call.argument<Int>("intensity")
                            ?: throw IllegalArgumentException("require field 'intensity'")
                    val duration = call.argument<Int>("duration")
                            ?: throw IllegalArgumentException("require field 'duration'")
                    val repeat = call.argument<Int>("repeat")
                            ?: throw IllegalArgumentException("require field 'repeat'")
                    val cycles = call.argument<List<Int>>("cycles")
                            ?: throw IllegalArgumentException("require field 'cycles'")
                    val device = btHelper.getBluetoothDevice(address)
                    val controller = controllers.firstOrNull {
                        it.device == device
                    } ?: throw IllegalArgumentException("controller $address not exist")
                    val data = ByteArray(cycles.size) { i: Int -> cycles[i].toByte() }
                    controller.setHomeLight(intensity.toByte(), duration.toByte(), repeat.toByte(), data)
                    result.success(0)
                } catch (e: IllegalArgumentException) {
                    result.error("IllegalArgumentException", e.message, null)
                }
            }
            "setPlayer" -> {
                try {
                    val address = call.argument<String>("address")
                            ?: throw IllegalArgumentException("require field 'address'")
                    val player = call.argument<Int>("player")
                            ?: throw IllegalArgumentException("require field 'player'")
                    val flash = call.argument<Int>("flash")
                            ?: throw IllegalArgumentException("require field 'flash'")
                    val device = btHelper.getBluetoothDevice(address)
                    val controller = controllers.firstOrNull {
                        it.device == device
                    } ?: throw IllegalArgumentException("controller $address not exist")
                    controller.setPlayer(player.toByte(), flash.toByte())
                    result.success(0)
                } catch (e: IllegalArgumentException) {
                    result.error("IllegalArgumentException", e.message, null)
                }
            }
            "setColor" -> {
                try {
                    val address = call.argument<String>("address")
                            ?: throw IllegalArgumentException("require field 'address'")
                    val body = call.argument<Long>("body")
                            ?: throw IllegalArgumentException("require field 'body'")
                    val button = call.argument<Long>("button")
                            ?: throw IllegalArgumentException("require field 'button'")
                    val left_grip = call.argument<Long>("left_grip")
                            ?: throw IllegalArgumentException("require field 'left_grip'")
                    val right_grip = call.argument<Long>("right_grip")
                            ?: throw IllegalArgumentException("require field 'right_grip'")
                    val device = btHelper.getBluetoothDevice(address)
                    val controller = controllers.firstOrNull {
                        it.device == device
                    } ?: throw IllegalArgumentException("controller $address not exist")
                    controller.setColor(body.and(0xFFFFFF).toInt(), button.and(0xFFFFFF).toInt(), left_grip.and(0xFFFFFF).toInt(), right_grip.and(0xFFFFFF).toInt())
                    result.success(0)
                } catch (e: IllegalArgumentException) {
                    result.error("IllegalArgumentException", e.message, null)
                }
            }
            "enableRumble" -> {
                try {
                    val address = call.argument<String>("address")
                            ?: throw IllegalArgumentException("require field 'address'")
                    val enable = call.argument<Boolean>("enable")
                            ?: throw IllegalArgumentException("require field 'enable'")
                    val device = btHelper.getBluetoothDevice(address)
                    val controller = controllers.firstOrNull {
                        it.device == device
                    } ?: throw IllegalArgumentException("controller $address not exist")
                    controller.enableRumble(enable)
                    result.success(0)
                } catch (e: IllegalArgumentException) {
                    result.error("IllegalArgumentException", e.message, null)
                }
            }
            "rumble" -> {
                try {
                    val address = call.argument<String>("address")
                            ?: throw IllegalArgumentException("require field 'address'")
                    val data = call.argument<List<Int>>("data")
                    require(data != null) { "require field 'data'" }
                    val device = btHelper.getBluetoothDevice(address)
                    val controller = controllers.firstOrNull {
                        it.device == device
                    } ?: throw IllegalArgumentException("controller $address not exist")
                    controller.rumble(
                            data[0].toByte(), data[1].toByte(), data[2].toByte(), data[3].toByte(),
                            data[4].toByte(), data[5].toByte(), data[6].toByte(), data[7].toByte()
                    )
                    result.success(0)
                } catch (e: IllegalArgumentException) {
                    result.error("IllegalArgumentException", e.message, null)
                }
            }
            "rumblef" -> {
                //btHelper.rumble(address, hf, ha, lf, la)
                try {
                    val address = call.argument<String>("address")
                            ?: throw IllegalArgumentException("require field 'address'")
                    val data = call.argument<List<Double>>("data")
                    require(data != null) { "require field 'data'" }
                    val device = btHelper.getBluetoothDevice(address)
                    val controller = controllers.firstOrNull {
                        it.device == device
                    } ?: throw IllegalArgumentException("controller $address not exist")
                    controller.rumblef(
                            Controller.RumbleDataF(
                                    data[0].toFloat(),
                                    data[1].toFloat(),
                                    data[2].toFloat(),
                                    data[3].toFloat(),
                                    data[4].toFloat(),
                                    data[5].toFloat(),
                                    data[6].toFloat(),
                                    data[7].toFloat()
                            )
                    )
                    result.success(0)
                } catch (e: IllegalArgumentException) {
                    result.error("IllegalArgumentException", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private val locationReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(p0: Context, p1: Intent) {
            if (p1.action == LocationManager.MODE_CHANGED_ACTION) {
                emitLocationServiceStatus(isLocationServiceEnabled(context!!))
            }
        }
    }

    private fun filterDevice(name: String): Boolean {
        return when (name) {
            Controller.JOYCON_L, Controller.JOYCON_R, Controller.PRO_CONTROLLER -> true
            else -> false
        }
    }

    private fun filterDevice(dev: BluetoothDevice): Boolean {
        return filterDevice(dev.name)
    }

    override fun onStateChanged(name: String?, address: String?, state: Int) {
        val cb = mStateCallback ?: return
        if (state.and(BT_STATE_DEVICE_MASK) != 0)
            if (!filterDevice(name ?: "")) return
        cb.send(mapOf(Pair("name", name), Pair("address", address), Pair("state", state)))
    }

    private fun emitLocationServiceStatus(enabled: Boolean) {
        mEventSink?.success(enabled)
    }

    private fun isLocationServiceEnabled(context: Context): Boolean {
        if (SDK_INT >= 28) {
            val locationManager = context.getSystemService(LocationManager::class.java)
                    ?: return false
            return locationManager.isLocationEnabled
        } else {
            val locationMode: Int
            try {
                locationMode = Settings.Secure.getInt(context.contentResolver, Settings.Secure.LOCATION_MODE)
            } catch (e: Settings.SettingNotFoundException) {
                e.printStackTrace()
                return false
            }
            return locationMode != Settings.Secure.LOCATION_MODE_OFF
        }
    }

}