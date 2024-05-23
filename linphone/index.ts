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
