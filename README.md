
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

1. To use SimPol, download the latest release from [here](https://gitlab.com/tum-fsd/simpol/-/releases).

1. Copy the `simpol` folder to a location of your choice.

1. In MATLAB, open this folder and type `install_simpol`.

1. Check section 6 of the [SimPol User Guide](SimPol%20User%20Guide.pdf) if your Polarion server uses an SSL certificate and you have trouble connecting to the server.

1. Restart MATLAB.

1. Call `SimPol`.

Refer to [SimPol User Guide](SimPol%20User%20Guide.pdf) for more details.

### Deinstallation:

- Call `uninstall_simpol` and follow the instructions.

### Requirements:

- MATLAB/Simulink, Simulink Requirements version 2019a and later

- Polarion version 20R1 and later
