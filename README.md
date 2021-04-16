
# Simulink® – Polarion® Connector SimPol

SimPol is a free, MATLAB®-based tool to create, maintain, and evaluate bi-directional traceability between Simulink® or Simulink® Test™ or MATLAB Code and work items in Polarion®. It is designed to support workflows of safety-critical development processes like DO-178C/DO-331 or ISO 26262.

SimPol seamlessly integrates with the [Simulink® Requirement Management Interface](https://www.mathworks.com/help/slrequirements/requirements-management-interface.html) (RMI) and supports almost all built-in functionality.
  

## License

Download and use of the tool is free. By downloading the tool, you accept the license Terms of SimPol and of included 3rd-party applications, source code, and binaries.

See [NOTICE.md](NOTICE.md) for licensing details.


## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.


## Download & Installation

### Installation and first startup:

1. Download the `simpol` folder of this project and copy it to your favorite location, e.g. `C:/Program Files/SimPo`.

1. Copy the Web Service Java Client from your Polarion Server`<Polarion Server Host>/polarion/sdk/lib/com.polarion.alm.ws.client/` into the folder `3rdparty\wsclient`

1. In MATLAB, open the root folder of SimPol and type `install_simpol`.

1. Check section 6 of the [SimPol User Guide](SimPol%20User%20Guide.docx) if your Polarion server uses an SSL certificate.

1. Restart MATLAB.

1. Call `SimPol`.

Alternatively, you can use `deploy_simpol` to create a p-code version of SimPol which can then be distributed locally for installation. You will still have to copy/paste the Web Service Java Client from your Polarion server.

Refer to [SimPol User Guide](SimPol%20User%20Guide.docx) for more details.

### Deinstallation:

- Call `uninstall_simpol` and follow the instructions.

### Requirements:

- MATLAB/Simulink, Simulink Requirements version 2019a and later

- Polarion version 20R1 and later
