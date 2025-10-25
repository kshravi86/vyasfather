# A Deep Dive into GitHub Actions Secrets for iOS Deployment

This document provides a comprehensive guide to the secrets used in the GitHub Actions workflows for building, signing, and deploying the Vedic Light iOS application.

## The Role of Secrets in CI/CD

Secrets are encrypted environment variables that allow you to store sensitive information, like passwords, API keys, and certificates, directly in your GitHub repository's settings. Using secrets is a critical security practice because it prevents sensitive data from being hard-coded into your workflow files, which are visible to anyone with access to your repository.

### How Secrets Flow in the Workflow

When a GitHub Actions workflow runs, it injects the secrets you've configured into the runner's environment. The scripts and tools executed by the workflow can then access these secrets to perform sensitive operations like code signing and uploading to the App Store.

```mermaid
graph TD
    subgraph "GitHub Secure Storage"
        A[GitHub Repository Secrets]
        A -- "Encrypted Values" --> B((Workflow Job))
    end

    subgraph "GitHub Actions Runner (macOS)"
        B -- "Injects secrets into environment" --> C{Workflow Steps}
        C --> D[Step: Install Certificates]
        C --> E[Step: Build & Sign App]
        C --> F[Step: Upload to App Store]
    end

    subgraph "Secrets in Action"
        direction LR
        S1[secrets.BUILD_CERTIFICATE_BASE64] --> D
        S2[secrets.P12_PASSWORD] --> D
        S3[secrets.PROVISIONING_PROFILE_BASE64] --> D
        S4[secrets.APP_STORE_CONNECT_API_KEY_ID] --> F
    end
```

---

## Catalogue of Secrets

The following secrets are used in the `ios-appstore-upload-v3.yml` workflow.

### 1. Code Signing Secrets

These secrets are essential for signing the application, which is a mandatory step for installing an app on a physical iOS device or submitting it to the App Store.

#### `BUILD_CERTIFICATE_BASE64`
*   **What it is:** A Base64 encoded Apple Distribution Certificate. This certificate is a `.p12` file, which contains your public and private keys for code signing.
*   **How to get it:**
    1.  Export your distribution certificate from the Keychain Access app on your Mac. You will be prompted to create a password for it.
    2.  Convert the resulting `.p12` file to a Base64 string. You can do this from your terminal:
        ```bash
        base64 -i YourCertificate.p12 -o YourCertificate.p12.txt
        ```
    3.  Copy the contents of `YourCertificate.p12.txt` and paste it into the GitHub secret.

#### `P12_PASSWORD`
*   **What it is:** The password you set when exporting the `.p12` certificate from Keychain Access.
*   **How to get it:** This is the password you created in the step above.

#### `PROVISIONING_PROFILE_BASE64`
*   **What it is:** A Base64 encoded Provisioning Profile (`.mobileprovision` file). This profile links your developer identity, the app ID, and the devices it can run on.
*   **How to get it:**
    1.  Download the provisioning profile from the Apple Developer Portal.
    2.  Convert the `.mobileprovision` file to a Base64 string:
        ```bash
        base64 -i YourProfile.mobileprovision -o YourProfile.mobileprovision.txt
        ```
    3.  Copy the contents of the output file and paste it into the GitHub secret.

#### `KEYCHAIN_PASSWORD`
*   **What it is:** A password used to create a new, temporary keychain on the GitHub Actions runner. This keychain is used to securely store the imported signing certificate during the build process.
*   **How to get it:** This can be any strong, randomly generated password. It doesn't need to be stored anywhere else.

### 2. Apple Developer Team Secret

#### `IOS_TEAM_ID`
*   **What it is:** Your unique 10-character Team ID from Apple.
*   **How to get it:** You can find this in the top-right corner of the Apple Developer Portal under your account name, or in App Store Connect under "Users and Access" -> "Keys".

### 3. App Store Connect API Secrets (Primary Upload Method)

This is the modern, recommended, and more secure way to authenticate with App Store Connect for automated uploads.

```mermaid
graph TD
    A[Log in to App Store Connect] --> B{Go to Users and Access};
    B --> C{Select the Keys tab};
    C --> D{Click 'Generate API Key' or select an existing one};
    D --> E{Enter a name for the key and select 'Admin' role};
    E --> F{Click 'Generate'};
    F --> G[Download the .p8 private key file];
    G --> H{Note the Issuer ID};
    G --> I{Note the Key ID};
    H & I & G --> J[Add all three as distinct GitHub Secrets];
end
```

#### `APP_STORE_CONNECT_API_KEY_ID`
*   **What it is:** The Key ID for the App Store Connect API key.

#### `APP_STORE_CONNECT_ISSUER_ID`
*   **What it is:** The Issuer ID associated with your App Store Connect account.

#### `APP_STORE_CONNECT_API_PRIVATE_KEY`
*   **What it is:** The content of the private key file (`.p8`) you downloaded from App Store Connect.
*   **How to get it:** Open the `.p8` file with a text editor, copy the entire content (including the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines), and paste it into the GitHub secret.

### 4. App Store Connect Apple ID Secrets (Fallback Method)

This is a legacy method for uploading and is used only if the API key secrets are not provided.

#### `APP_STORE_CONNECT_USERNAME`
*   **What it is:** The Apple ID email address of an account with at least an "App Manager" role in App Store Connect.

#### `APP_SPECIFIC_PASSWORD`
*   **What it is:** An app-specific password generated for the Apple ID.
*   **How to get it:**
    1.  Log in to `appleid.apple.com`.
    2.  Go to the "App-Specific Passwords" section.
    3.  Click "Generate an app-specific password" and follow the prompts.
