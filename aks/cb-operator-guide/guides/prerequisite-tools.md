# Prerequisites

In this section, you will perform the necessary steps to install and configure the prerequisite tools required to interact with kubernetes cluster deployed on Azure. Follow the steps below and reach out for help if you get stuck. You can skip any step if you already have the corresponding tool(s) installed on your computer.

> **Note:** It is important to have the right minimum versions of the tools. This guide focuses on installing the right versions, so you get the functionality needed to complete all steps successfully.

For Mac OS, it is recommended you install Homebrew package manager; it will make things much easier. If you don't have homebrew available on your system, [install homebrew](https://docs.brew.sh/Installation.html) before continuing.

There are separate sections for Mac and Windows setup steps where needed. If there are no such separate sections, the steps are similar or identical for both operating systems, however terminal commands shown are based on Mac OS and some may need to be modified before being run on Windows, e.g. change / to \\, remove trailing & character to run commands in the background.

This guide does not cover installation steps on Linux due to a variety of popular Linux distributions. Please ask for help if you are using Linux and get stuck.

## Install kubectl

Kubectl is a command line interface for running commands against Kubernetes clusters. We will use kubectl to deploy and manage applications on Kubernetes. There are multiple options to download and install kubectl for your operating system, you can find them on the following page: [Install and setup kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/). Below are the recommended methods for Mac and Windows.

### Mac - Homebrew

Please follow the below steps to install `kubectl` uisng [Homebrew](https://brew.sh/) package manager.

1. Run the installation command:

	```bash
	brew install kubernetes-cli
	```

2. Test to ensure the version you installed is up-to-date:

	```bash
	kubectl version
	```

	If `kubectl` is installed successfully, then you should see the below output.

	```bash
	Client Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.2",   
	GitCommit:"f6278300bebbb750328ac16ee6dd3aa7d3549568", GitTreeState:"clean",
	BuildDate:"2019-08-05T16:54:35Z", GoVersion:"go1.12.7", Compiler:"gc", Platform:"darwin/
	amd64"}
	```

### Windows - Download kubectl.exe

1. Download the kubectl.exe binary from here: [kubectl 1.13.0 binary for Windows](https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/windows/amd64/kubectl.exe). Put the kubectl.exe file in any directory of your choice on your computer, e.g. ```C:\kubectl```.

2. Modify/edit your PATH environment variable to include the path where you put kubectl.exe, e.g., C:\kubectl. Use the Environment Variables dialog box (Control Panel → System → Advanced system settings → Environment Variables) to change the PATH variable permanently or use the terminal as shown below to change the PATH variable for the duration of the session:

	```bash
	> set PATH=%PATH%;C:\kubectl
	```
	
## Install Azure CLI

The Azure CLI is a command-line tool providing a great experience for managing Azure resources. Please refer [Install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) for more details on installing Azure CLI on various environments.

### Mac - Homebrew

Please follow the below steps to install `Azure CLI` uisng [Homebrew](https://brew.sh/) package manager.

You can install the CLI by updating your brew repository information, and then running the `install` command:

```bash
brew update && brew install azure-cli
```

> **Note:** The Azure CLI has a dependency on the python3 package in Homebrew, and will install it on your system, even if Python 2 is available. The Azure CLI is guaranteed to be compatible with the latest version of python3 published on Homebrew.

You can then run the Azure CLI with the az command. To sign in, use [az login](https://docs.microsoft.com/en-us/cli/azure/reference-index#az-login) command.

1. Run the login command.

	```bash
	az login
	```

	If the CLI can open your default browser, it will do so and load a sign-in page.

	Otherwise, you need to open a browser page and follow the instructions on the command line to enter an authorization code after navigating to [https://aka.ms/devicelogin](https://aka.ms/devicelogin) in your browser.

2. Sign in with your account credentials in the browser.

To learn more about different authentication methods, see [Sign in with Azure CLI](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli?view=azure-cli-latest).

### Windows - MSI Installer

The MSI distributable is used for installing or updating the Azure CLI on Windows. You don't need to uninstall any current versions before using the MSI installer.

You can download the MSI Installer [here](https://aka.ms/installazurecliwindows).

You can now run the Azure CLI with the `az` command from either Windows Command Prompt or PowerShell. PowerShell offers some tab completion features not available from Windows Command Prompt. 

1. Run the login command.

	```bash
	az login
	```

2. Sign in with your account credentials in the browser.
