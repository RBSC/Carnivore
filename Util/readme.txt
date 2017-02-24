Carnivore MultiFlash SCC Cartridge version 1.1
Copyright (c) 2016 RBSC

The Setup
---------

After assembling, the cartridge needs to be programmed in order to function properly. The following steps are necessary:

 1. Upload the Altera's firmware
 2. Initialize the directory
 3. Write the Boot Block
 4. Restart MSX


How to upload the firmware
--------------------------

Before uploading the firmware please make sure that your MSX boots fine with the inserted cartridge!

 1. Solder jumper pins to the "+5v" and "GND" soldering points (or solder wires to both sides of C1 capacitor)
 2. Prepare the ByteBlaster 2 programmer, open the Quartus II software
 3. In the Quartus user interface select "JTAG" mode for your ByteBlaster 2
 4. Supply 5v power to the cartridge board (mind the correct polarity!)
 5. Connect the ByteBlaster's cable to the JTAG socket of the cartridge (make sure you connect the cable correctly!)
 6. Use "Autodetect" button to detect your Altera chip
 7. Rightclick on the added device's string and select "Change File"
 8. Select the .POF file from the "Firmware" directory
 9. Enable the checkboxes: "Program/Configure", "Verify" and "Blank Check"
10. Click "Start" and monitor the programming and verification process

If the programming completed successfully, disconnect the ByteBlaster's cable and 5v power from the board.


How to enable the cartridge and install Boot Block
--------------------------------------------------

Insert the cartridge into the MSX slot, preferably into the first main slot. Power up MSX and check if it functions
normally. If the machine shows an anomaly, remove and inspect the cartridge. To fully set up the cartridge the
following needs to be done:

 1. Make sure that the BOOTCSCC.BIN file is in the same folder with the utilities
 2. Run the "cman.com" or "cman_40.com" (for MSX1 only) utility
 3. When asked, enter the slot number where the cartridge is inserted (for example "1" for first slot, "2" for second slot, etc.)
 4. From the main menu select "Open cartridge's Service Menu" using the "9" key
 5. With the "7" key select "Fully erase FlashROM chip" and confirm twice
 6. With the "3" key select "Init/Erase all directory entries" to initialize the directory
 7. With the "4" key select "Write Boot Block (bootcscc.bin)" to write the Boot Block
 8. If there were no errors during the steps 5-7, then power down and start your MSX


How to work with Boot Block
---------------------------

The Boot Block allows to start the ROMs from the flash chip and to restart the cartridge with the desired configuration.
After MSX shows its boot logo, the cartridge's boot block should start and you should see the menu. Navigating the menu is very
easy. Here are the key assignments:

 [ESC] - boot MSX using the default configuration
 [LEFT],[RIGHT] - previous/next directory page
 [UP],[DOWN] - select ROM/CFG entry
 [SPACE]     - start entry normally
 [SHIFT]+[G] - start entry directly (using the jump address of the ROM)
 [SHIFT]+[R] - reset and start entry
 [SHIFT]+[A] - entry's autostart ON
 [SHIFT]+[D] - entry's autostart OFF

Please keep in mind that some ROMs may require alternative starting method, so if pressing SPACE doesn't start the ROM, try
using the direct start or start after system's reset.

When you enable the autostart for an entry, it will be always activated after MSX's boot logo. The Boot Block menu will not be
shown and the ROM or configuration entry will be started automatically. In order to disable the autostart or to skip the boot
block completely the following keys should be used:

	[TAB] - disable autostart option
	[F5]  - disable startup menu


CMAN and CMAN_40 utilities
--------------------------

The CMAN utility allows to initialize the cartridge, add ROMs into the FlashROM, edit the cartridge's directory. The CMAN_40
utility is for MSX1 computers using the 40 character wide display, the CMAN utility is for MSX2 and later computers.

The utility supports the following command line options:

 cman [filename.rom] [/h] [/v] [/a] [/su]

 /h  - help screen
 /v  - verbose mode (show detailed information)
 /a  - automatically detect and write ROM image (no user interaction needed)
 /su - enable Super User mode (allows editing all registers: this is RISKY!)

