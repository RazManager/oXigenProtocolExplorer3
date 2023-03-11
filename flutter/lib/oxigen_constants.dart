enum OxigenTxPitlaneLapCounting { enabled, disabled }

enum OxigenTxPitlaneLapTrigger { pitlaneEntry, pitlaneExit }

enum OxigenTxRaceStatus { running, paused, stopped, flaggedLcEnabled, flaggedLcDisabled }

enum OxigenRxCarReset {
  carPowerSupplyHasntChanged,
  carHasJustBeenPoweredUpOrReset // (info available for 2 seconds)
}

enum OxigenRxControllerCarLink {
  controllerLinkWithItsPairedCarHasntChanged,
  controllerHasJustGotTheLinkWithItsPairedCar // (info available for2 seconds) (e.g.:link dropped and restarted)
}

enum OxigenRxControllerBatteryLevel { ok, low }

enum OxigenRxTrackCall {
  no,
  yes // (info available for 2 seconds)
}

enum OxigenRxArrowUpButton { buttonNotPressed, buttonPressed }

enum OxigenRxArrowDownButton { buttonNotPressed, buttonPressed }

enum OxigenRxCarOnTrack {
  carIsNotOnTheTrack,
  carIsOnTheTrack // Info available only if the paired controller is powered up
}

enum OxigenRxCarPitLane { carIsNotInThePitLane, carIsInThePitLane }
