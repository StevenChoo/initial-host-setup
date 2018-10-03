# initial-host-setup

A script that runs an initial setup script for Debian based installation. 

**Change the PUBLIC_KEY variable to any desired public key.**

Using curl to run:
```bash
curl -L https://raw.githubusercontent.com/StevenChoo/initial-host-setup/master/initial-setup.sh | bash
```

Using docker to test
```bash
docker run -it debian:latest bash -c "`cat initial-setup.sh`"
```

Tips:
* You can append ```bash``` to initial-setup to avoid stopping the container running a bash shell.
