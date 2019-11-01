# login-menu
Dynamic login for SSH connections. Dynamically reads a flat file and generates the menu and login commands.

## Use
`menu.sh [-i path/inventory_file.txt] [-t "Menu Title"] [-u username] [-m ssh|rdp] [-w n] [--nosort]`

### Parameters
-i filename     The path and name of the inventory file. Defaults to ./inventory.txt.
                Multiple inventory files may be used for connecting to different environments, eg prod_inv.txt & test_inv.txt
-t title        Title displayed at the top of the menu.
-u username     The username for login. Defaults to "whoami". Can be overridden in the inventory file for individual connections.
-m ssh|rdp      The default login method. Can be overridden in the inventory file for individual connections.
-w width        Change the width of the menu to "width" characters.
--nosort        Don't sort the output. By default, the script sorts entries in the inventory file and places break lines when the
                group name changes.

### Example
Run as:
`./menu.sh -i inventory.txt -w 100 -t "My Server Menu"`

```
====================================================================================================
                                           My Server Menu
====================================================================================================
Development            1. devdb1                    Dev - (dev1, dev2)                                                     
====================================================================================================
Production             2. prod-db1                  Prod - RAC Node1 (prod1)                                               
                       3. prod-db2                  Prod - RAC Node2 (prod2)                                               
                       4. prod01                    Prod database host (database1, database2)                              
====================================================================================================
Test                   5. test-db01                 Test RAC Node1 (dbt01)                                                 
                       6. test-db02                 Test RAC Node2 (dbt02)                                                 
====================================================================================================
                       X.  Exit 
 
 
 
Enter an option: (1 - 6 or X to exit): 
```
#### Command History
When exiting a connection, the command history is preserved and displayed just about the selection line:
```
Command history: 1, 2, 5
Enter an option: (1 - 6 or X to exit): 
```
This was added mainly to keep track when changing passwords on multiple hosts.
