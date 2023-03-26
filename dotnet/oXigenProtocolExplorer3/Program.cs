using oXigenProtocolExplorer3;
using System;
using System.IO.Ports;
using System.Linq;


string serialPortName = null!;
short txDelay = 500;
short txTimeout = 2000;
short controllerTimeout = 30;

var serialPortNames = SerialPort.GetPortNames().OrderBy(x => x);
if (!serialPortNames.Any())
{
    Console.WriteLine("There are no serial ports.");
    return;
}
foreach (var serialPort in serialPortNames.Select((x, i) => new { index = i, serialPortName = x }))
{
    Console.WriteLine($" {serialPort.index + 1}. {serialPort.serialPortName}");
}

Console.Write("Please select a serial port: ");
var selectedSerialPortIndexString = Console.ReadLine();
if (string.IsNullOrWhiteSpace(selectedSerialPortIndexString))
{
    return;
}
if (!byte.TryParse(selectedSerialPortIndexString, out var selectedSerialPortIndex))
{
    return;
}
if (selectedSerialPortIndex < 1 || selectedSerialPortIndex > serialPortNames.Count())
{
    return;
}
serialPortName = serialPortNames.ElementAt(selectedSerialPortIndex - 1);

Console.Write("Please select a transmit delay (ms) (default 500ms): ");
var txDelayString = Console.ReadLine();
if (!string.IsNullOrWhiteSpace(txDelayString))
{
    if (!short.TryParse(txDelayString, out txDelay))
    {
        return;
    }
}

if (txDelay >= txTimeout)
{
    return;
}

var txRxLoop = new TxRxLoop(serialPortName, txDelay, txTimeout, controllerTimeout);
txRxLoop.Tx(null);

Console.ReadLine();