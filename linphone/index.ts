import {useEffect, useState} from 'react';
import {
  EmitterSubscription,
  NativeEventEmitter,
  NativeModules,
} from 'react-native';
const {LinphoneModule} = NativeModules;

interface RegisterConfig {
  username: string;
  password: string;
  domain: string;
  transport?: 'Udp' | 'Tcp' | 'Tls';
}

type CallState =
  | 'Idle'
  | 'IncomingReceived'
  | 'PushIncomingReceived'
  | 'OutgoingInit'
  | 'OutgoingProgress'
  | 'OutgoingRinging'
  | 'OutgoingEarlyMedia'
  | 'Connected'
  | 'StreamsRunning'
  | 'Pausing'
  | 'Paused'
  | 'Resuming'
  | 'Referred'
  | 'Error'
  | 'End'
  | 'PausedByRemote'
  | 'UpdatedByRemote'
  | 'IncomingEarlyMedia'
  | 'Updating'
  | 'Released'
  | 'EarlyUpdatedByRemote'
  | 'EarlyUpdating';

type CallEvent = {
  state: CallState;
  message: string;
};

type AudioDevice = {
  id: string;
  name: string;
  driverName: string;
  capabilities: 'CapabilityRecord' | 'CapabilityPlay' | 'CapabilityAll';
  type:
    | 'Unknown'
    | 'Microphone'
    | 'Earpiece'
    | 'Speaker'
    | 'Bluetooth'
    | 'BluetoothA2DP'
    | 'Telephony'
    | 'AuxLine'
    | 'GenericUsb'
    | 'Headset'
    | 'Headphones'
    | 'HearingAid';
};

class CallEvents extends NativeEventEmitter {
  constructor() {
    super(LinphoneModule);
  }

  addListener(
    eventType: 'callstate',
    listener: (event: CallEvent) => void,
    context?: Object | undefined,
  ): EmitterSubscription {
    return super.addListener(eventType, listener, context);
  }

  emit(eventType: string, ...params: any[]): void {
    return super.emit(eventType, ...params);
  }

  listenerCount(eventType: string): number {
    return super.listenerCount(eventType);
  }

  removeAllListeners(eventType: string): void {
    return super.removeAllListeners(eventType);
  }
}

export const callEvents = new CallEvents();

export function register(config: RegisterConfig): Promise<void> {
  return LinphoneModule.register(
    config.username,
    config.password,
    config.domain,
    config.transport ?? 'Udp',
  );
}

export function unregister(): Promise<void> {
  return LinphoneModule.unregister();
}

export function deleteAccount(): Promise<void> {
  return LinphoneModule.delete();
}

export function accept(): Promise<void> {
  return LinphoneModule.accept();
}

export function decline(): Promise<void> {
  return LinphoneModule.decline();
}

export function call(address: string): Promise<void> {
  console.log('calling');
  return LinphoneModule.call(address);
}

export function terminate(): Promise<void> {
  return LinphoneModule.terminate();
}

export function getAudioDevices(): Promise<{
  devices: AudioDevice[];
  current: string;
}> {
  return LinphoneModule.getAudioDevices();
}

export function setAudioDevice(deviceId: string): Promise<void> {
  return LinphoneModule.setAudioDevice(deviceId);
}

export function useOutputAudioDevices() {
  const [devices, setDevices] = useState<AudioDevice[]>([]);
  const [current, setCurrent] = useState<string>('');

  useEffect(() => {
    const sub = callEvents.addListener('callstate', data => {
      switch (data.state) {
        case 'StreamsRunning':
        case 'Connected':
        case 'IncomingReceived':
        case 'OutgoingInit':
        case 'Idle':
          getAudioDevices().then(result => {
            setDevices(result.devices.filter(d => d.type !== 'Microphone'));
            setCurrent(result.current);
          });
          break;
        default:
          console.log('state', data.state);
      }

      return sub.remove;
    });
  }, []);

  return {devices, current};
}
