# Adding Root-CA certificate to Windows XP (IE/Chrom)

## Preparations

After creating the Root CA certificate (with `./create_certificate_authority.sh`),
give the generated certificate file (`ca_public_certificate.pem`) to the clients' devices
(by email attachment or providing a downloadable link).

## Installation

### Installation Step 1 - Open Certificate File

Download the certificate file, and double-click to open it:

![](images/05_IE_download_certificate.png)

### Installation Step 2 - Install Certificate File

Click **Install Certificate**:

![](images/06_Windows_install_certificate.png)

### Installation Step 3 - Installation Wizard Program

Click **Next**:

![](images/07_windows_install_certificate.png)

Click **Next**:

![](images/08_windows_install.png)

Click **Next**:

![](images/09_windows_install.png)

Click **Yes**:

![](images/10_windows_install.png)




![](images/11_windows_install.png)

The certificate is now installed.



## Removal

TODO

## Security Considerations

* Installing (and trusting) any certificate enables all sorts of nasty tricks (e.g man-in-the-middle attacks). This should not be done lightly.
