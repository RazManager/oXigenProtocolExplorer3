using System;
using static System.Runtime.InteropServices.JavaScript.JSType;


namespace oXigenProtocolExplorer3
{
    public class RxCarControllerPair
    {
        public OxigenRxCarReset CarReset { get; set; }
        public int CarResetCount { get; set; } = 0;
        public OxigenRxControllerCarLink ControllerCarLink { get; set; }
        public int ControllerCarLinkCount { get; set; } = 0;
        public OxigenRxControllerBatteryLevel ControllerBatteryLevel { get; set; }
        public OxigenRxTrackCall TrackCall { get; set; }
        public OxigenRxArrowUpButton ArrowUpButton { get; set; }
        public OxigenRxArrowDownButton ArrowDownButton { get; set; }
        public OxigenRxCarOnTrack CarOnTrack { get; set; }
        public OxigenRxCarPitLane CarPitLane { get; set; }
        public byte TriggerMeanValue { get; set; }
        public int DongleRaceTimer { get; set; }
        public int DongleLapRaceTimer { get; set; }
        public short DongleLapTime { get; set; }
        public double DongleLapTimeSeconds { get; set; }
        public byte DongleLapTimeDelay { get; set; }
        public short DongleLaps { get; set; }
        public int? PreviousLapRaceTimer { get; set; }
        public double? CalculatedLapTimeSeconds { get; set; }
        public short? CalculatedLaps { get; set; }
        public double? ControllerFirmwareVersion { get; set; }
        public double? CarFirmwareVersion { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public TimeSpan? RefreshRate { get; set; }
    }
}
