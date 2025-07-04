enum PluginType { cityMap, nftPack, uiMod, pvpRule }

class PluginManifest {
  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final PluginType pluginType;
  final String entrypoint;
  final List<String> permissions;
  final List<String> assets;

  PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    required this.pluginType,
    required this.entrypoint,
    required this.permissions,
    required this.assets,
  });
}
