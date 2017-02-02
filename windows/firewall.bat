:: OPTIONAL: Setup firewall 0.60
@Echo off

echo Setting up firewall (SSH & rdesktop) ...
netsh firewall add portopening TCP 22 SSH enable subnet
netsh firewall add portopening TCP 3389 Rdesktop enable subnet 