The utility is normally able to find the inserted cartridge by itself. If the utility can't find the cartridge, you will need
to input the slot number manually and press Enter. The slot number is "1" for first slot, "2" for second slot, and so on.

The main menu allows to:

 - Write new ROM image into FlashROM
 - Browse/edit cartridge's directory

The menu options should be selected with the corresponding numeric buttons.


Adding a ROM file into the FlashROM
-----------------------------------

To add a new ROM file into the FlashROM chip, select the "Write new ROM image into FlashROM" option. Follow the on-screen instructions
until the ROM is successfully written into the chip and the main menu re-appears. The large ROMs' mapper should be normally
detected automatically by the utility, but on some ROMs autodetecting may fail. In this case the utility will ask you to choose the
mapper. The ROM will not start with incorrect mapper settings, so if your setting didn't work, try to change the mapper type.

The FlashROM chip contains 128 blocks by 64kb (8mb in total). The first block is occupied by the Boot Block and cartridge's directory.
Other blocks are available for a user to add the ROMs. The ROMs that are smaller than 64kb are grouped into one block. For example two 32kb
ROMs will be written into the same 64kb block, eight 8kb ROMs will be grouped into the same 64kb block and finally four 16kb ROMs will be
grouped written into the same 64kb block. All this is done automatically.

You can add a ROM into the chip without user interaction. The following command line should be used:

 CMAN file.rom /a

The utility will try to automatically detect the ROM's mapper, check whether any free space is available and then it will write the
selected ROM into the FlashROM chip. If you add the "/v" option, the utility will show additional information about the chip and the
ROM that is being added as well as the map of the free chip's blocks.

The map of FlashROM chip blocks can be viewed from the Service Menu. Just select the "Show FlashROM chip's block usage" option.


Editing or deleting directory entries
-------------------------------------
 
To edit the cartridge's directory select the "Browse/edit cartridge's directory" option. This will open the screen with the list of
directory entries, 10 per page. The key assignment is similar to the boot block with the exception that you can't start the entry.
An entry can be edited or deleted. Follow the on-screen instructions for editing a directory entry. Please keep in mind that the very
first entry called "DefConfig: SCC cartridge" can't be deleted.

In the directory editor you can change almost all fields of an entry, select a different mapper, reset options and so on. The editor
has the context based help that is displayed at the bottom of the screen.

With the Super User mode you can edit any register you want, but be advised, that you may damage the directory beyond repair and you
will need to initialize it to continue using the cartridge.

When you finish editing, you need to save the entry. The utility will offer you to replace the older entry or to create a copy of the
edited entry. The new entry will be located in the end of the list. The name of the entry will be the same if you didn't rename it while
editing.

The number of directory entries is limited to 254. If the utility can't find an empty directory entry, it will ask you whether the
directory should be optimized. If you select "Yes", then there's a big chance that unused directory entries will be found and deleted
and you will have the possibility to add new ones.


Notes
-----

The audio socket of the Carnivore cartridge may not be suitable for connecting the headphones. It's recommended to connect it to the
speakers or to the amplifier. This socket will only output SCC music and sounds. For the full experience please use the MSX's
startdard sound output - it will have the amplified SCC sound and music as well as the PSG sound and music.


IMPORTANT!
----------

The RBSC provides all the files and information for free, without any liability (see the disclaimer.txt file). The provided information,
software or hardware must not be used for commercial purposes unless permitted by the RBSC. Producing a small amount of bare boards for
personal projects and selling the rest of the batch is allowed without the permission of RBSC.

When the sources of the tools are used to create alternative projects, please always mention the original source and the copyright!


Contact information
-------------------

The members of RBSC group Wierzbowsky, Ptero and DJS3000 can be contacted via the MSX.ORG or ZX-PK.RU forums. Just send a personal
message and state your business.

The RBSC repository can be found here:

https://github.com/rbsc


-= ! MSX FOREVER ! =-
