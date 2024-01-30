import {NativeEventEmitter, NativeModules} from 'react-native';
const {LinphoneModule} = NativeModules;

interface RegisterConfig {
  username: string;
  password: string;
  domain: string;
  transport?: 'Udp' | 'Tcp' | 'Tls';
}

export const callEvents = new NativeEventEmitter(LinphoneModule);

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
