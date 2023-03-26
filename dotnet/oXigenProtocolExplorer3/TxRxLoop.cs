using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO.Ports;
using System.Linq;
using System.Threading;

namespace oXigenProtocolExplorer3
{
    public class TxRxLoop
    {
        private readonly short _txDelay;
        private readonly short _txTimeout;
        private readonly short _controllerTimeout;
        private readonly SerialPort _serialPort;

        private readonly OxigenTxPitlaneLapCounting _txPitlaneLapCounting = OxigenTxPitlaneLapCounting.disabled;
        private readonly OxigenTxPitlaneLapTrigger _txPitlaneLapTrigger = OxigenTxPitlaneLapTrigger.PitlaneEntry;
        private readonly OxigenTxRaceState _txRaceState = OxigenTxRaceState.Running;
        private readonly byte _maximumSpeed = 255;

        private readonly ConcurrentDictionary<byte, RxCarControllerPair> _rxCarControllerPairs = new();
        System.Threading.Timer? txTimeoutTimer;


        public TxRxLoop(string serialPortName,
                        short transmitDelay,
                        short transmitTimeout,
                        short controllerTimeout)
        {
            _txDelay = transmitDelay;
            _txTimeout = transmitTimeout;
            _controllerTimeout = controllerTimeout;

            _serialPort = new SerialPort(serialPortName);
            Console.WriteLine($"Opening {serialPortName}...");
            _serialPort.Open();
            _serialPort.DataReceived += _serialPort_Rx;
            _serialPort.ErrorReceived += _serialPort_ErrorReceived;
            _serialPort.WriteTimeout = transmitTimeout;
            Console.WriteLine($"{_serialPort.PortName} opened.");
        }


