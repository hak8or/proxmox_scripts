# All our important stuff
import click
import sys
import os
from proxmoxer import ProxmoxAPI

# Ensure we have the correct enviorment variables.
try:
    os.environ["PROX_HOST"]
except:
    print("Enviorment variable PROX_HOST not found. This can be fixed with:\n\texport PROX_HOST=127.0.0.1")
    sys.exit(0)
try:
    os.environ["PROX_USER"]
except:
    print("Enviorment variable PROX_USER not found. This can be fixed with:\n\texport PROX_USER=someusername")
    sys.exit(0)
try:
    os.environ["PROX_PASS"]
except:
    print("Enviorment variable PROX_HOST not found. This can be fixed with:\n\texport PROX_HOST=somepassword")
    sys.exit(0)

# Ensure we can connect to the host using enviorment variabels.
proxmox = ProxmoxAPI
try:
    proxmox = ProxmoxAPI(os.environ["PROX_HOST"], user=os.environ["PROX_USER"], password=os.environ["PROX_PASS"], verify_ssl=False)
except ProxmoxAPI.backends.https.AuthenticationError as err:
    print("Failed to login to server:",  err)
except:
    print("Failed to login to server:", sys.exc_info()[0])
    sys.exit(0)
