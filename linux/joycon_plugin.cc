#include "joycon_plugin.h"

#include <flutter/basic_message_channel.h>
#include <flutter/message_codec.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_glfw.h>
#include <flutter/standard_message_codec.h>
#include <flutter/standard_method_codec.h>
#include <string.h>
#include <sys/utsname.h>

#include <iostream>
#include <map>
#include <memory>
#include <sstream>
#include <thread>

#include "../modules/bluez/gutil.h"

namespace {
using namespace bluez;
using namespace flutter;
using flutter::EncodableMap;
using flutter::EncodableValue;

class FlutterJoyconPlugin : public Plugin {
   public:
    static void RegisterWithRegistrar(PluginRegistrarGlfw *registrar);

    FlutterJoyconPlugin(
        std::unique_ptr<BasicMessageChannel<EncodableValue>> &&callback);

    virtual ~FlutterJoyconPlugin();

   private:
    BluezUtil util;
    std::unique_ptr<BasicMessageChannel<EncodableValue>> state_callback;
    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(const MethodCall<EncodableValue> &method_call,
                          std::unique_ptr<MethodResult<EncodableValue>> result);
    void HandleBluezEvent(BluetoothEvent event, const BluetoothDevice *device);
    void ConvertDeviceMap(EncodableMap &map, const BluetoothDevice *device);
    bool IsNintendoDevice(const BluetoothDevice *device);
};

// static
void FlutterJoyconPlugin::RegisterWithRegistrar(
    PluginRegistrarGlfw *registrar) {
    auto bluetooth_channel = std::make_unique<MethodChannel<EncodableValue>>(
        registrar->messenger(), "com.mumumusuc.libjoycon/bluetooth",
        &StandardMethodCodec::GetInstance());
    auto state_callback = std::make_unique<BasicMessageChannel<EncodableValue>>(
        registrar->messenger(), "com.mumumusuc.libjoycon/bluetooth/state",
        &StandardMessageCodec::GetInstance());
    auto plugin =
        std::make_unique<FlutterJoyconPlugin>(std::move(state_callback));
    bluetooth_channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
}

void FlutterJoyconPlugin::ConvertDeviceMap(EncodableMap &map,
                                           const BluetoothDevice *device) {
    assert(device);
    map[EncodableValue("key")] = EncodableValue(device->object_path());
    map[EncodableValue("name")] = EncodableValue(device->name());
    map[EncodableValue("address")] = EncodableValue(device->address());
    map[EncodableValue("state")] = EncodableValue(device->state());
}

bool FlutterJoyconPlugin::IsNintendoDevice(const BluetoothDevice *device) {
    // TODO : check vid/pid (?)
    // dict entry(
    //      string "Modalias"
    //      variant string "usb:v057Ep2007d0001"
    // )
    if (!device) return false;
    auto name = device->name();
    if (!name || strlen(name) == 0) return false;
    return strcmp(name, "Pro Controller") == 0 ||
           strcmp(name, "Joy-Con (L)") == 0 || strcmp(name, "Joy-Con (R)") == 0;
}

FlutterJoyconPlugin::FlutterJoyconPlugin(
    std::unique_ptr<BasicMessageChannel<EncodableValue>> &&callback)
    : util() {
    state_callback.swap(callback);
    util.RegisterListener(std::bind(&FlutterJoyconPlugin::HandleBluezEvent,
                                    this, std::placeholders::_1,
                                    std::placeholders::_2));
}

FlutterJoyconPlugin::~FlutterJoyconPlugin() { util.RegisterListener(nullptr); }

void FlutterJoyconPlugin::HandleBluezEvent(BluetoothEvent event,
                                           const BluetoothDevice *device) {
    EncodableMap param;
    if (event == EV_DEVICE && IsNintendoDevice(device)) {
        ConvertDeviceMap(param, device);
    }
    param[EncodableValue("event")] =
        EncodableValue(static_cast<BluetoothEventType>(event));
    state_callback->Send(EncodableValue(param));
}

void FlutterJoyconPlugin::HandleMethodCall(
    const MethodCall<EncodableValue> &method_call,
    std::unique_ptr<MethodResult<EncodableValue>> result) {
    // Replace "getPlatformVersion" check with your plugin's method.
    // See:
    // https://github.com/flutter/engine/tree/master/shell/platform/common/cpp/client_wrapper/include/flutter
    // and
    // https://github.com/flutter/engine/tree/master/shell/platform/glfw/client_wrapper/include/flutter
    // for the relevant Flutter APIs.
    auto method = method_call.method_name();
    if (method.compare("enable") == 0) {
        bool on = false;
        if (method_call.arguments() && method_call.arguments()->IsMap()) {
            const EncodableMap &arguments = method_call.arguments()->MapValue();
            auto value_it = arguments.find(EncodableValue("on"));
            if (value_it != arguments.end()) {
                on = value_it->second.BoolValue();
                std::cout << "got input: " << on << std::endl;
                // TODO: enable adpater
            }
        } else {
            std::cout << "argument_error" << std::endl;
            result->Error("argument_error", "No 'on' provided");
            return;
        }
        result->Success();
    } else if (method.compare("discovery") == 0) {
        bool on = false;
        if (method_call.arguments() && method_call.arguments()->IsMap()) {
            const EncodableMap &arguments = method_call.arguments()->MapValue();
            auto value_it = arguments.find(EncodableValue("on"));
            if (value_it != arguments.end()) {
                on = value_it->second.BoolValue();
                std::cout << "discovery got input: " << on << std::endl;
                if (on)
                    util.StartDiscovery();
                else
                    util.StopDiscovery();
            }
        } else {
            std::cout << "argument_error" << std::endl;
            result->Error("argument_error", "No 'on' provided");
            return;
        }
        result->Success();
    } else if (method.compare("pair") == 0) {
        std::string key;
        if (method_call.arguments() && method_call.arguments()->IsMap()) {
            const EncodableMap &arguments = method_call.arguments()->MapValue();
            auto value_it = arguments.find(EncodableValue("key"));
            if (value_it != arguments.end()) {
                key = value_it->second.StringValue();
                std::cout << "pair got input: " << key << std::endl;
                util.Pair(key.c_str());
            }
        } else {
            std::cout << "argument_error" << std::endl;
            result->Error("argument_error", "No 'key' provided");
            return;
        }
        result->Success();
    } else if (method.compare("connect") == 0) {
        bool on = false;
        std::string key;
        if (method_call.arguments() && method_call.arguments()->IsMap()) {
            const EncodableMap &arguments = method_call.arguments()->MapValue();
            auto key_it = arguments.find(EncodableValue("key"));
            if (key_it != arguments.end()) {
                key = key_it->second.StringValue();
                std::cout << "connect got input: " << key << std::endl;
            }
            auto on_it = arguments.find(EncodableValue("on"));
            if (on_it != arguments.end()) {
                on = on_it->second.BoolValue();
                std::cout << "connect got input: " << on << std::endl;
            }
            if (on)
                util.Connect(key.c_str());
            else
                util.Disconnect(key.c_str());
        } else {
            std::cout << "argument_error" << std::endl;
            result->Error("argument_error", "No 'address' provided");
            return;
        }
        result->Success();
    } else if (method.compare("getAdapterState") == 0) {
        std::cout << "getAdapterState" << std::endl;
        EncodableValue response(util.GetAdapterState());
        result->Success(&response);
    } else if (method.compare("getDeviceState") == 0) {
        EncodableValue response("later");
        result->Success(&response);
    } else if (method.compare("getDevices") == 0) {
        std::cout << "-- getDevices" << std::endl;
        EncodableList list;
        auto devices = util.GetDevices();
        auto iter = devices.cbegin();
        while (iter != devices.cend()) {
            if (IsNintendoDevice(iter->get())) {
                EncodableMap map;
                ConvertDeviceMap(map, iter->get());
                list.emplace_back(map);
            }
            iter++;
        }
        EncodableValue response(list);
        result->Success(&response);
    } else {
        result->NotImplemented();
    }
}

}  // namespace

void FlutterJoyconPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
    // The plugin registrar wrappers owns the plugins, registered callbacks,
    // etc., so must remain valid for the life of the application.
    static auto *plugin_registrars =
        new std::map<FlutterDesktopPluginRegistrarRef,
                     std::unique_ptr<PluginRegistrarGlfw>>;
    auto insert_result = plugin_registrars->emplace(
        registrar, std::make_unique<PluginRegistrarGlfw>(registrar));

    FlutterJoyconPlugin::RegisterWithRegistrar(
        insert_result.first->second.get());
}
