import 'package:cbj_hub/domain/node_red/i_node_red_repository.dart';
import 'package:cbj_hub/domain/scene/i_scene_cbj_repository.dart';
import 'package:cbj_hub/domain/scene/scene_cbj.dart';
import 'package:cbj_hub/infrastructure/node_red/node_red_api/node_red_api.dart';
import 'package:cbj_hub/injection.dart';
import 'package:cbj_hub/utils.dart';
import 'package:http/src/response.dart';
import 'package:injectable/injectable.dart';

/// Control Node-RED, create scenes and more
@LazySingleton(as: INodeRedRepository)
class NodeRedRepository extends INodeRedRepository {
  static NodeRedAPI nodeRedAPI = NodeRedAPI();

  /// List of all the scenes JSONs in Node-RED
  List<String> scenesList = [];

  /// List of all the routines JSONs in Node-RED
  List<String> routinesList = [];

  /// List of all the bindings JSONs in Node-RED
  List<String> bindingsList = [];

  @override
  Future<void> createNewNodeRedScene(SceneCbj sceneCbj) async {
    final Response response = await nodeRedAPI.postFlow(
      label: sceneCbj.name,
      nodes: sceneCbj.automationString!,
    );
    if (response.statusCode == 200) {
      getIt<ISceneCbjRepository>().addNewScene(sceneCbj);
    }
    logger.i('Response\n${response.statusCode}');
  }

  /// Get entity and return the full MQTT path to it
  Future<String> genericDeviceEntityToMqttPath() async {
    throw 'Not implemented';
  }

  @override
  Future<Map<String, SceneCbj>> getAllNodeRedScenes() async {
    return getIt<ISceneCbjRepository>().getAllScenesAsMap();
  }
}
