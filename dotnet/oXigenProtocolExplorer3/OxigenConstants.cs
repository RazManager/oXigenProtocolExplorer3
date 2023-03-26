using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace oXigenProtocolExplorer3
{

    public enum OxigenTxPitlaneLapCounting
    {
        enabled,
        disabled
    }

    public enum OxigenTxPitlaneLapTrigger
    {
        PitlaneEntry,
        PitlaneExit
    }

    public enum OxigenTxRaceState
    {
        Running,
        Paused,
        Stopped,
        FlaggedLcEnabled,
        FlaggedLcDisabled
    }

    public enum OxigenTxTransmissionPower
    {
        dBm18,
        dBm12,
        dBm6,
        dBm0
    }

    public enum OxigenTxCommand
    {
        MaximumSpeed,
        MinimumSpeed,
        PitlaneSpeed,
        MaximumBrake,
        ForceLcUp,
        ForceLcDown,
        TransmissionPower
    }

    public enum OxigenRxCarReset
    {
        CarPowerSupplyHasntChanged,
        CarHasJustBeenPoweredUpOrReset // (info available for 2 seconds)
    }

    public enum OxigenRxControllerCarLink
    {
        ControllerLinkWithItsPairedCarHasntChanged,
        ControllerHasJustGotTheLinkWithItsPairedCar // (info available for2 seconds) (e.g.:link dropped and restarted)
    }

    public enum OxigenRxControllerBatteryLevel
    {
        OK,
        Low
    }

    public enum OxigenRxTrackCall
    {
        No,
        Yes // (info available for 2 seconds)
    }

    public enum OxigenRxArrowUpButton
    {
        ButtonNotPressed,
        ButtonPressed
    }

    public enum OxigenRxArrowDownButton
    {
        ButtonNotPressed,
        ButtonPressed
    }

    public enum OxigenRxCarOnTrack
    {
        CarIsNotOnTheTrack,
        CarIsOnTheTrack // Info available only if the paired controller is powered up
    }

    public enum OxigenRxCarPitLane
    {
        CarIsNotInThePitLane,
        CarIsInThePitLane
    }

    public enum OxigenRxDeviceSoftwareReleaseOwner
    {
        ControllerSoftwareRelease,
        CarSoftwareRelease
    }
}
