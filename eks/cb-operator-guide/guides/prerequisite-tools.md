## Step 5: Configure AWS CLI

We will configure AWS CLI credentials and options by running aws configure command. Use the following values for AWS Access Key ID, AWS Secret Access Key, Default region name, and Default output format:

| NAME              | VALUE |
| --------------------- | ----------- |
|AWS Access Key ID	|A*****************|
|AWS Secret Access Key|	L******************************/8*******|
|Default region name	|us-east-2|
|Default output format	|json|

Run the aws configure command and enter each of the values provided above, as shown below:
```
$ aws configure

AWS Access Key ID [none]: A*****************
AWS Secret Access Key [none]: L******************************/8*******
Default region name [none]: us-east-2
Default output format [none]: json
```


## Step 6: Install git CLI

git CLI is a tool to work with GitHub repositories.

### Mac - git via Homebrew
git CLI is usually pre-installed on Mac. You can also install it by using Homebrew package manager:
```
$ brew install git
```
### Windows - git via Installer
git CLI for Windows can be downloaded from the following location: [Git for Windows](https://gitforwindows.org/).  Here is the direct link for the current 64-bit installer: [Git Windows 64-bit installer](https://github.com/git-for-windows/git/releases/download/v2.20.1.windows.1/Git-2.20.1-64-bit.exe).
