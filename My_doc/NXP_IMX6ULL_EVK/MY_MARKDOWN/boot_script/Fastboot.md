# Fastboot

[Fastboot](https://en.wikipedia.org/wiki/Fastboot) is a protocol originally created for Android, which is used primarily to modify the flash filesystem via a USB connection from a host computer.

Most Android systems run a bootloader that implements the fastboot protocol, and therefore can be reflashed from a host computer running the corresponding `fastboot` tool. It sounded like a good candidate for the second step of our factory flashing process, to actually flash the different parts of our system.