        public void Tx(object? state)
        {
            var disconnectedController = _rxCarControllerPairs
                .FirstOrDefault(x => x.Value.UpdatedAt.HasValue && x.Value.UpdatedAt < DateTime.Now.AddSeconds(-_controllerTimeout));
            if (disconnectedController.Key != 0)
            {
                _rxCarControllerPairs.Remove(disconnectedController.Key, out var dummy);
            }

            byte byte0 = 0;
            switch (_txRaceState)
            {
                case OxigenTxRaceState.Running:
                    byte0 = 0x3;
                    break;
                case OxigenTxRaceState.Paused:
                    byte0 = 0x4;
                    break;
                case OxigenTxRaceState.Stopped:
                    byte0 = 0x1;
                    break;
                case OxigenTxRaceState.FlaggedLcEnabled:
                    byte0 = 0x5;
                    break;
                case OxigenTxRaceState.FlaggedLcDisabled:
                    byte0 = 0x15;
                    break;
            }

            switch (_txPitlaneLapCounting)
            {
                case OxigenTxPitlaneLapCounting.enabled:
                    break;
                case OxigenTxPitlaneLapCounting.disabled:
                    byte0 |= 2 ^ 5;
                    break;
            }

            if (_txPitlaneLapCounting == OxigenTxPitlaneLapCounting.enabled)
            {
                switch (_txPitlaneLapTrigger)
                {
                    case OxigenTxPitlaneLapTrigger.PitlaneEntry:
                        break;
                    case OxigenTxPitlaneLapTrigger.PitlaneExit:
                        byte0 |= 2 ^ 6;
                        break;
                }
            }

            var buffer = new byte[] { byte0, _maximumSpeed, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

            _serialPort.Write(buffer, 0, buffer.Length);

            if (txTimeoutTimer is not null)
            {
                txTimeoutTimer.Dispose();
            }
            txTimeoutTimer = new Timer(Tx, null, _txTimeout, Timeout.Infinite);
        }


        private void _serialPort_Rx(object sender, SerialDataReceivedEventArgs e)
        {
            try
            {
                var buffer = new byte[_serialPort.ReadBufferSize];
                var bytesRead = _serialPort.Read(buffer, 0, _serialPort.BytesToRead);
                Console.WriteLine($"{bytesRead} bytes received.");
                if (bytesRead == 5)
                {
                    Console.WriteLine($"Dongle firmware: {buffer[0] + buffer[1] / 100}");
                }
                else if ( bytesRead > 0 && bytesRead % 13 == 0)
                {
                    var offset = 0;
                    do
                    {
                        var id = buffer[1 + offset];

                        OxigenRxCarReset? oldCarReset = null;
                        OxigenRxControllerCarLink? oldControllerCarLink = null;
                        if (_rxCarControllerPairs.TryGetValue(id, out var rxCarControllerPair))
                        {
                            oldCarReset = rxCarControllerPair.CarReset;
                            oldControllerCarLink = rxCarControllerPair.ControllerCarLink;
                        }
                        else
                        {
                            rxCarControllerPair = new();
                            _rxCarControllerPairs.TryAdd(id, rxCarControllerPair);
                        }

                        if ((buffer[0 + offset] & (2 ^ 0)) == 0)
                        {
                            rxCarControllerPair.CarReset = OxigenRxCarReset.CarPowerSupplyHasntChanged;
                        }
                        else
                        {
                            rxCarControllerPair.CarReset = OxigenRxCarReset.CarHasJustBeenPoweredUpOrReset;
                        }
                        if (rxCarControllerPair.CarReset == OxigenRxCarReset.CarHasJustBeenPoweredUpOrReset &&
                            oldCarReset is not null &&
                            oldCarReset.Value != rxCarControllerPair.CarReset)
                        {
                            rxCarControllerPair.CarResetCount++;
                        }

                        if ((buffer[0 + offset] & (2 ^ 1)) == 0)
                        {
                            rxCarControllerPair.ControllerCarLink =
                                OxigenRxControllerCarLink.ControllerLinkWithItsPairedCarHasntChanged;
                        }
                        else
                        {
                            rxCarControllerPair.ControllerCarLink =
                                OxigenRxControllerCarLink.ControllerHasJustGotTheLinkWithItsPairedCar;
                        }
                        if (rxCarControllerPair.ControllerCarLink == OxigenRxControllerCarLink.ControllerHasJustGotTheLinkWithItsPairedCar &&
                            oldControllerCarLink is not null &&
                            oldControllerCarLink.Value != rxCarControllerPair.ControllerCarLink)
                        {
                            rxCarControllerPair.ControllerCarLinkCount++;
                        }

                        if ((buffer[0 + offset] & (2 ^ 2)) == 0)
                        {
                            rxCarControllerPair.ControllerBatteryLevel = OxigenRxControllerBatteryLevel.OK;
                        }
                        else
                        {
                            rxCarControllerPair.ControllerBatteryLevel = OxigenRxControllerBatteryLevel.Low;
                        }

                        if ((buffer[0 + offset] & (2 ^ 3)) == 0)
                        {
                            rxCarControllerPair.TrackCall = OxigenRxTrackCall.No;
                        }
                        else
                        {
                            rxCarControllerPair.TrackCall = OxigenRxTrackCall.Yes;
                        }

                        if ((buffer[0 + offset] & (2 ^ 5)) == 0)
                        {
                            rxCarControllerPair.ArrowUpButton = OxigenRxArrowUpButton.ButtonNotPressed;
                        }
                        else
                        {
                            rxCarControllerPair.ArrowUpButton = OxigenRxArrowUpButton.ButtonPressed;
                        }

                        if ((buffer[0 + offset] & (2 ^ 6)) == 0)
                        {
                            rxCarControllerPair.ArrowDownButton = OxigenRxArrowDownButton.ButtonNotPressed;
                        }
                        else
                        {
                            rxCarControllerPair.ArrowDownButton = OxigenRxArrowDownButton.ButtonPressed;
                        }

                        if ((buffer[7 + offset] & (2 ^ 7)) == 0)
                        {
                            rxCarControllerPair.CarOnTrack = OxigenRxCarOnTrack.CarIsNotOnTheTrack;
                        }
                        else
                        {
                            rxCarControllerPair.CarOnTrack = OxigenRxCarOnTrack.CarIsOnTheTrack;
                        }

                        if ((buffer[8 + offset] & (2 ^ 6)) == 0)
                        {
                            rxCarControllerPair.CarPitLane = OxigenRxCarPitLane.CarIsNotInThePitLane;
                        }
                        else
                        {
                            rxCarControllerPair.CarPitLane = OxigenRxCarPitLane.CarIsInThePitLane;
                        }

                        rxCarControllerPair.TriggerMeanValue = Convert.ToByte(buffer[7 + offset] & 0x7F);
                        rxCarControllerPair.DongleLapTime = Convert.ToInt16(buffer[2 + offset] * 256 + buffer[3 + offset]);
                        rxCarControllerPair.DongleLapTimeDelay = buffer[4 + offset];
                        rxCarControllerPair.DongleLaps = Convert.ToInt16(buffer[6 + offset] * 256 + buffer[5 + offset]);

                        OxigenRxDeviceSoftwareReleaseOwner deviceSoftwareReleaseOwner;
                        if ((buffer[8 + offset] & (2 & 7)) == 0)
                        {
                            deviceSoftwareReleaseOwner = OxigenRxDeviceSoftwareReleaseOwner.ControllerSoftwareRelease;
                        }
                        else
                        {
                            deviceSoftwareReleaseOwner = OxigenRxDeviceSoftwareReleaseOwner.CarSoftwareRelease;
                        }

                        var softwareRelease =
                            (buffer[8 + offset] & 48) / 16 + (buffer[0 + offset] & 16) / 100 + (buffer[8 + offset] & 15) / 100;

                        switch (deviceSoftwareReleaseOwner)
                        {
                            case OxigenRxDeviceSoftwareReleaseOwner.ControllerSoftwareRelease:
                                rxCarControllerPair.ControllerFirmwareVersion = softwareRelease;
                                break;
                            case OxigenRxDeviceSoftwareReleaseOwner.CarSoftwareRelease:
                                rxCarControllerPair.CarFirmwareVersion = softwareRelease;
                                break;
                        }

                        rxCarControllerPair.DongleRaceTimer = buffer[9 + offset] * 16777216 +
                            buffer[10 + offset] * 65536 +
                            buffer[11 + offset] * 256 +
                            buffer[12 + offset];

                        rxCarControllerPair.DongleLapRaceTimer =
                            rxCarControllerPair.DongleRaceTimer - rxCarControllerPair.DongleLapTimeDelay;

                        rxCarControllerPair.DongleLapTimeSeconds = rxCarControllerPair.DongleLapTime / 99.25;

                        if (rxCarControllerPair.PreviousLapRaceTimer == null)
                        {
                            if (rxCarControllerPair.DongleRaceTimer == 0)
                            {
                                rxCarControllerPair.PreviousLapRaceTimer = 0;
                            }
                        }
                        else if (rxCarControllerPair.DongleRaceTimer > 0)
                        {
                            if (rxCarControllerPair.PreviousLapRaceTimer != rxCarControllerPair.DongleLapRaceTimer)
                            {
                                if (rxCarControllerPair.CalculatedLaps == null)
                                {
                                    rxCarControllerPair.CalculatedLaps = 0;
                                }
                                else
                                {
                                    rxCarControllerPair.CalculatedLaps = rxCarControllerPair.CalculatedLaps++;
                                    if (rxCarControllerPair.PreviousLapRaceTimer is not null)
                                    {
                                        rxCarControllerPair.CalculatedLapTimeSeconds =
                                            (rxCarControllerPair.DongleLapRaceTimer - rxCarControllerPair.PreviousLapRaceTimer) / 100.0;

                                        if (rxCarControllerPair.FastestLapTime is null ||
                                            rxCarControllerPair.FastestLapTime > rxCarControllerPair.CalculatedLapTimeSeconds)
                                        {
                                            rxCarControllerPair.FastestLapTime = rxCarControllerPair.CalculatedLapTimeSeconds;
                                        }
                                    }
                                }
                                rxCarControllerPair.PreviousLapRaceTimer = rxCarControllerPair.DongleLapRaceTimer;
                            }
                        }

                        var now = DateTime.Now;
                        if (rxCarControllerPair.UpdatedAt.HasValue)
                        {
                            rxCarControllerPair.RefreshRate = now - rxCarControllerPair.UpdatedAt;
                        }
                        rxCarControllerPair.UpdatedAt = now;

                        if (!rxCarControllerPair.RefreshRate.HasValue)
                        {
                            Console.WriteLine($"Id={id}");
                        }
                        else
                        {
                            Console.WriteLine($"Id={id}, Refresh rate={rxCarControllerPair.RefreshRate.Value.TotalMilliseconds}ms");
                        }

                        offset += 13;
                    } while (offset < bytesRead - 1);
                }
            }
            catch (Exception exception)
            {
                Console.WriteLine(exception.Message);
            }

            _ = new Timer(Tx, null, _txDelay, Timeout.Infinite);
        }


        private void _serialPort_ErrorReceived(object sender, SerialErrorReceivedEventArgs e)
        {
            Console.WriteLine(e.EventType);
        }
    }
}
