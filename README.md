# oXigen Protocol Explorer 3

"oXigen Protocol Explorer 3" is a little tool that developers can use to better understand the oXigen 3.X dongle protocol.
I.e, the protocol that is used by slot.it's digital slot car system between a dongle and an RMS program.


## Hardware and software requirements

- An oXigen 3.X dongle.
- A computer/device capable of running a 64-bit desktop version of Windows 7/8/10/11, MacOS or Linux. A Raspberry Pi will work, but it needs at least 1GB RAM.


## Installation

As this is a simple developement tool, it's not available from an app store, i.e. from the Microsoft Store, from Apple's app store, or as a Linux snap.
Instead, download a version for your operating system from the release page (link to the right), extract the compressed file, and start the excecutable file.


### Windows

After extracting the .zip file, simply start oxigen_protocol_explorer_3.exe. You'll get a warning that you're trying to run a file from an untrusted source.
Click on "more information" (or similar), and accept to run it anyway.


### MacOS

After extracting the .zip file, simply start oxigen_protocol_explorer_3.app. You'll get a warning that you're trying to run a file from an untrusted source.
It's a bit complicated to get around this in MacOS, but by **very** carefully following the warning instructions, you should be able to start it.


### Linux

On RaspBerry Pi OS, extract the compressed file and you should then be able to start oxigen_protocol_explorer_3.

On Ubuntu, it's a bit more complicated, as your user account typically doesn't have access to the serial port (it's not a member of the dialup group).
The easiest to solve this is by running the program as root:

<code>sudo ./oxigen_protocol_explorer_3</code>

On Ubuntu on a RaspBerry Pi, you might get the following error:

<code>Failed to start Flutter renderer: Unable to create a GL context</code>

It's caused by missing graphic drivers, and the easiest way to run the program anyway is to add an environment variable so that software rendering is used instead:

<code>export LIBGL_ALWAYS_SOFTWARE=1</code>
