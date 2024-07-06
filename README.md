# livelabsbrew

<last updates 2024-07-07>

```livelabs-brew.sh``` is the first init script.

## What does it do?
It creates the following setup:
- 23ai free in a container
  - including Oracle sample data
- ORDS + APEX in a container (fully configured with the DB)
- Jupyter Lab including LSPs for several languages.
  - Allows running Flask apps (on port 5000)
  - sqlcl installed


## What is possible?
After running the script you can do the following:
- Connect to DB Actions / APEX via <ip:8181>
- Connect to Jupyter Lab via <ip:8888>
  - Start Flask apps from Jupyter Lab on port 5000 <ip:5000>
  - Connect to the database using `sqlcl` (Example: `sql hr/<password>@23aifree/freepdb1)

## DB Users
All users are ORDS-enabled

Oracle Sample Data:
- HR
- CO
- SH
  
Admin user with DBA role

# Installation
Connect to an OCI compute instance as `opc`.

Run:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/klazarz/livelabsbrew/main/livelabs-brew.sh)"
```