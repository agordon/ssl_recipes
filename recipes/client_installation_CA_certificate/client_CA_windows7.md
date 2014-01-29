# Adding Root-CA certificate to Windows 7 (IE/Chrom)

## Preparations

After creating the Root CA certificate (with `./create_certificate_authority.sh`),
give the generated certificate file (`ca_public_certificate.pem`) to the clients' devices
(by email attachment or providing a downloadable link).

## Installation

### Installation Step 1 - Open Certificate File

![](images/win7/01_open_file.png)

### Installation Step 2 - Install Certificate File

Click **Install Certificate**:

![](images/win7/02_certificate_view.png)

### Installation Step 3 - Follow Installation Wizard Program

Click **Next**:

![](images/win7/03_install_wizard.png)

Select **"Place all certificates in the following store"** and click **Browse**:

![](images/win7/04_wizard_store.png)

Select **Trusted Root Certificate Authorities**, and click **OK**:

![](images/win7/05_wizard_store_trusted.png)

The wizard should look like this. Click **Finish**:

![](images/win7/06_wizard_store_selected.png)


![](images/win7/07_wizard_final.png)



![](images/win7/08_import_done.png)



The certificate is now installed.



## Removal

TODO

## Security Considerations

* Installing (and trusting) any certificate enables all sorts of nasty tricks (e.g man-in-the-middle attacks). This should not be done lightly.
