package com.linphonetest
import android.net.Uri
import android.os.Build
import android.telecom.CallAttributes
import android.util.JsonWriter
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.telecom.CallAttributesCompat
import androidx.core.telecom.CallsManager
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.bridge.WritableMap
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.supervisorScope

import org.linphone.core.*

class LinphoneModule(reactContext: ReactApplicationContext): ReactContextBaseJavaModule(reactContext) {
    override fun getName() = "LinphoneModule"

    private val TAG = "LinphoneModule"
    private var core: Core = Factory.instance().createCore(null, null, reactApplicationContext)

    private val coreListener: CoreListener = object : CoreListenerStub( ) {
        override fun onCallStateChanged(
            core: Core,
            call: Call,
            state: Call.State?,
            message: String
        ) {
            Log.d(TAG, "onCallStateChanged: $state $message")

            val params = Arguments.createMap().apply {
                putString("state", state.toString())
                putString("message", message)
            }
            sendEvent(reactContext, "callstate", params)

            when (state) {
                Call.State.IncomingReceived -> {

                }

                Call.State.Idle -> TODO()
                Call.State.PushIncomingReceived -> TODO()
                Call.State.OutgoingInit -> TODO()
                Call.State.OutgoingProgress -> TODO()
                Call.State.OutgoingRinging -> TODO()
                Call.State.OutgoingEarlyMedia -> TODO()
                Call.State.Connected -> TODO()
                Call.State.StreamsRunning -> TODO()
                Call.State.Pausing -> TODO()
                Call.State.Paused -> TODO()
                Call.State.Resuming -> TODO()
                Call.State.Referred -> TODO()
                Call.State.Error -> TODO()
                Call.State.End -> TODO()
                Call.State.PausedByRemote -> TODO()
                Call.State.UpdatedByRemote -> TODO()
                Call.State.IncomingEarlyMedia -> TODO()
                Call.State.Updating -> TODO()
                Call.State.Released -> TODO()
                Call.State.EarlyUpdatedByRemote -> TODO()
                Call.State.EarlyUpdating -> TODO()
                null -> TODO()
            }
        }
    }

    /**
     * React Native Event Emitter
     * */

    private var listenerCount = 0;

    private fun sendEvent(reactContext: ReactApplicationContext, eventName: String, params: WritableMap) {
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java).emit(eventName, params)
    }

    @ReactMethod fun addListener(_eventName: String) {
        if( listenerCount == 0) core.addListener(coreListener)
        listenerCount += 1;
    }

    @ReactMethod fun removeListener() {
        listenerCount -= 1;
        if( listenerCount == 0) core.removeListener(coreListener)
    }

    @ReactMethod fun removeListeners() {
        listenerCount = 0;
        core.removeListener(coreListener)
    }

    /**
     * End of React native Event Emitter
     * */

    @ReactMethod fun register(username: String, password: String, domain: String, transport: String, promise: Promise) {
        val authInfo = Factory.instance().createAuthInfo(username, null, password, null, null, null);
        val accountParams = core.createAccountParams();

        val identity = Factory.instance().createAddress("sip:${username}@${domain}")
        accountParams.identityAddress = identity;

        val address = Factory.instance().createAddress("sip:${domain}")

        address?.transport = TransportType.valueOf(transport)
        accountParams.serverAddress = address
        accountParams.isRegisterEnabled = true

        val account = core.createAccount(accountParams)
        core.addAuthInfo(authInfo)
        core.addAccount(account)
        core.defaultAccount = account

        val listener = { _: Account, state: RegistrationState, message: String ->
            if (state !== RegistrationState.Ok && state !== RegistrationState.Progress) {
                promise.reject(state.toString(), message)
            } else if (state == RegistrationState.Ok) {
                promise.resolve("Registration successful")
            }
        }

        account.addListener(listener)
        core.start()
    }

    @ReactMethod fun unregister(promise: Promise) {
        val account = core.defaultAccount
        account ?: return

        val params = account.params
        val clonedParams = params.clone()

        clonedParams.isRegisterEnabled = false
        account.params = clonedParams

        account.addListener{ _, state, message ->
            if (state !== RegistrationState.Cleared && state !== RegistrationState.Progress) {
                promise.reject(state.toString(), message)
            } else if (state == RegistrationState.Cleared) {
                promise.resolve("Unregister successful")
            }
        }
    }

    @ReactMethod fun delete(promise: Promise) {
        val account = core.defaultAccount
        account ?: return

        core.removeAccount(account)

        promise.resolve("Delete successful")
    }

    @ReactMethod fun accept() {
        core.currentCall?.accept()
    }

    @ReactMethod fun terminate() {
        core.currentCall?.terminate()
    }

    @ReactMethod fun decline() {
        core.currentCall?.decline(Reason.Declined)
    }

    @ReactMethod fun call(address: String, promise: Promise) {
        val callParams = core.createCallParams(null)
        callParams ?: return promise.reject("call-creation", "Call params creation failed")

        callParams.mediaEncryption = MediaEncryption.SRTP

        val remoteAddress = Factory.instance().createAddress(address)
        remoteAddress ?: return promise.reject("call-creation", "Address creation failed")

        val call = core.inviteAddressWithParams(remoteAddress, callParams)

        if (call == null) {
            promise.reject("call-creation", "Call invite failed")
        } else {
            promise.resolve("Call successful")
        }
    }

    /**
     * Resolve um objeto com os dispositivos de áudio disponíveis e o id do dispositivo selecionado atualmente
     * */
    @ReactMethod fun getAudioDevices(promise: Promise){
        val values = Arguments.createArray()

        for (device in core.audioDevices) {
            val mappedDevice = Arguments.createMap()
            mappedDevice.putString("name", device.deviceName)
            mappedDevice.putString("driverName", device.driverName)
            mappedDevice.putString("id", device.id)
            mappedDevice.putString("type", device.type.toString())
            mappedDevice.putString("capabilities", device.capabilities.toString())
            values.pushMap(mappedDevice)
        }

        val returnedMap = Arguments.createMap()
        returnedMap.putArray("devices", values)
        returnedMap.putString("current", core.currentCall?.outputAudioDevice?.id)

        promise.resolve(returnedMap)
    }

    @ReactMethod fun setAudioDevice(id: String, promise: Promise) {
        if (core.currentCall == null) {
            promise.reject("no-call", "No current call")
            return
        }

        val newDevice = core.audioDevices.find{ it.id == id }
        if (newDevice == null) {
            promise.reject("no-device", "No device with $id found")
            return
        }
        if (newDevice.id == core.currentCall?.outputAudioDevice?.id) {
            return
        }

        core.currentCall!!.outputAudioDevice = core.audioDevices.find { it.id == id }
        promise.resolve("Set audio device successfully")
    }
}

