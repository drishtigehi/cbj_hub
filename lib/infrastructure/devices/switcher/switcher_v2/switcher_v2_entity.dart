import 'dart:async';

import 'package:cbj_hub/domain/generic_devices/abstract_device/core_failures.dart';
import 'package:cbj_hub/domain/generic_devices/abstract_device/device_entity_abstract.dart';
import 'package:cbj_hub/domain/generic_devices/abstract_device/value_objects_core.dart';
import 'package:cbj_hub/domain/generic_devices/device_type_enums.dart';
import 'package:cbj_hub/domain/generic_devices/generic_boiler_device/generic_boiler_entity.dart';
import 'package:cbj_hub/domain/generic_devices/generic_boiler_device/generic_boiler_value_objects.dart';
import 'package:cbj_hub/infrastructure/devices/switcher/switcher_api/switcher_api_object.dart';
import 'package:cbj_hub/infrastructure/devices/switcher/switcher_device_value_objects.dart';
import 'package:cbj_hub/infrastructure/gen/cbj_hub_server/protoc_as_dart/cbj_hub_server.pbgrpc.dart';
import 'package:cbj_hub/utils.dart';
import 'package:dartz/dartz.dart';

class SwitcherV2Entity extends GenericBoilerDE {
  SwitcherV2Entity({
    required CoreUniqueId uniqueId,
    required VendorUniqueId vendorUniqueId,
    required DeviceDefaultName defaultName,
    required DeviceState deviceStateGRPC,
    required DeviceStateMassage stateMassage,
    required DeviceSenderDeviceOs senderDeviceOs,
    required DeviceSenderDeviceModel senderDeviceModel,
    required DeviceSenderId senderId,
    required DeviceCompUuid compUuid,
    required DevicePowerConsumption powerConsumption,
    required GenericBoilerSwitchState boilerSwitchState,
    required this.switcherMacAddress,
    required this.lastKnownIp,
    required this.switcherPort,
  }) : super(
          uniqueId: uniqueId,
          vendorUniqueId: vendorUniqueId,
          defaultName: defaultName,
          deviceStateGRPC: deviceStateGRPC,
          stateMassage: stateMassage,
          senderDeviceOs: senderDeviceOs,
          senderDeviceModel: senderDeviceModel,
          senderId: senderId,
          deviceVendor:
              DeviceVendor(VendorsAndServices.switcherSmartHome.toString()),
          compUuid: compUuid,
          powerConsumption: powerConsumption,
          boilerSwitchState: boilerSwitchState,
        ) {
    switcherObject = SwitcherApiObject(
      deviceType: SwitcherDevicesTypes.switcherV2Esp,
      deviceId: vendorUniqueId.getOrCrash(),
      switcherIp: lastKnownIp.getOrCrash(),
      switcherName: defaultName.getOrCrash()!,
      macAddress: switcherMacAddress.getOrCrash(),
      powerConsumption: powerConsumption.getOrCrash(),
    );
  }

  SwitcherMacAddress switcherMacAddress;

  /// Switcher communication port
  SwitcherPort? switcherPort;

  DeviceLastKnownIp lastKnownIp;

  /// Switcher package object require to close previews request before new one
  SwitcherApiObject? switcherObject;

  String? autoShutdown;
  String? electricCurrent;
  String? lastDataUpdate;
  String? macAddress;
  String? remainingTime;

  /// Please override the following methods
  @override
  Future<Either<CoreFailure, Unit>> executeDeviceAction({
    required DeviceEntityAbstract newEntity,
  }) async {
    if (newEntity is! GenericBoilerDE) {
      return left(
        const CoreFailure.actionExcecuter(
          failedValue: 'Not the correct type',
        ),
      );
    }

    if (newEntity.boilerSwitchState!.getOrCrash() !=
            boilerSwitchState!.getOrCrash() ||
        deviceStateGRPC.getOrCrash() != DeviceStateGRPC.ack.toString()) {
      final DeviceActions? actionToPreform = EnumHelper.stringToDeviceAction(
        newEntity.boilerSwitchState!.getOrCrash(),
      );

      if (actionToPreform == DeviceActions.on) {
        (await turnOnBoiler()).fold(
          (l) {
            logger.e('Error turning boiler on');
            deviceStateGRPC =
                DeviceState(DeviceStateGRPC.newStateFailed.toString());
          },
          (r) {
            logger.i('Boiler turn on success');
            deviceStateGRPC = DeviceState(DeviceStateGRPC.ack.toString());
          },
        );
      } else if (actionToPreform == DeviceActions.off) {
        (await turnOffBoiler()).fold(
          (l) {
            logger.e('Error turning boiler off');
            deviceStateGRPC =
                DeviceState(DeviceStateGRPC.newStateFailed.toString());
          },
          (r) {
            logger.i('Boiler turn off success');
            deviceStateGRPC = DeviceState(DeviceStateGRPC.ack.toString());
          },
        );
      } else {
        logger.e('actionToPreform is not set correctly on Switcher V2');
      }
    }

    return right(unit);
  }

  @override
  Future<Either<CoreFailure, Unit>> turnOnBoiler() async {
    boilerSwitchState = GenericBoilerSwitchState(DeviceActions.on.toString());

    try {
      await switcherObject!.turnOn();
      return right(unit);
    } catch (e) {
      return left(const CoreFailure.unexpected());
    }
  }

  @override
  Future<Either<CoreFailure, Unit>> turnOffBoiler() async {
    boilerSwitchState = GenericBoilerSwitchState(DeviceActions.off.toString());

    try {
      await switcherObject!.turnOff();
      return right(unit);
    } catch (e) {
      return left(const CoreFailure.unexpected());
    }
  }
}
