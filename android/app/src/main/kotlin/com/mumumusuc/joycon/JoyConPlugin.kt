package com.mumumusuc.joycon

import android.app.Activity
import android.bluetooth.BluetoothDevice
import android.content.Context
import android.content.Intent
import android.util.Log
import com.mumumusuc.libjoycon.BluetoothHelper
import com.mumumusuc.libjoycon.BluetoothHelper.Companion.BT_STATE_DISCOVERY_OFF
import com.mumumusuc.libjoycon.BluetoothHelper.Companion.BT_STATE_DISCOVERY_ON
import com.mumumusuc.libjoycon.Controller
import com.mumumusuc.libjoycon.PermissionHelper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.*
import java.lang.RuntimeException

class JoyConPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, BluetoothHelper.StateChangedCallback {
    companion object {
        const val ROOT = "com.mumumusuc.libjoycon"
    }

    private val btHelper by lazy { BluetoothHelper() }
    private var activity: Activity? = null
    private var chan_bluetooth: MethodChannel? = null
    private var chan_controller: MethodChannel? = null
    private var state_callback: BasicMessageChannel<Any>? = null
    private val controllers = HashSet<Controller>()

    private fun init(messenger: BinaryMessenger) {
        chan_bluetooth = MethodChannel(messenger, "$ROOT/bluetooth")
        chan_bluetooth!!.setMethodCallHandler(this)
        chan_controller = MethodChannel(messenger, "$ROOT/controller")
        chan_controller!!.setMethodCallHandler(this)
        state_callback = BasicMessageChannel(messenger, "$ROOT/bluetooth/state", StandardMessageCodec())
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        init(binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        chan_bluetooth!!.setMethodCallHandler(null)
        chan_bluetooth = null
        chan_controller!!.setMethodCallHandler(null)
        chan_controller = null
        state_callback = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
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

    fun register(activity: Activity) {
        this.activity = activity
        btHelper.register(activity, this)
        btHelper.enable(true)
    }

    fun unregister() {
        btHelper.unregister(activity!!)
        this.activity = null
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
        val cb = state_callback ?: return
        when (state) {
            BT_STATE_DISCOVERY_ON, BT_STATE_DISCOVERY_OFF -> {
            }
            else -> if (!filterDevice(name ?: "")) return
        }
        cb.send(mapOf(Pair("name", name), Pair("address", address), Pair("state", state)))
    }

}