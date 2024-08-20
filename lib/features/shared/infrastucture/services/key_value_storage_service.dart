abstract class KeyValueStorageService{
Future<void> setKeyValue(String key, dynamic value);
Future getValue (String key);
Future<bool> removeKey(String key);

}