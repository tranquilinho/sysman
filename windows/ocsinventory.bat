:: OPTIONAL: Install OCS Inventory agent

@Echo off

todo.pl "%Z%\packages\ocsinventory\agent_1.02rc2\OcsAgentSetup.exe /install /server:ingalls.cnb.csic.es"
todo.pl "c:\program files\OCS Inventory Agent\OCSInventory.exe /server:ocsserver /debug"
